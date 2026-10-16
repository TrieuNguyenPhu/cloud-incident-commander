# Local-first MVP task list

Chi tiết nghiệm thu, kiểm tra và phụ thuộc ở [plan.md](plan.md). Chỉ đánh dấu
`local-ready` trong danh sách này; trạng thái story P1–P4 ở backlog gốc vẫn chờ
bằng chứng AWS.

## Local

- [ ] L01 Dữ liệu demo bền vững trên DynamoDB Local
- [ ] L02 Ranh giới quyền và danh tính chỉ cho local
- [ ] L03 Tài nguyên và lịch sử triển khai qua API lên web
- [ ] Checkpoint 1: web đọc dữ liệu local bền vững, CI xanh
- [ ] L04 Mutation và outbox/audit an toàn
- [ ] L05 Alarm fixture tạo đúng một incident
- [ ] L06 Incident list/detail/timeline và chuyển trạng thái
- [ ] Checkpoint 2: alarm fixture → incident trên web
- [ ] L07 Bằng chứng có giới hạn, redaction và digest
- [ ] L08 Phân tích có căn cứ và đề xuất hợp lệ
- [ ] L09 Yêu cầu và quyết định phê duyệt của hai vai
- [ ] Checkpoint 3: incident → evidence → phân tích → phê duyệt
- [ ] L10 Preflight, rollback giả lập và drift guard
- [ ] L11 Xác minh VERIFIED/FAILED/UNKNOWN sau rollback giả lập
- [ ] L12 Audit theo quyền, outbox reconciliation và export
- [ ] L13 Bản nháp postmortem chỉnh sửa được
- [ ] L14 Demo local hoàn chỉnh, hướng dẫn chạy lại và ca âm
- [ ] Cổng local-ready: UI/API end-to-end, CI xanh, mock được gắn nhãn rõ

## AWS rồi phát triển–deploy liên tục

- [ ] AWS gate: P0 external controls, account/region/IAM/budget/plan/cost approval
- [ ] Deploy đầu: CloudFront/S3, DynamoDB, Cognito, API Lambda; smoke thật
- [ ] Bắt đầu vòng mỗi story: local → PR/CI → approved plan → dev deploy → evidence
- [ ] P1 nguồn thật: ECS, deployment recorder, inventory, CloudWatch alarm
- [ ] P2 tín hiệu → incident → evidence qua EventBridge/SQS/S3 thật
- [ ] P3 Bedrock có giới hạn, policy validator và đánh giá output
- [ ] P4 Step Functions, ECS rollback có approval, verification, UAT-01..20
