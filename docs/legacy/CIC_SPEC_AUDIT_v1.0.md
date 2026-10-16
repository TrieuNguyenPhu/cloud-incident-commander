# Cloud Incident Commander — SRS/Architecture/Database/Backlog Audit

**Ngày rà soát:** 2026-10-15  
**Phiên bản nguồn:** Baseline v1.0 (6 files)  
**Kết luận:** **NOT READY for blind full implementation**. **READY for P0 discovery/contracts** once the blocking corrections are accepted. Original baseline documents have **not** been modified by this audit.

## A. Kiểm tra tính toàn vẹn và phạm vi

- 6/6 file trong ZIP, ZIP integrity test pass; archive contents match working copies byte-for-byte.
- 28 functional requirements (FR-001..FR-028); 14 NFR; 10 MVP UAT; 18 SVC boundaries.
- 3 DynamoDB tables (core, dedupe, audit), 3 sparse GSIs; 8 phases (P0-P7).
- 64 CSV backlog rows; all issue IDs unique; all literal `P#-##` dependency IDs exist; no forward/self dependencies.
- Story-point summary: P0=20, P1=38, P2=44, P3=26, P4=52, P5=40, P6=39, P7=69; **total=328**.
- Scope matches key choices: AWS-only infrastructure, Next.js + TypeScript UI, GitHub Actions main CI/CD; EKS/ROSA/Nomad and alternate CI/CD as on-demand labs; AI read-only recommendations.

## B. Chặn triển khai (BLOCKER)

| ID | Phát hiện | Vị trí / bằng chứng | Hệ quả | Sửa yêu cầu |
|---|---|---|---|---|
| B01 | `P1-06` phải publish `DeploymentEvent` và P1 exit gate đòi event đã về CIC, nhưng bus/queue/consumer chỉ được triển khai tại `P2-01`. | `04_PHASE_BACKLOG.md`, P1-06 / P2-01 | Không thể nghiệm thu P1 theo kế hoạch. | Đưa event bus + deployment recorder nhỏ vào P1, hoặc sửa exit gate P1 và chỉ publish/ingest ở P2. Đề nghị phương án đầu. |
| B02 | P1 cần inventory và deployment history **thật** (`FR-002`, `FR-005`, P1-07), nhưng chưa có story cụ thể triển khai scheduled inventory collector, lưu deployment, resource mapping và API đọc thực. | `01_SRS.md` FR-002/005; `02_SERVICE_ARCHITECTURE.md` SVC-04/07; `04_PHASE_BACKLOG.md` P1-04/07 | UI có thể rỗng hoặc dummy nhưng được ghi là đạt tiêu chí. | Thêm story P1-09 `inventory collector + deployment recorder + read API` và dependency bắt buộc trước P1-07, hoặc chia lại P1-04/06. |
| B03 | Audit được mô tả như append-only do IAM chỉ cấp `PutItem`, nhưng `PutItem` **mặc định có thể ghi đè item cùng key**; một IAM policy đơn thuần không ép `ConditionExpression` phải tồn tại trong request. | `03_DATABASE_DESIGN.md` Table C; `02_SERVICE_ARCHITECTURE.md` SVC-15 | Tuyên bố “immutable-by-policy” chưa đúng về bảo đảm an ninh. | Đổi mô tả thành application-enforced append-only + tested conditional Put, least privilege + CloudTrail; nếu cần WORM thực sự thì xuất audit sang S3 Object Lock cùng retention/bucket policy theo threat model. |
| B04 | P4-03 yêu cầu approval audit, nhưng writer/audit timeline ở P4-07, trong khi P4-07 phụ thuộc P4-03 và P4-06. | `04_PHASE_BACKLOG.md` P4-03 / P4-07 | Không thể hoàn thành definition of done cho P4-03 theo dependency list. | Chuyển audit primitive + outbox schema vào P1/P2, audit decision P4-03 ngay khi triển khai, P4-07 chỉ bổ sung coverage/export/validation. |
| B05 | Mô tả ECS Fargate không chọn một mô hình egress/network khả thi: private subnet không NAT phải có endpoint ECR/S3/CloudWatch; public subnet cần public IP/route phù hợp. Luồng tạo alarm HTTP 5xx có ALB hoặc custom metric cũng chưa chốt. | `02_SERVICE_ARCHITECTURE.md`, sections 4, 11; `01_SRS.md` UC-001/UAT-01 | Có thể task không kéo image/gửi logs; không tái hiện được incident 5xx thật. | Chốt 1 profile MVP: public subnet + task public IP + no inbound SG + IGW egress + app emits structured 5xx logs + metric filter/alarm; hoặc private subnet + explicit NAT/endpoints và ALB/test generator (có cost plan). Bổ sung Terraform paths và network diagram. |

## C. HIGH — cần sửa trước khi coding domain

| ID | Phát hiện | Sửa cụ thể |
|---|---|---|
| H01 | EventBridge custom bus chưa nêu rõ bus model và routing AWS service events từ default bus; AWS native alarms được gửi vào default bus. | Chốt Classic custom bus + rule `default -> custom -> SQS`, hoặc default bus -> SQS trực tiếp; test fixture `aws.cloudwatch` event envelope và rule. |
| H02 | Thiết kế ingestion webhook vừa nằm chung API Gateway JWT authorizer, vừa phải nhận HMAC webhooks từ GitLab/Bitbucket/Jenkins. | Tách routes authorizer: `/v1/*` Cognito JWT, `/webhooks/*` không dùng Cognito, nhưng bắt buộc HMAC/connector signature, replay protection, secret rotation, rate limits. |
| H03 | SRS BR-01 đòi `observed_at`, canonical `SignalEvent v1` dùng `occurred_at`. | Chốt dùng `occurred_at` nguồn, `ingested_at` hệ thống; đổi BR-01 và fixtures. |
| H04 | UAT-08 dùng `VERIFY_SUCCESS/VERIFY_FAILED`, database enum dùng `VERIFIED/FAILED/UNKNOWN`. | Chốt `Verification.status = VERIFIED|FAILED|UNKNOWN` và sửa UAT/sequence/API. |
| H05 | Resource PK `RESOURCE#SHA256(resource_uid)` không chứa tenant nhưng SRS nêu đường nâng cấp multi-tenant; nếu 2 tenants theo dõi cùng ARN, record collisions. | Hoặc tuyên bố single-tenant v1 strictly và không tuyên bố isolation across tenants, hoặc hash `tenant_id + canonical_resource_uid` để nhất quán. Đề nghị phương án sau. |
| H06 | SRS FR-003 nói search/filter status/severity/resource, nhưng GSI chỉ hỗ trợ status và resource queries; full-text search không được thiết kế. | Scope MVP search tới incident ID / exact resource / bounded status+severity; defer full-text đến P5+ hoặc thêm search index. Kiểm thử pagination qua nhiều status. |
| H07 | Executor preflight re-read không phải CAS nguyên tử với ECS `UpdateService`; document đã nhận biết race external deploy, nhưng NFR/SRS còn gọi `compare-and-swap revision` như bảo đảm toàn phần. | Sửa wording: best-effort drift check + CIC lock + single workflow execution + monitor external drift, không tuyên bố atomic CAS ngoài DynamoDB. Test concurrent GitHub deploy/executor. |
| H08 | API contract mới chỉ có endpoint table + 1 action request; chưa có OpenAPI/JSON schema versioned cho response/error/pagination/authz và all workflows. | P0-03 phải sinh OpenAPI 3.x + Pydantic types + JSON Schema fixtures; wire CI contract diff. |

## D. MEDIUM — hoàn thiện để coder không tự đoán

| ID | Phát hiện | Hành động |
|---|---|---|
| M01 | Không có bảng FR → Service → API → DB → Story → Test mapping, dù P0-01 yêu cầu traceability. | Thêm traceability matrix ngay P0. |
| M02 | Region, Bedrock model/version/access và hard ceiling cho ngân sách từng phase chưa chốt. | Quy định region mặc định sau khi kiểm tra model/quotas; budget alert thresholds, max runtime, weekly spend review; Terraform vars, secret naming. |
| M03 | MFA cho Approver/Admin mới là `where configured`, chưa phải gate cứng. | Định nghĩa authn policy và step-up/MFA theo threat model; role granting/rotation/revocation. |
| M04 | UAT incident 5xx, ALB tùy chọn, HTTP traffic generator và error emission thiếu script. | Tạo reproducible `healthy -> bad -> rollback -> verify` harness, alarms và dashboard được instrument chính xác. |
| M05 | State `CLOSED -> INVESTIGATING` nhưng chưa định rõ lifecycle khi reopen (fingerprint lock, severity, postmortem superseding). | Viết transition table và tests với new incident/reopened scenario. |
| M06 | Evidence 90d, audit 365d, postmortem vô thời hạn nhưng không định nghĩa biểu diễn evidence đã hết retention khi truy vấn báo cáo. | Giữ metadata/digest, đánh dấu `EXPIRED`, UI hiển thị rõ; kiểm tra legal hold/retention override. |
| M07 | P6-04 IAM/RBAC adapter thực hiện sau P6-03 connector đã chạy, P6-05 chưa phụ thuộc P6-04. | Đưa security boundary trước production-like connector và Jenkins X lab; sửa dependencies. |
| M08 | P7-07 gom GitHub/GitLab/Bitbucket connectors vào 5 SP thiếu per-provider auth/callback/error tests. | Tách GitLab SCM, Bitbucket SCM, Jenkins event contract thành stories riêng và per-provider UAT. |
| M09 | Kế hoạch EKS/ROSA, ELK và EC2 chưa có detailed cost forecast/hard budget cap; AWS Budgets không phải spend cut-off. | Phụ lục cost per phase, teardown inventory, worst-case resources (NAT, EBS, ELB, IP, snapshot, logs), AWS billing alarms. |
| M10 | Không có deployment readiness package: exact Terraform module dependency, parameter table, IAM matrix, secrets, rollback runbook, backup-restore scripted test. | Bổ sung trong P0-P1 trước AWS apply; staging/dry-run costs, security review. |

## E. Đề xuất thứ tự sửa tài liệu thành v1.1

1. **SRS:** đồng bộ event names/status, scope search/reopen, điều kiện success 5xx scenario, mục tiêu backup/audit thực tế; thêm FR/AC traceability.
2. **Architecture:** chọn profile mạng Fargate và alarm generator, rõ default EventBridge bus/custom bus, tách JWT và webhook HMAC, chốt deployment recorder và immutable audit claims.
3. **Database:** sửa tenant scope resource PK, audit classification, evidence expired metadata, consistency/lock/outbox flow.
4. **Backlog:** giải quyết B01/B02/B04, sửa P6 dependencies, thêm stories cho audit, inventory, alarm harness, contract schemas và IAM/network tests. Lập lại story points/timeline sau khi sửa.
5. **Quality:** lập artifacts mở rộng: `API_OPENAPI.yaml`, `EVENT_SCHEMAS`, `IAM_ACCESS_MATRIX`, `REQUIREMENT_TRACEABILITY`, `UAT_TEST_CASES`, `COST_BUDGET`, `RUNBOOKS`.

## F. Gate kết luận

- **Hiện tại:** Có thể bắt đầu P0 (repo skeleton, contract design, threat model, cost guardrails) nhưng **không nên bật Codex auto-implement toàn bộ P0..P7** dựa vào v1.0 mà không vá các blocker.
- **Khi B01-B05 đã sửa, H01-H08 được đặc tả và các dependency cập nhật:** Có thể gọi tài liệu *implementation-ready for MVP P0-P4*; vẫn chưa có actual cloud deployment hoặc pass test.
- **P5-P7:** Cần kiểm tra thực tế khả năng cung cấp, version compatibility, AWS quota, ROSA support và ngân sách tại thời điểm provision; không thể chứng nhận completion chỉ dựa vào tài liệu.

## G. Tài liệu kỹ thuật AWS đối chiếu

- DynamoDB PutItem (overwrite default, conditional put): https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_PutItem.html
- EventBridge AWS service events -> default bus: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-events.html
- API Gateway HTTP API JWT authorizer on routes: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html
- Fargate task networking, image pull: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html
- S3 Object Lock WORM: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html
- Step Functions Standard idempotent StartExecution: https://docs.aws.amazon.com/step-functions/latest/apireference/API_StartExecution.html
