//
//  LocationPickerViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit
import WebKit

struct PostcodeSelection: Equatable {
    let roadAddress: String
    let jibunAddress: String
    let buildingName: String
    let legalDongName: String
    let zoneCode: String

    var detailText: String {
        let values = [buildingName, legalDongName, jibunAddress]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return values.isEmpty ? "선택한 주소" : values.joined(separator: " · ")
    }
}

@MainActor
final class LocationPickerViewModel {
    struct State: Equatable {
        var currentAddress: String
        var helperText = "카카오 주소 검색에서 정확한 주소를 선택해 주세요."
        var isResolvingCurrentLocation = false
        var isResolvingSelectedAddress = false
        var selectedAddress: AddressSuggestion?
    }

    var onStateChange: ((State) -> Void)?
    var onAddressSelected: ((AddressSuggestion) -> Void)?

    private let locationAddressService: any LocationAddressService
    private(set) var state: State
    private var selectionTask: Task<Void, Never>?
    private var selectionGeneration = 0

    init(
        currentLocation: AddressSuggestion,
        locationAddressService: any LocationAddressService
    ) {
        self.locationAddressService = locationAddressService
        self.state = State(currentAddress: currentLocation.roadAddress)
    }

    func load() {
        onStateChange?(state)
    }

    func didTapUseCurrentLocation() {
        cancelPendingSelection()
        state.isResolvingCurrentLocation = true
        state.isResolvingSelectedAddress = false
        state.selectedAddress = nil
        state.helperText = "현재 위치를 확인하는 중이에요."
        onStateChange?(state)

        let generation = selectionGeneration
        selectionTask = Task { [weak self] in
            guard let self else { return }

            do {
                let suggestion = try await locationAddressService.requestCurrentAddress()
                guard Task.isCancelled == false, generation == selectionGeneration else { return }
                state.selectedAddress = suggestion
                state.helperText = "현재 위치 주소를 불러왔어요. 이 주소로 설정할 수 있어요."
            } catch {
                guard Task.isCancelled == false, generation == selectionGeneration else { return }
                state.helperText = error.localizedDescription
            }

            guard generation == selectionGeneration else { return }
            state.isResolvingCurrentLocation = false
            onStateChange?(state)
        }
    }

    func didSelectPostcode(_ selection: PostcodeSelection) {
        cancelPendingSelection()
        state.isResolvingCurrentLocation = false
        state.isResolvingSelectedAddress = true
        state.selectedAddress = nil
        state.helperText = "선택한 주소를 확인하는 중이에요."
        onStateChange?(state)

        let generation = selectionGeneration
        selectionTask = Task { [weak self] in
            guard let self else { return }

            do {
                let suggestion = try await locationAddressService.resolveAddress(
                    roadAddress: selection.roadAddress,
                    detailText: selection.detailText
                )
                guard Task.isCancelled == false, generation == selectionGeneration else { return }
                state.selectedAddress = suggestion
                state.helperText = "선택한 주소를 적용할 준비가 됐어요."
            } catch {
                guard Task.isCancelled == false, generation == selectionGeneration else { return }
                state.selectedAddress = nil
                state.helperText = "선택한 주소의 위치를 확인하지 못했어요. 다시 선택해 주세요."
            }

            guard generation == selectionGeneration else { return }
            state.isResolvingSelectedAddress = false
            onStateChange?(state)
        }
    }

    func didTapConfirm() {
        guard let selectedAddress = state.selectedAddress,
              selectedAddress.latitude != nil,
              selectedAddress.longitude != nil else {
            state.helperText = "지도 기준점을 확인할 수 있는 주소만 설정할 수 있어요."
            onStateChange?(state)
            return
        }

        onAddressSelected?(selectedAddress)
    }

    private func cancelPendingSelection() {
        selectionGeneration += 1
        selectionTask?.cancel()
    }
}

final class LocationPickerViewController: UIViewController {
    private let viewModel: LocationPickerViewModel
    private let onSelection: (AddressSuggestion) -> Void
    private let contentView = LocationPickerView()

    init(viewModel: LocationPickerViewModel, onSelection: @escaping (AddressSuggestion) -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        viewModel.load()
    }

    private func bind() {
        contentView.closeButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        contentView.currentLocationButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapUseCurrentLocation()
        }, for: .touchUpInside)
        contentView.confirmButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapConfirm()
        }, for: .touchUpInside)
        contentView.postcodeSearchView.onSelection = { [weak self] selection in
            self?.viewModel.didSelectPostcode(selection)
        }

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onAddressSelected = { [weak self] address in
            guard let self else { return }
            onSelection(address)
            dismiss(animated: true)
        }
    }

    private func render(_ state: LocationPickerViewModel.State) {
        contentView.currentAddressValueLabel.text = state.currentAddress
        contentView.helperLabel.text = state.helperText
        contentView.updateSelectedAddress(state.selectedAddress)
        contentView.updateCurrentLocationButton(isLoading: state.isResolvingCurrentLocation)
        contentView.updateConfirmButton(
            isEnabled: state.selectedAddress?.latitude != nil &&
                state.selectedAddress?.longitude != nil &&
                state.isResolvingSelectedAddress == false &&
                state.isResolvingCurrentLocation == false,
            isLoading: state.isResolvingSelectedAddress
        )
    }
}

private final class LocationPickerView: UIView {
    let closeButton = IconActionButton(symbolName: "xmark", accessibilityLabel: "닫기")
    let currentAddressValueLabel = UILabel()
    let currentLocationButton = UIButton(type: .system)
    let helperLabel = UILabel()
    let confirmButton = UIButton(type: .system)
    let postcodeSearchView = KakaoPostcodeSearchView()

    private let selectedAddressValueLabel = UILabel()
    private let selectedAddressDetailLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = AppSpacing.l

        let subtitleLabel = UILabel()
        subtitleLabel.text = "현재 위치를 불러오거나 카카오 주소 검색에서 정확한 주소를 선택해 주세요."
        subtitleLabel.font = AppTypography.body
        subtitleLabel.textColor = AppColor.textSecondary
        subtitleLabel.numberOfLines = 0

        let currentAddressCard = CardContainerView()
        let currentAddressTitleLabel = UILabel()
        currentAddressTitleLabel.text = "현재 설정 주소"
        currentAddressTitleLabel.font = AppTypography.tiny
        currentAddressTitleLabel.textColor = AppColor.textTertiary

        currentAddressValueLabel.font = AppTypography.subheadline
        currentAddressValueLabel.textColor = AppColor.textPrimary
        currentAddressValueLabel.numberOfLines = 2

        let selectedAddressCard = CardContainerView()
        let selectedAddressTitleLabel = UILabel()
        selectedAddressTitleLabel.text = "선택된 주소"
        selectedAddressTitleLabel.font = AppTypography.tiny
        selectedAddressTitleLabel.textColor = AppColor.textTertiary

        selectedAddressValueLabel.font = AppTypography.subheadline
        selectedAddressValueLabel.textColor = AppColor.textTertiary
        selectedAddressValueLabel.numberOfLines = 2

        selectedAddressDetailLabel.font = AppTypography.caption
        selectedAddressDetailLabel.textColor = AppColor.textSecondary
        selectedAddressDetailLabel.numberOfLines = 2

        let postcodeCard = CardContainerView()

        helperLabel.font = AppTypography.caption
        helperLabel.textColor = AppColor.textSecondary
        helperLabel.numberOfLines = 0

        var currentLocationConfiguration = UIButton.Configuration.plain()
        currentLocationConfiguration.image = UIImage(systemName: "location.viewfinder")
        currentLocationConfiguration.imagePadding = AppSpacing.s
        currentLocationConfiguration.baseForegroundColor = AppColor.accent
        currentLocationConfiguration.background.backgroundColor = AppColor.accentSurface
        currentLocationConfiguration.background.cornerRadius = 16
        currentLocationConfiguration.contentInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 14)
        currentLocationConfiguration.title = "현재 위치로 찾기"
        currentLocationButton.configuration = currentLocationConfiguration

        var confirmConfiguration = UIButton.Configuration.filled()
        confirmConfiguration.baseBackgroundColor = AppColor.textPrimary
        confirmConfiguration.baseForegroundColor = .white
        confirmConfiguration.cornerStyle = .large
        confirmConfiguration.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        confirmConfiguration.title = "이 주소로 설정"
        confirmButton.configuration = confirmConfiguration

        addSubviews(closeButton, scrollView)
        [closeButton, scrollView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        currentAddressCard.addSubviews(currentAddressTitleLabel, currentAddressValueLabel)
        [currentAddressTitleLabel, currentAddressValueLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        selectedAddressCard.addSubviews(selectedAddressTitleLabel, selectedAddressValueLabel, selectedAddressDetailLabel)
        [selectedAddressTitleLabel, selectedAddressValueLabel, selectedAddressDetailLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        postcodeCard.addSubview(postcodeSearchView)
        postcodeSearchView.translatesAutoresizingMaskIntoConstraints = false

        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(currentAddressCard)
        contentStack.addArrangedSubview(currentLocationButton)
        contentStack.addArrangedSubview(selectedAddressCard)
        contentStack.addArrangedSubview(postcodeCard)
        contentStack.addArrangedSubview(helperLabel)
        contentStack.addArrangedSubview(confirmButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.l),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: AppSpacing.s),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: AppSpacing.s),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: AppSpacing.xxl),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -AppSpacing.xxl),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppSpacing.xxl),

            currentAddressTitleLabel.topAnchor.constraint(equalTo: currentAddressCard.topAnchor, constant: AppSpacing.l),
            currentAddressTitleLabel.leadingAnchor.constraint(equalTo: currentAddressCard.leadingAnchor, constant: AppSpacing.l),
            currentAddressTitleLabel.trailingAnchor.constraint(equalTo: currentAddressCard.trailingAnchor, constant: -AppSpacing.l),

            currentAddressValueLabel.topAnchor.constraint(equalTo: currentAddressTitleLabel.bottomAnchor, constant: AppSpacing.xs),
            currentAddressValueLabel.leadingAnchor.constraint(equalTo: currentAddressTitleLabel.leadingAnchor),
            currentAddressValueLabel.trailingAnchor.constraint(equalTo: currentAddressTitleLabel.trailingAnchor),
            currentAddressValueLabel.bottomAnchor.constraint(equalTo: currentAddressCard.bottomAnchor, constant: -AppSpacing.l),

            selectedAddressTitleLabel.topAnchor.constraint(equalTo: selectedAddressCard.topAnchor, constant: AppSpacing.l),
            selectedAddressTitleLabel.leadingAnchor.constraint(equalTo: selectedAddressCard.leadingAnchor, constant: AppSpacing.l),
            selectedAddressTitleLabel.trailingAnchor.constraint(equalTo: selectedAddressCard.trailingAnchor, constant: -AppSpacing.l),

            selectedAddressValueLabel.topAnchor.constraint(equalTo: selectedAddressTitleLabel.bottomAnchor, constant: AppSpacing.xs),
            selectedAddressValueLabel.leadingAnchor.constraint(equalTo: selectedAddressTitleLabel.leadingAnchor),
            selectedAddressValueLabel.trailingAnchor.constraint(equalTo: selectedAddressTitleLabel.trailingAnchor),

            selectedAddressDetailLabel.topAnchor.constraint(equalTo: selectedAddressValueLabel.bottomAnchor, constant: AppSpacing.xs),
            selectedAddressDetailLabel.leadingAnchor.constraint(equalTo: selectedAddressValueLabel.leadingAnchor),
            selectedAddressDetailLabel.trailingAnchor.constraint(equalTo: selectedAddressValueLabel.trailingAnchor),
            selectedAddressDetailLabel.bottomAnchor.constraint(equalTo: selectedAddressCard.bottomAnchor, constant: -AppSpacing.l),

            postcodeSearchView.topAnchor.constraint(equalTo: postcodeCard.topAnchor, constant: AppSpacing.s),
            postcodeSearchView.leadingAnchor.constraint(equalTo: postcodeCard.leadingAnchor, constant: AppSpacing.s),
            postcodeSearchView.trailingAnchor.constraint(equalTo: postcodeCard.trailingAnchor, constant: -AppSpacing.s),
            postcodeSearchView.bottomAnchor.constraint(equalTo: postcodeCard.bottomAnchor, constant: -AppSpacing.s),
            postcodeSearchView.heightAnchor.constraint(equalToConstant: 360)
        ])

        accessibilityIdentifier = "locationPickerScreen"
        postcodeSearchView.accessibilityIdentifier = "locationPicker.postcodeWebView"
        updateSelectedAddress(nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelectedAddress(_ suggestion: AddressSuggestion?) {
        guard let suggestion else {
            selectedAddressValueLabel.text = "아직 주소를 선택하지 않았어요."
            selectedAddressValueLabel.textColor = AppColor.textTertiary
            selectedAddressDetailLabel.text = "카카오 주소 검색 결과나 현재 위치를 선택하면 여기에서 확인할 수 있어요."
            return
        }

        selectedAddressValueLabel.text = suggestion.roadAddress
        selectedAddressValueLabel.textColor = AppColor.textPrimary
        selectedAddressDetailLabel.text = suggestion.detailText
    }

    func updateCurrentLocationButton(isLoading: Bool) {
        var configuration = currentLocationButton.configuration
        configuration?.title = isLoading ? "현재 위치 확인 중..." : "현재 위치로 찾기"
        currentLocationButton.configuration = configuration
        currentLocationButton.isEnabled = isLoading == false
    }

    func updateConfirmButton(isEnabled: Bool, isLoading: Bool) {
        var configuration = confirmButton.configuration
        configuration?.title = isLoading ? "주소 확인 중..." : "이 주소로 설정"
        confirmButton.configuration = configuration
        confirmButton.isEnabled = isEnabled
    }
}

private final class KakaoPostcodeSearchView: UIView, WKScriptMessageHandler, WKNavigationDelegate {
    var onSelection: ((PostcodeSelection) -> Void)?

    private enum MessageName {
        static let postcode = "postcode"
    }

    private let statusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let webView: WKWebView

    override init(frame: CGRect) {
        let userContentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: frame)

        userContentController.add(WeakScriptMessageHandler(delegate: self), name: MessageName.postcode)
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = AppColor.surface
        webView.isOpaque = false
        webView.layer.cornerRadius = AppRadius.medium
        webView.layer.cornerCurve = .continuous
        webView.clipsToBounds = true

        statusLabel.font = AppTypography.caption
        statusLabel.textColor = AppColor.textSecondary
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "카카오 주소 검색을 불러오는 중이에요."

        backgroundColor = AppColor.surface
        layer.cornerRadius = AppRadius.medium
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        addSubviews(webView, statusLabel, loadingIndicator)
        [webView, statusLabel, loadingIndicator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: AppSpacing.l),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -AppSpacing.l),

            loadingIndicator.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -AppSpacing.m),
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        loadingIndicator.startAnimating()
        loadPostcodePage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: MessageName.postcode)
    }

    private func loadPostcodePage() {
        webView.loadHTMLString(Self.html, baseURL: URL(string: "https://postcode.map.kakao.com"))
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == MessageName.postcode else { return }
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }

        switch type {
        case "ready":
            loadingIndicator.stopAnimating()
            statusLabel.isHidden = true
        case "selected":
            let selection = PostcodeSelection(
                roadAddress: body["roadAddress"] as? String ?? "",
                jibunAddress: body["jibunAddress"] as? String ?? "",
                buildingName: body["buildingName"] as? String ?? "",
                legalDongName: body["legalDongName"] as? String ?? "",
                zoneCode: body["zoneCode"] as? String ?? ""
            )
            guard selection.roadAddress.isEmpty == false else { return }
            onSelection?(selection)
        case "error":
            loadingIndicator.stopAnimating()
            statusLabel.isHidden = false
            statusLabel.text = "주소 검색을 불러오지 못했어요. 네트워크를 확인해 주세요."
        default:
            break
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        showLoadError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        showLoadError()
    }

    private func showLoadError() {
        loadingIndicator.stopAnimating()
        statusLabel.isHidden = false
        statusLabel.text = "주소 검색을 불러오지 못했어요. 네트워크를 확인해 주세요."
    }

    private static let html = """
    <!doctype html>
    <html lang="ko">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          background: #FFFFFF;
          font-family: -apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo", "Helvetica Neue", sans-serif;
        }
        #wrap {
          width: 100%;
          height: 100%;
        }
      </style>
      <script src="https://t1.kakaocdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
    </head>
    <body>
      <div id="wrap"></div>
      <script>
        (function() {
          var handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.postcode;

          function send(payload) {
            if (handler) {
              handler.postMessage(payload);
            }
          }

          function postcodeConstructor() {
            if (window.daum && window.daum.Postcode) {
              return window.daum.Postcode;
            }
            if (window.kakao && window.kakao.Postcode) {
              return window.kakao.Postcode;
            }
            return null;
          }

          function mount() {
            var Postcode = postcodeConstructor();
            if (!Postcode) {
              send({ type: "error" });
              return;
            }

            new Postcode({
              width: "100%",
              height: "100%",
              oncomplete: function(data) {
                send({
                  type: "selected",
                  roadAddress: data.roadAddress || "",
                  jibunAddress: data.jibunAddress || "",
                  buildingName: data.buildingName || "",
                  legalDongName: data.bname || "",
                  zoneCode: data.zonecode || ""
                });
              }
            }).embed(document.getElementById("wrap"));

            send({ type: "ready" });
          }

          if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", mount);
          } else {
            mount();
          }
        })();
      </script>
    </body>
    </html>
    """
}

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
