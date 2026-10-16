# Kế hoạch MVP: hoàn thiện luồng local trước, triển khai AWS sau

**Ngày:** 2026-10-16 · **Trạng thái:** đề xuất để thực hiện theo từng PR nhỏ.

## Mục tiêu và phạm vi

"Tính năng quan trọng" là luồng UC-001/P0–P4: xem tài nguyên và bản triển khai,
nhận sự cố, xem bằng chứng, đọc phân tích, yêu cầu rollback, người khác phê duyệt,
kiểm tra kết quả và xuất postmortem. P5–P7 vẫn theo backlog gốc.

Hiện repo có nền P0 (web chỉ có trang đầu và API chỉ có `/healthz`). PR #2 đã
merge cấu hình S3/CloudFront cho P1-01; chưa apply AWS hoặc upload web. Kế hoạch
này thay đổi **thứ tự viết và kiểm tra code**, không thay tiêu chí nghiệm thu
trong `docs/04_PHASE_BACKLOG.md`, OpenAPI, ADR hay cổng AWS ở
`docs/07_RELEASE_READINESS.md`. Một story có thể đạt **local-ready** nhưng chỉ
được đánh dấu **DONE** khi bằng chứng AWS mà story yêu cầu đã có.

## Quyết định thực hiện

- Dùng Next.js/FastAPI, contract v1.1 và DynamoDB Local cho dữ liệu demo. Dữ liệu
  seed đi qua API/persistence thật; UI không dùng mảng dữ liệu hard-code.
- Dùng danh tính, report AI và ECS client **chỉ trong local** để thử quyền và
  luồng an toàn. Cấu hình deploy phải từ chối local mode. Cùng validator/chính
  sách nghiệp vụ được dùng khi nối Cognito, Bedrock, Step Functions và ECS thật.
- Mỗi PR có một lát chức năng nhìn thấy hoặc kiểm chứng được: dữ liệu/API/UI hay
  một chuyển trạng thái có test tập trung. Không thêm lớp mở rộng khi chưa cần.
- Không gọi rollback AWS từ local. Không ghi mock là bằng chứng đã triển khai.
  DynamoDB audit là append-only do application kiểm soát, không phải WORM.

## Thứ tự local

Mỗi task dưới đây là một PR nhỏ. `npm run check` là cổng chung; chỉ chạy kiểm tra
tập trung cần thiết cho logic vừa thay đổi. File liệt kê là nơi dự kiến chạm tới,
không phải danh sách phải tạo đủ.

### L01 — Dữ liệu demo bền vững

- **Phụ thuộc:** P0-03. **Backlog:** phần local của P1-03.
- **Làm:** chạy DynamoDB Local, tạo bảng theo `docs/03_DATABASE_DESIGN.md`, seed
  idempotent một ECS resource, hai deployment và một alarm fixture.
- **Đạt khi:** khởi động lại API không mất seed; chạy seed hai lần không nhân bản;
  không cần AWS credentials. **Kiểm tra:** đọc lại ba loại record và thử seed lặp.
- **Vùng code:** `infra/`, `scripts/`, `services/api/`, `tests/`. **Cỡ:** M.

### L02 — Ranh giới quyền local

- **Phụ thuộc:** L01. **Backlog:** logic RBAC của P1-02.
- **Làm:** bảo vệ `/v1/*` bằng cùng ma trận Viewer/Operator/Approver/Admin; cho
  local demo đổi vai qua cơ chế chỉ hoạt động ở máy phát triển.
- **Đạt khi:** thiếu danh tính trả 401, sai vai/tenant trả 403; cấu hình deploy
  không thể bật local identity. **Kiểm tra:** các ca 401/403 và fail-closed.
- **Vùng code:** `services/api/`, `tests/security/`, cấu hình local. **Cỡ:** M.

### L03 — Tài nguyên và lịch sử triển khai nhìn thấy trên web

- **Phụ thuộc:** L01–L02. **Backlog:** phần local của P1-07/P1-10.
- **Làm:** API đọc resource/deployment từ DynamoDB Local; web có layout, trang
  resources/deployments, trạng thái loading/empty/error và link resource.
- **Đạt khi:** web hiển thị đúng seed qua API và phản ánh dữ liệu mới sau refresh;
  Viewer không truy cập record tenant khác. **Kiểm tra:** API read + kiểm tra tay
  hai trang trên local. **Vùng code:** `services/api/`, `apps/web/`, `tests/`. **Cỡ:** M.

**Checkpoint 1:** người dùng nhìn thấy dữ liệu thật của local store, không còn
chỉ trang chào; CI xanh. Story P1-07 vẫn chờ Cognito và inventory AWS thật.

### L04 — Mutation và outbox an toàn

- **Phụ thuộc:** L01–L02. **Backlog:** logic local của P1-11.
- **Làm:** ghi mutation và outbox cùng transaction; writer ghi audit bằng
  conditional PutItem, retry không ghi đè.
- **Đạt khi:** lỗi audit không làm mất outbox; ghi lặp cùng ID không thay nội dung.
  **Kiểm tra:** transaction failure, retry và overwrite rejection bằng DynamoDB
  Local. **Vùng code:** `services/api/`, `tests/integration/`. **Cỡ:** M.

### L05 — Alarm fixture tạo đúng một incident

- **Phụ thuộc:** L01, L04. **Backlog:** logic local của P2-02/P2-03.
- **Làm:** dùng schema v1.1 để chuẩn hóa alarm/deployment fixture, fingerprint
  theo tenant/resource/time window, lưu incident và timeline.
- **Đạt khi:** phát cùng event năm lần chỉ có một incident và một timeline item;
  event sai schema bị từ chối. **Kiểm tra:** duplicate, out-of-order và invalid
  fixture. **Vùng code:** `services/api/`, `packages/contracts/`, `tests/`. **Cỡ:** M.

### L06 — Trang incident và chuyển trạng thái

- **Phụ thuộc:** L02, L05. **Backlog:** logic local của P2-04/P2-07.
- **Làm:** list/detail/timeline có filter, cursor; Operator ACK/transition qua
  API với optimistic version và audit.
- **Đạt khi:** Viewer xem được nhưng không đổi trạng thái; version cũ trả 409;
  timeline đúng thứ tự. **Kiểm tra:** API permission/version và thao tác trên web.
- **Vùng code:** `services/api/`, `apps/web/`, `tests/`. **Cỡ:** M.

**Checkpoint 2:** từ alarm fixture đến incident/timeline trên web chạy lại được
trong local. P2-08 vẫn chờ alarm/EventBridge/SQS thật và đo thời gian trên AWS.

### L07 — Bằng chứng có giới hạn và digest

- **Phụ thuộc:** L05–L06. **Backlog:** logic local của P2-05/P2-06/P2-07.
- **Làm:** thu thập từ fixture có time/size bound, redaction, SHA-256 manifest;
  local file store chỉ dùng cho dev và evidence tab đọc qua API có quyền.
- **Đạt khi:** log chứa secret bị che; evidence quá hạn/quá lớn bị xử lý rõ;
  digest khớp bytes. **Kiểm tra:** bound/redaction/digest và Viewer scope.
- **Vùng code:** `services/api/`, `apps/web/`, `tests/`. **Cỡ:** M.

### L08 — Phân tích và đề xuất có căn cứ

- **Phụ thuộc:** L07. **Backlog:** logic local của P3-02/P3-04/P3-05/P3-06.
- **Làm:** nạp AI report fixture qua validator sản xuất; UI hiển thị evidence
  links, confidence, INCONCLUSIVE và một đề xuất rollback hợp lệ hoặc null.
- **Đạt khi:** evidence ID không tồn tại, action ngoài allowlist hoặc output thiếu
  căn cứ bị từ chối; AI không có quyền thực thi. **Kiểm tra:** fixture hợp lệ và
  các ca fabricated/unsafe. **Vùng code:** `services/api/`, `apps/web/`, `tests/`.
  **Cỡ:** M.

### L09 — Yêu cầu và quyết định phê duyệt

- **Phụ thuộc:** L02, L04, L08. **Backlog:** logic local của P4-01/P4-03.
- **Làm:** Operator tạo yêu cầu có expiry/idempotency key; Approver khác người
  quyết định trên web; ghi outbox/audit và trạng thái.
- **Đạt khi:** self-approval 403, quyết định hết hạn không tác động, gửi lặp
  không tạo quyết định mới, version cũ 409. **Kiểm tra:** các ca âm + luồng hai
  vai trên local. **Vùng code:** `services/api/`, `apps/web/`, `tests/`. **Cỡ:** M.

**Checkpoint 3:** đi được từ incident → evidence → phân tích → phê duyệt trên
local; không có đường gọi Bedrock/Step Functions/ECS thật.

### L10 — Rollback giả lập và xác minh

- **Phụ thuộc:** L09. **Backlog:** logic local của P4-04/P4-05/P4-06.
- **Làm:** preflight so expected/current revision và allowlist, resource lease,
  executor dùng ECS client giả lập; ghi VERIFIED/FAILED/UNKNOWN.
- **Đạt khi:** drift hoặc từ chối phê duyệt không gọi UpdateService; retry không
  chạy hai lần; thiếu telemetry là UNKNOWN. **Kiểm tra:** spy client, drift,
  duplicate và ba trạng thái. **Vùng code:** `services/api/`, `tests/`. **Cỡ:** M.

### L11 — Audit và postmortem

- **Phụ thuộc:** L04, L06–L10. **Backlog:** logic local của P4-07/P4-08.
- **Làm:** admin xem/export audit theo quyền; tạo bản nháp Markdown từ timeline,
  evidence và kết quả action, chỉnh sửa được.
- **Đạt khi:** Viewer không đọc audit; export có digest; postmortem nói rõ RCA
  chưa chắc chắn. **Kiểm tra:** quyền, digest và bản nháp từ incident seed.
- **Vùng code:** `services/api/`, `apps/web/`, `tests/`. **Cỡ:** M.

### L12 — Demo local hoàn chỉnh

- **Phụ thuộc:** L01–L11. **Backlog:** chuẩn bị cho P4-09, chưa nghiệm thu AWS.
- **Làm:** một lệnh seed và hướng dẫn đi từ deployment lỗi đến postmortem bằng
  hai vai; gắn kết quả kiểm tra vào PR.
- **Đạt khi:** người mới chạy lại được toàn luồng; các ca duplicate, 401/403,
  self-approval, drift và thiếu telemetry đều có bằng chứng; không có AWS API call.
  **Kiểm tra:** chạy theo README local và focused suite. **Vùng code:** `README.md`,
  `scripts/`, `tests/`. **Cỡ:** M.

**Cổng local-ready:** L01–L12 xong, web/API chạy được bằng lệnh trong README, CI
xanh, demo end-to-end local tái hiện được và mọi thành phần giả lập được ghi rõ.

## Lên AWS và chuyển sang vòng phát triển–deploy

1. **AWS gate:** đóng các mục external còn mở của P0: independent review,
   account/role/region, IAM/OIDC, budget recipient, estimate, state isolation;
   duyệt saved Terraform plan đúng `docs/07_RELEASE_READINESS.md`. Không auto-apply.
2. **Bản deploy đầu tiên:** dùng P1-01 đã merge để đưa static export lên S3/CloudFront
   HTTPS; sau đó P1-03, P1-02, P1-04 để web dùng Cognito, DynamoDB và Lambda thật.
   Smoke kiểm tra HTTPS, 401/403, MFA và data read. Chỉ ở đây bắt đầu vòng
   **code local → PR/CI → plan/cost review → deploy dev → smoke/record evidence →
   sửa hoặc rollback** cho từng story.
3. **Nguồn tín hiệu thật:** theo P1-05 → P1-12 → P1-08 và P1-09 → P1-06 →
   P1-10/P1-07/P1-11; rồi P2-01 → P2-08. Chứng minh ECS task 5xx tạo incident
   có evidence, event/deployment link và độ trễ đo được.
4. **Điều tra và xử lý thật:** P3-01 → P3-06 cho Bedrock có giới hạn; P4-01 →
   P4-09 cho Step Functions, rollback ECS đúng scope, verification và UAT-01..20.
   Deploy từng lát vào dev theo vòng ở bước 2; không đợi toàn P4 mới deploy.

## Rủi ro và giới hạn

| Rủi ro                                        | Cách giữ phạm vi đúng                                                                          |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Local demo bị hiểu là integration AWS         | `local-ready` và `DONE` tách biệt; AWS event IDs, resource IDs và UAT chỉ ghi sau deploy thật. |
| Local identity/adapter lọt vào deploy         | Local mode phải fail-closed khi chạy profile AWS; CI có ca âm.                                 |
| AWS rollout cần sửa code vì mock khác thực tế | Dùng cùng OpenAPI/schema, DynamoDB Local và các test adapter; triển khai AWS theo lát nhỏ.     |
| Chi phí hoặc dữ liệu bị tác động bởi apply    | Giữ cờ mặc định tắt, plan/cost/IAM review và duyệt trước từng apply; kiểm tra destroy scope.   |

## Việc kế tiếp

Bắt đầu **L01**, sau đó **L02–L03** để người dùng sớm thấy trang tài nguyên và
lịch sử triển khai lấy từ API local. Không mở rộng sang P5–P7 trước cổng local.
