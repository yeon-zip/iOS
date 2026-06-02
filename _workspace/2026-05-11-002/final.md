본 논문에서 제안하는 소장도서 검색 서비스는 클라이언트, Spring Boot 서버, 데이터베이스, 외부 API로 구성된다. 클라이언트는 사용자가 입력한 검색어와 현재 위치 또는 선택한 주소, 탐색 반경을 서버로 전달한다. 서버는 이 값을 바탕으로 도서 검색, ISBN 추출, 도서관 소장 조회를 차례로 수행한다. 도서 검색 단계에서는 네이버 도서 검색 API를 호출해 후보 도서 목록을 가져오고, 응답 데이터에서 추출한 ISBN을 도서관 정보나루 API 요청에 활용한다. 도서관 정보나루 API를 통해 해당 도서를 소장한 도서관과 대출 가능 여부를 확인한다. 국가자료종합목록 OpenAPI는 제목, 저자, 출판사 등 서지 정보를 보완하는 데 사용하며, 카카오맵 API는 주소 검색과 지도 표시 기능을 담당한다. 본 서비스의 전체 구성도는 그림 1과 같다.

<!-- HUMANIZE-SUMMARY v2.0.0
mode: fast
run_id: 2026-05-11-002
original_length: 444
rewritten_length: 423
length_delta_rate: 4.7%
metrics_risk_band: absent
metrics_note: prepare_monolith_input.py completed with degraded=true; no baseline risk score available.
category_counts_before: A-2=2, A-6=1, H-1=0, E-2=3, F-4=2
category_counts_after: A-2=1, A-6=0, E-2=1, F-4=1
self_check: 6/6
quality_grade: A
highlights:
- Repaired line-break artifacts that split words such as "도 서" and "정 보나루".
- Reduced repetitive "서버는" sentence openings by linking related API steps.
- Preserved API names, component structure, and figure reference.
- Kept a formal report style without adding new functions or claims.
residual_findings: Some technical nouns remain because they are required by the system description.
-->
