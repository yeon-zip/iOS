본 서비스는 도서 검색부터 ISBN 추출, 주변 도서관 조회, 대출 상태 확인까지의 과정을 하나의 흐름으로 연결한다. 사용자는 현재 위치나 직접 선택한 주소를 기준으로 가까운 도서관의 소장 여부와 대출 가능 상태를 거리순으로 확인할 수 있다. 한 권의 도서를 중심으로 인근 도서관별 현황을 비교하도록 구성했으며, ISBN을 식별 기준으로 삼아 같은 도서가 여러 검색 결과로 나뉘는 문제를 줄인다. 다른 이용자가 이미 대출한 도서에는 알림 신청 기능을 제공해, 이후 대출 가능 여부를 알림 페이지에서 쉽게 확인할 수 있게 한다. 향후 연구에서는 시스템 안정성과 사용자 경험을 높이기 위해 다음 과제를 중심으로 연구를 이어가고자 한다.

<!-- HUMANIZE-SUMMARY v2.0.0
mode: fast
run_id: 2026-05-11-001
original_length: 379
rewritten_length: 353
length_delta_rate: 6.9%
metrics_risk_band: absent
metrics_note: prepare_monolith_input.py completed with degraded=true; no baseline risk score available.
category_counts_before: A-2=3, A-10=3, D-1=1, H-1=1, F-4=2
category_counts_after: A-10=2, F-4=1
self_check: 6/6
quality_grade: A
highlights:
- Replaced mechanical connectors such as "이를 통해" and "또한" with sentence-level flow.
- Reduced repeated "확인할 수 있다/비교할 수 있다" structure where meaning allowed.
- Kept ISBN, location/address, nearby library, availability, and notification-page claims intact.
- Preserved formal report register without adding new claims or examples.
residual_findings: Minor formal report nominalization remains because the source genre requires an academic tone.
-->
