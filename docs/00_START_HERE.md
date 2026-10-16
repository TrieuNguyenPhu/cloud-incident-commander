# Cloud Incident Commander — Complete Implementation Specification v1.1

**Date:** 2026-10-15 · **Cloud target:** AWS (GCP/Azure out of scope) · **State:** SPECIFICATION COMPLETE FOR P0 START, NOT IMPLEMENTED.

**2026-10-16 amendment:** ADR-018 supersedes ADR-016's region default. The active MVP region is `us-east-1`.

## Purpose
CIC is an AI-assisted incident operations platform: detect real AWS deployment failures → evidence capture → grounded Bedrock investigation → human approval → constrained ECS rollback → verification → auditable postmortem. Core AWS serverless is distinct from expensive, opt-in integration labs. Neither an architecture PDF nor these files mean the product has been deployed.

## Files and order

| File | Contents |
|---|---|
| 00_START_HERE.md | Exact decisions, read order, start-up directions |
| 01_SRS.md | Full product requirements and acceptance baseline |
| 02_SERVICE_ARCHITECTURE.md | 18 service boundaries + AWS routes and trust relationships |
| 03_DATABASE_DESIGN.md | DynamoDB 3-table model, indexes, audit/outbox and S3 |
| 04_PHASE_BACKLOG.md | 72 stories, phase exits and dependencies |
| 05_BACKLOG_IMPORT.csv | Import-ready backlog with IDs, owners to assign in tracker |
| 06_ADR_DECISIONS.md | Non-negotiable architecture choices and exceptions |
| 07_RELEASE_READINESS.md | Gates and safe AWS apply checklist |
| 08_REQUIREMENT_TRACEABILITY.md | FR/NFR → stories and test cases |
| 09_IAM_ACCESS_MATRIX.md | Roles, required AWS actions and security boundaries |
| 10_API_OPENAPI.yaml | Machine-validatable OpenAPI 3.0 contract |
| 11_EVENT_SCHEMAS/ | Versioned JSON Schemas and sample events |
| 12_UAT_TEST_CASES.md | Executable acceptance plans and adverse scenarios |
| 13_COST_BUDGET.md | Manual budgets, default OFF labs and cost inventory |
| 14_OPERATIONS_RUNBOOKS.md | Deployment, incident, backup/restore, cleanup and recovery |
| 15_INTEGRATION_MATRIX.md | How every mandatory technology is actually used |
| 16_SECURITY_THREAT_MODEL.md | Trust boundaries, auth models, sensitive data, hazards |
| 17_TERRAFORM_TOPOLOGY.md | Exact state/module/dependency conventions and tfvars |
| 18_TEST_STRATEGY.md | Tests, datasets, exit evidence and CI quality gates |
| 19_AUDIT_RESOLUTION.md | Status/evidence for all original 23 audit findings |
| 20_CODEX_IMPLEMENTATION_PROMPT.md | Unambiguous agent prompt; starts P0, not blind full deploy |
| 21_EVENT_TOPOLOGY.md | Network and deterministic 5xx test harness |
| MANIFEST_SHA256.txt | Checksums of package files for integrity checks |

## Final hard decisions

- AWS is the cloud deployment target; default region `us-east-1` for MVP subject to checking every required service/model in actual account. Frontend Next.js+TypeScript static export on S3/CloudFront, backend Python/FastAPI Lambda; Cognito, DynamoDB and S3 as primary. Local development runs on the developer's machine and does not require AWS credentials.
- GitHub Actions primary CI/CD via AWS OIDC, deployment events published to EventBridge custom **Classic** bus in P1. EKS, OpenShift/ROSA, Nomad, Jenkins, Jenkins X, GitLab CI/CD, Bitbucket, GitLab SCM, Prometheus/Grafana/ELK, Packer/Ansible/RHEL as real opt-in AWS-hosted integration labs P5..P7.
- P1 ECS demo is a public-subnet Fargate **task** with outbound internet/public IPv4, no inbound SG, no NAT, no ALB. In-task loopback HTTP load tester + structured JSON access logs → CloudWatch Logs metric filter 5xx → alarm → default EventBridge bus → custom bus → SQS in P2.
- Bedrock AI is read-only advisory. Only initial action is `ecs.rollback_task_definition`, approved by separate human with scoped IAM, conditional workflow state, best-effort ECS drift guard and verification.
- Audit DynamoDB is application-enforced append-only, not immutable. Conditional writes + outbox + retries; S3 Object Lock needs separate gate to claim WORM.
- All lab enable flags default `false`. No AWS resource is to be provisioned by reading this package.

## How to use

1. Create Git repository and commit the contents under `docs/`, plus `infra`, `services`, `apps`, `tests` as implementation progresses.
2. Import `05_BACKLOG_IMPORT.csv`; track progress by IDs. The file has 72 rows; **all are TODO initially**.
3. Follow `20_CODEX_IMPLEMENTATION_PROMPT.md` to implement **P0 only first**. CI plan/validate should not run cloud apply without approval.
4. P0 exit: code skeleton, schema tests, CI checks, security review, cost controls and Terraform plans ready.
5. P1 exit: deployed & verified actual AWS inventory/deployment recorder + synthetic-traffic alarm path; P2→P4 after prerequisite completion.
6. For first production-like or billable apply: record region, account alias, projected cost, permissions, exact resource list, plan artifact and explicit approval.

## Known external dependencies (not yet validated)

AWS account eligibility, IAM administrative permissions, Bedrock model access in selected region, ECS/EKS/ROSA quota/support, source SCM/provider credentials, billing settings and actual costs must be checked during delivery. A service unavailable in-region should block its story (or require documented approved ADR) rather than allowing silent architecture change.

## Reference docs

- https://nextjs.org/docs/app/guides/static-exports
- https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-events.html
- https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_PutItem.html
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html
- https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html
- https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
