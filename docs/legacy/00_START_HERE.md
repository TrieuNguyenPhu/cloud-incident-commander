# Cloud Incident Commander — Baseline Specification Package v1.0

**Chốt ngày 2026-10-15.** Các tài liệu này dùng để implement trực tiếp trên AWS và quản lý issues trong GitHub Projects/Codex/Superpowers.

## Tài liệu

| File | Mục đích |
|---|---|
| `01_SRS.md` | Product goals, scope, actors, FR-001..FR-028, NFR, business rules, UAT |
| `02_SERVICE_ARCHITECTURE.md` | ADR, Mermaid architecture & sequence, 18 service boundaries, AWS deployment topology, event/API contracts |
| `03_DATABASE_DESIGN.md` | DynamoDB physical tables, GSI, sample items, access patterns, S3 lifecycle, analytics |
| `04_PHASE_BACKLOG.md` | P0-P7 roadmap, per-story dependencies, acceptance criteria, release/quality gates |
| `05_BACKLOG_IMPORT.csv` | 64 issues with title, phase, dependency, points and acceptance criteria for import to issue tracker |

## Final hard constraints

1. AWS is the **only** deployment cloud. Frontend is **Next.js + TypeScript**, static S3/CloudFront. Backend FastAPI/Lambda; DynamoDB primary; S3 evidence.
2. Main CI/CD is **GitHub Actions with AWS OIDC**. Other systems (Jenkins, GitLab CI, Jenkins X) are tested as integration labs, not the core release path.
3. All 6-image technologies are truly integrated across P0..P7, but expensive platforms are provisioned *on demand* with budget approval; never pretend mocks satisfy completion.
4. No AI autonomous AWS write actions. Approved ECS rollback is the only initial mutation runbook, with separate approver, preflight, narrow IAM, idempotency and audit.
5. P0..P4 = shippable MVP. P5..P7 = hardened observability/data/security and broad platform integrations.
6. No use of requirements/artifacts from unrelated React exercise projects.

## Order to implement

1. Create GitHub repo `cloud-incident-commander` with this `docs/` package.
2. Import CSV into GitHub Project; P0 stories first. Use story ID in branch name and PR (`feat/P1-03-dynamodb-core`).
3. Start with `P0-02` repo skeleton, `P0-03` contracts, `P0-05` budget/terraform, `P0-06` CI checks. Do not provision ROSA/EKS in MVP.
4. Build in phase order P1→P4 and demonstrate UC-001. Every story must prove its acceptance criteria; every phase must pass exit gate.
5. After P4 passes the 10 MVP UATs, tag `v1.0.0-mvp`; only then start P5..P7.

## Cost and safety caveat

The EKS control-plane hourly fee, EC2/EBS/ELB/NAT, ELK resources and ROSA service/infrastructure/support fees are **additional**, and eligibility for AWS promotional credits must be checked before lab creation. No guarantee the user's promotional credit covers any specific service. AWS Budgets is alerting, not automatic spending cut-off; add explicit enable flags and manually verify teardown.

## Canonical implementation kickoff for coding agent

> Implement the Cloud Incident Commander baseline defined by `docs/00_START_HERE.md`, `docs/01_SRS.md`, `docs/02_SERVICE_ARCHITECTURE.md`, `docs/03_DATABASE_DESIGN.md` and `docs/04_PHASE_BACKLOG.md`. Treat these as binding decisions. Begin with P0 stories in dependency order, no architectural option exploration and no repeated clarifying questions. Do not skip IAM/security, tests, budget gates or UAT. Provide code changes, tests, exact deploy commands and per-issue acceptance evidence. Do not provision AWS resources automatically without an explicitly approved apply step; do not create EKS/ROSA/Nomad/Jenkins/ELK resources until their scheduled phases and budget approval.

## Trusted external docs

- Next.js static exports: https://nextjs.org/docs/app/guides/static-exports
- AWS/GitHub OIDC: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- AWS Step Functions human approval: https://docs.aws.amazon.com/step-functions/latest/dg/tutorial-human-approval.html
- DynamoDB consistency: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html
- AWS EKS pricing: https://aws.amazon.com/eks/pricing/
- ROSA prerequisites/cost: https://docs.aws.amazon.com/rosa/latest/userguide/set-up.html
