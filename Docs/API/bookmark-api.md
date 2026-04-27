# 찜 API 명세

확인일: 2026-04-26
Source: https://polaris.nimonic.dev/api-docs.json
앱 구현 Base URL: `https://api.k-polaris.life/api/v1`

## 인증

아래 API는 모두 인증이 필요하다.

```http
Authorization: Bearer <accessToken>
```

## 엔드포인트 요약

| 기능 | Method | Path | Response |
| --- | --- | --- | --- |
| 도서관 찜 등록 | `POST` | `/libraries/{libraryId}/bookmark` | `204 No Content` |
| 도서관 찜 해제 | `DELETE` | `/libraries/{libraryId}/bookmark` | `204 No Content` |
| 도서 찜 등록 | `POST` | `/books/{isbn}/bookmark` | `204 No Content` |
| 도서 찜 해제 | `DELETE` | `/books/{isbn}/bookmark` | `204 No Content` |
| 찜한 도서관 목록 조회 | `GET` | `/users/me/bookmarked-libraries` | `BookmarkedLibrariesResponse` |
| 찜한 도서 목록 조회 | `GET` | `/users/me/bookmarked-books` | `BookmarkedBooksResponse` |

## 도서관 찜 등록/해제

```http
POST /api/v1/libraries/{libraryId}/bookmark
DELETE /api/v1/libraries/{libraryId}/bookmark
Authorization: Bearer <accessToken>
```

### Path Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `libraryId` | `integer(int64)` | yes | 도서관 ID |

### Response

```http
204 No Content
```

## 도서 찜 등록/해제

```http
POST /api/v1/books/{isbn}/bookmark
DELETE /api/v1/books/{isbn}/bookmark
Authorization: Bearer <accessToken>
```

### Path Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `isbn` | `string` | yes | 도서 ISBN |

### Response

```http
204 No Content
```

## 찜한 도서관 목록 조회

```http
GET /api/v1/users/me/bookmarked-libraries
Authorization: Bearer <accessToken>
```

### Response

```json
{
  "items": [
    {
      "libraryId": 1,
      "name": "구미시립양포도서관",
      "address": "경상북도 구미시 옥계북로 51"
    }
  ]
}
```

### Data Item

| Field | Type | Description |
| --- | --- | --- |
| `libraryId` | `integer(int64)` | 도서관 ID |
| `name` | `string` | 도서관명 |
| `address` | `string` | 주소 |

## 찜한 도서 목록 조회

```http
GET /api/v1/users/me/bookmarked-books
Authorization: Bearer <accessToken>
```

### Response

```json
{
  "items": [
    {
      "isbn": "9791198363510",
      "title": "아몬드",
      "author": "손원평",
      "coverImageUrl": "https://nl.go.kr/seoji/fu/ecip/dbfiles/CIP_FILES_TBL/2023/06/9791198363510.jpg"
    }
  ]
}
```

### Data Item

| Field | Type | Description |
| --- | --- | --- |
| `isbn` | `string` | 도서 ISBN. 예시가 숫자로 내려올 수 있어 iOS에서는 문자열로 정규화한다. |
| `title` | `string` | 도서명 |
| `author` | `string` | 저자 |
| `coverImageUrl` | `string` | 표지 이미지 URL |

## 구현 메모

- 현재 OpenAPI 기준 찜 API는 `{ status, message, data }` 래퍼를 쓰지 않는다.
- 등록/해제 API는 `204 No Content`라서 body decoding 없이 2xx 여부만 확인한다.
- 목록 응답은 `{ items: [...] }` 형태다.
- 기존 문서의 `/likes`, `/me/liked-*`, `imageUrl`, `publisher` 필드는 현재 OpenAPI와 다르므로 구현에 사용하지 않는다.
