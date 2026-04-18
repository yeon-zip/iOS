# 인증 API 명세

확인일: 2026-04-26
Docs URL: `https://polaris.nimonic.dev`
Request Base URL: `https://api.k-polaris.life`

## 토큰 정책

- 액세스 토큰은 메모리에 저장하고 `Authorization` 헤더에 담아 전송한다.
- 리프레시 토큰은 Keychain에 저장하고 `/api/v1/auth/refresh` 요청 또는 로그아웃 요청에만 사용한다.
- 액세스 토큰 유효 기간은 10분, 즉 `600`초다.
- 리프레시 토큰 유효 기간은 1년, 즉 `31536000`초다.
- 토큰 재발급 시 기존 리프레시 토큰은 무효화되고 새 액세스 토큰과 새 리프레시 토큰이 발급된다.
- 로그아웃 시 서버의 리프레시 토큰을 무효화하고, 클라이언트에 저장된 액세스 토큰과 리프레시 토큰은 같이 삭제해야 한다.

## 엔드포인트 요약

| 기능 | Method | Path | 인증 |
| --- | --- | --- | --- |
| Kakao 로그인 | `GET` | `/api/v1/auth/kakao/login` | 불필요 |
| 인증 토큰 발급 | `POST` | `/api/v1/auth/exchange` | 불필요 |
| 인증 토큰 재발급 | `POST` | `/api/v1/auth/refresh` | 리프레시 토큰 필요 |
| 로그아웃 또는 토큰 무효화 | `DELETE` | `/api/v1/auth/logout` | 액세스 토큰 및 리프레시 토큰 필요 |

## Kakao 로그인

Source: https://polaris.nimonic.dev/api-reference/%EC%9D%B8%EC%A6%9D/kakao-%EB%A1%9C%EA%B7%B8%EC%9D%B8

Kakao 로그인 페이지로 이동한다.

```http
GET /api/v1/auth/kakao/login
```

### Query Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `channel` | `string` | no | 모바일 앱 환경에서는 `app`, 웹 환경에서는 `web` 사용. 기본 값은 `web` |
| `target` | `string` | app 환경에서 필요 | 모바일 앱 환경일 때 앱으로 되돌아가기 위한 앱 Scheme |
| `codeChallenge` | `string` | PKCE 사용 시 필요 | 애플리케이션에서 생성한 `code_verifier`를 변환한 값 |
| `codeChallengeMethod` | `string` | PKCE 사용 시 필요 | `code_verifier` 변환 함수. `S256` 사용 |

### iOS Request Example

```http
GET /api/v1/auth/kakao/login?channel=app&target=<app-scheme>&codeChallenge=<code-challenge>&codeChallengeMethod=S256
```

### Response

```http
200 OK
```

## 인증 토큰 발급

Source: https://polaris.nimonic.dev/api-reference/%EC%9D%B8%EC%A6%9D/%EC%9D%B8%EC%A6%9D-%ED%86%A0%ED%81%B0-%EB%B0%9C%EA%B8%89

Kakao 로그인 후 발급된 코드로 로그인할 수 있는 액세스 토큰 및 리프레시 토큰을 발급한다.

```http
POST /api/v1/auth/exchange
Content-Type: application/json;charset=UTF-8
```

### Body

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `code` | `string` | yes | Kakao 로그인 후 발급된 코드. 최소 길이 `1` |
| `targetId` | `string` | yes | 로그인 요청을 식별하는 대상 ID. 최소 길이 `1` |
| `codeVerifier` | `string` | no | PKCE에서 앱이 생성한 원본 `code_verifier` |

### Request Example

```json
{
  "code": "<string>",
  "targetId": "<string>",
  "codeVerifier": "<string>"
}
```

### Response

```json
{
  "accessToken": "<string>",
  "refreshToken": "<string>",
  "expiresIn": 600,
  "userId": 123
}
```

### Response Fields

| Field | Type | Description |
| --- | --- | --- |
| `accessToken` | `string` | API 요청에 사용할 액세스 토큰 |
| `refreshToken` | `string` | 토큰 재발급 및 로그아웃에 사용할 리프레시 토큰 |
| `expiresIn` | `integer<int64>` | 액세스 토큰 만료까지 남은 시간. 초 단위 |
| `userId` | `integer<int64>` | 로그인 사용자 ID |

## 인증 토큰 재발급

Source: https://polaris.nimonic.dev/api-reference/%EC%9D%B8%EC%A6%9D/%EC%9D%B8%EC%A6%9D-%ED%86%A0%ED%81%B0-%EC%9E%AC%EB%B0%9C%EA%B8%89

리프레시 토큰을 사용해 액세스 토큰을 재발급하고 기존 리프레시 토큰을 무효화한다.

```http
POST /api/v1/auth/refresh
Authorization: <authorization>
```

### Headers

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `Authorization` | `string` | yes | 명세상 required. cURL 예시는 `Authorization: <authorization>` 형태이며 Bearer 스킴은 명시되어 있지 않음 |

### Response

```json
{
  "accessToken": "<string>",
  "refreshToken": "<string>",
  "expiresIn": 600,
  "userId": 123
}
```

### Response Fields

| Field | Type | Description |
| --- | --- | --- |
| `accessToken` | `string` | 새 액세스 토큰 |
| `refreshToken` | `string` | 새 리프레시 토큰 |
| `expiresIn` | `integer<int64>` | 액세스 토큰 만료까지 남은 시간. 초 단위 |
| `userId` | `integer<int64>` | 로그인 사용자 ID |

## 로그아웃 또는 토큰 무효화

Source: https://polaris.nimonic.dev/api-reference/%EC%9D%B8%EC%A6%9D/%EB%A1%9C%EA%B7%B8%EC%95%84%EC%9B%83-%EB%98%90%EB%8A%94-%ED%86%A0%ED%81%B0-%EB%AC%B4%ED%9A%A8%ED%99%94

로그아웃을 위해 리프레시 토큰을 무효화한다. 액세스 토큰이 저장돼 있다면 잠시 동안 로그인 상태일 수 있으므로 클라이언트에서도 삭제해야 한다.

```http
DELETE /api/v1/auth/logout
Authorization: Bearer <token>
Refresh-Token: <refresh-token>
```

### Authorizations

```http
Authorization: Bearer <token>
```

### Headers

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `Authorization` | `string` | yes | Bearer authentication header. `<token>`은 액세스 토큰 |
| `Refresh-Token` | `string` | no | 명세상 required 표시는 없지만, 리프레시 토큰 무효화를 위해 전달 필요 |

### Response

```http
200 OK
```

## 구현 메모

- `expiresIn`은 문서 문구보다 서버 응답 값을 기준으로 처리한다.
- 현재 확인된 액세스 토큰 기본 만료값은 `600`초다.
- iOS에서는 액세스 토큰은 메모리 보관, 리프레시 토큰은 Keychain 보관을 기본 정책으로 둔다.
- 재발급 성공 시 저장된 리프레시 토큰을 새 값으로 반드시 교체한다.
- 재발급 실패 시 로컬 토큰을 제거하고 로그인 플로우로 돌려보내는 처리가 필요하다.
- 로그아웃 성공 여부와 관계없이 사용자가 로그아웃을 선택한 경우 로컬 토큰은 삭제하는 편이 안전하다.
- 재발급 API의 `Authorization` 헤더 스킴은 문서에 Bearer로 명시되어 있지 않다. 실제 연동 시 백엔드와 `Authorization: <refreshToken>`인지 `Authorization: Bearer <refreshToken>`인지 확인 필요하다.
- 문서 cURL에는 `https://k-polaris.life`가 표시되어 있지만 2026-04-26 확인 기준 해당 호스트의 인증 API는 404를 반환한다. 실제 동작 호스트는 `https://api.k-polaris.life`다.
- `GET /api/v1/auth/kakao/login?channel=app&target=polaris...`는 2026-04-26 확인 기준 `OIDC_TARGET_NOT_ALLOWED`를 반환한다. 앱 로그인 전에 백엔드에 iOS callback target/scheme 등록이 필요하다.
