# Release & AWS Apply Readiness Gates

## Gate P0 (no production provisioning)

- [ ] Repository and branch protection are configured; code review is required.
- [ ] OpenAPI schema and JSON Schema fixtures validate; typed Python/TypeScript domain types generated or synced.
- [ ] `terraform fmt`, `terraform validate`, Checkov/Trivy/secret scanning pass; backend and frontend CI checks pass.
- [ ] Threat model reviewed, approval/signer boundary recorded, environment-specific accounts/ARNs confirmed.
- [ ] Core vs lab backend isolated; Terraform destroy scope checked and tags/TTL enforced.
- [ ] Budget alerts configured (manually confirm messages received); AWS IAM OIDC trust conditions reviewed.

## Gate before EVERY terraform apply

1. Record AWS account (masked), region, commit SHA, target state name and exact resources.
2. Run fmt/validate, provider lockfile validation, security scan and `terraform plan -out=<artifact>`; compare against declared change list.
3. Confirm quote or estimate for runtime, network, public IP, logs, secrets, storage and potential unused resources; obtain explicit approval.
4. Ensure no core resources appear in a lab state destroy. Inspect IAM wildcard permissions and externally accessible ingress.
5. Apply exactly the reviewed plan in an approved CI environment; capture CloudTrail IDs and output digests. Do not run interactive unexplained `terraform apply -auto-approve`.
6. Run smoke tests; keep rollback path and verified prior task definition revision.

## Gate P1

- [ ] Real Cognito login and permissions (incl approver/admin MFA and denial tests).
- [ ] Real ECS task healthy/faulty transitions, public subnet outbound path, zero inbound SG.
- [ ] App HTTP status 500 shown by localhost test client; metric filter counts 5xx and alarm state observed.
- [ ] GitHub deploy event signed by IAM/OIDC on custom event bus and persisted by deployment recorder.
- [ ] ECS collector stores real service inventory; UI queries real data; outbox audit primitive fails safely on overwrite.

## Gate P4 — MVP release

- [ ] UAT-01..UAT-20 pass with timestamps/trace IDs and references, including DLQ/poison-message replay and out-of-order delivery.
- [ ] AI recommendation cannot execute anything; role/separation-of-duty/MFA negative tests pass.
- [ ] Concurrent ECS outside change detected when re-read; no false claim of atomic guarantee.
- [ ] Verification evidence proves `VERIFIED | FAILED | UNKNOWN` behave correctly.
- [ ] Postmortem, audit outbox drain, and DLQ/backpressure dashboards work.
- [ ] ECS rollback verification and DLQ recovery pass; full lab teardown + no cross-state deletes.

## P5..P7 completion

- [ ] P5-09 backup/restore drill measured and recorded against NFR-007 RPO/RTO targets; do not claim these targets achieved at P4.

Real EKS/ROSA/OpenShift/Nomad/Jenkins/GitLab/Jenkins X/ELK integrations, real provider event ingestion, recorded cost and teardown proof. Any blocked external prerequisite keeps story OPEN rather than treating stub/mock as DONE.
