# Architecture Decision Records — v1.1

Each record is an immutable decision identifier (the design may be amended only in a later ADR). A coding agent MUST NOT explore alternatives unless the specified deployment is demonstrably unavailable, insecure or unreasonably expensive; then create a change request.

| ADR | Decision | Why | Trade-off |
|---|---|---|---|
| ADR-001 | AWS only, one AWS account for dev/lab with separated state and IAM | Simplicity, no multi-cloud operations | No cross-cloud DR |
| ADR-002 | Next.js static export + TypeScript on private S3 OAC / CloudFront | Low idle cost; app uses client OIDC PKCE | No SSR, Next.js server actions/routes |
| ADR-003 | FastAPI + Lambda behind API Gateway HTTP API | Python AI domain, pay-per-use | Lambda cold starts; request ceiling |
| ADR-004 | Single-tenant DynamoDB core/dedupe/audit + S3 evidence | No always-on RDS; bounded patterns | Explicit indexes/consistency, no SQL joins |
| ADR-005 | P1 custom **Classic** EventBridge bus; P2 default bus alarm routing | P1 recorder available; vendor AWS events arrive on default | Two rules + permissions to test |
| ADR-006 | P1 Fargate public subnet/public IPv4; NO inbound; no NAT/ALB | Low number of always-on paid network components; predictable 5xx lab | Public IPv4 charged; not general internet-facing production service |
| ADR-007 | Internal synthetic HTTP traffic → access JSON log metric filter 5xx | Reproducible 5xx without ALB | Synthetic user requests, documented as lab |
| ADR-008 | Bedrock read-only evidence-grounded RCA | Limit model authority and prompt injection risk | Manual verification of suggestions |
| ADR-009 | Step Functions Standard + separate approval + ECS rollback only | Safe automation, traceable saga | ECS external UpdateService lacks atomic CAS |
| ADR-010 | DDB outbox + conditional Put audit, optional S3 Object Lock | Bounded complexity with honest guarantee | Not true immutable DDB |
| ADR-011 | GitHub Actions AWS OIDC CI/CD is primary | Limit static AWS secrets | Dependence on GitHub hosted CI |
| ADR-012 | EKS/ROSA/Nomad/CI/ELK AWS labs are manually approved opt-in | Meet technology goals without always-on spend | Full scope requires real provisioning and cost |
| ADR-013 | MFA for Approver/Admin + separation of duties | Prevent unauthorized/high-impact actions | Additional onboarding complexity |
| ADR-014 | Webhooks per-provider signature/secret/replay checks; separate from JWT API | Machines lack Cognito user token | Connector secret rotation needed |
| ADR-015 | Current deployment read before UpdateService plus resource lock | Reduce cross-run conflicts | Not atomic against external deployers |
| ADR-016 | Default MVP region ap-southeast-1, model ID verified at P3 | Localized deployment baseline | Region/model access could block AI feature |
| ADR-017 | v1.1 OpenAPI/JSON Schemas govern payloads and shared enums; phase gates follow backlog ownership and UAT IDs | Prevent divergent implementations from stale examples or circular release gates | Workflow substeps stay internal; AI report has one optional action and report-level citations |
| ADR-018 | Use `us-east-1` as the MVP AWS region; supersedes ADR-016's region default | The operator selected the new account and region for a lower-cost deployment candidate | Actual service pricing, quotas and Bedrock model access still require account-specific verification before apply |

## ADR-017 — Specification alignment (accepted 2026-10-16)

- Keep the existing OpenAPI Action/Approval enums in both API and storage; preflight/execution/verification are workflow steps under `RUNNING`. Adding a second public state vocabulary would require unnecessary translation and conflicting client behavior.
- Keep `AIAnalysisReport.schema.json`: string hypotheses, report-level confidence/evidence IDs, and one nullable `recommended_action`. Backend owns report IDs and model metadata; the architecture example and fixture must validate against this schema. A list of executable proposals is outside the initial single-runbook scope.
- MVP release requires **UAT-01..UAT-20**, including DLQ/poison-message and out-of-order cases. The measured backup/restore drill remains a **P5-09** gate, matching NFR-007 traceability; P4 retains rollback verification, DLQ recovery and scoped teardown. Requiring P5-09 before P4 would create a circular gate because P5-09 depends on P4 completion.
- These corrections align the specification only; implementation and AWS acceptance remain pending.

## ADR-018 — Region amendment (accepted 2026-10-16)

The current deployment baseline is `us-east-1` in the new AWS account. ADR-016
remains in this log as the historical decision; its `ap-southeast-1` default no
longer applies. Source examples, event fixtures, API host, sample environments,
Terraform backends and the GitHub plan workflow use `us-east-1`.

The choice is a cost hypothesis, not an account-specific quote. Before the first
billable plan/apply, compare exact services and usage in the AWS Pricing Calculator,
verify quotas/model access and record account, cost and approval under
`13_COST_BUDGET.md`. Do not migrate or delete resources in another region merely
because the local default changed.

## Deployment facts vs specification

- No AWS service has been created by these documents.
- IAM `Resource`/Condition support must be tested against provider API; a broad permission in a policy example is not automatically production-approved.
- No AWS Budget guarantees a service cannot incur charges. `terraform destroy` requires verifying no residual ENI/EIP, volume, load balancer, snapshots, CloudWatch Logs or third-party charges.
