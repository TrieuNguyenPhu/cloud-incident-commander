# Fixed Prompt for Codex/Superpowers — Implement CIC by Backlog, No Architecture Re-Selection

> You are the engineering lead implementing **Cloud Incident Commander**. Repository `/docs/` contains authoritative spec v1.1. **Do not ask me to choose architecture/stack again.** Read `00_START_HERE.md`, `01_SRS.md`, `02_SERVICE_ARCHITECTURE.md`, `03_DATABASE_DESIGN.md`, `04_PHASE_BACKLOG.md`, `05_BACKLOG_IMPORT.csv`, `06_ADR_DECISIONS.md`, `09_IAM_ACCESS_MATRIX.md`, `10_API_OPENAPI.yaml`, `11_EVENT_SCHEMAS/`, `17_TERRAFORM_TOPOLOGY.md`, `19_AUDIT_RESOLUTION.md`. Follow the exact contracts and dependency graph.
>
> **Current task: IMPLEMENT P0 ONLY (P0-01 through P0-06).** Work in story order compatible with dependencies; make real changes and tests in repo, not just an abstract plan. Bootstrap monorepo `apps/web` Next.js TypeScript static export, `services/api` FastAPI, `packages/contracts`, `/infra` modules/environment skeleton, `.github/workflows`, `/tests`, documentation and sample envs. Configure local dev, lint, typecheck, CI, OpenAPI/JSON-schema validation, threat model, Terraform isolated-state skeleton, tagging/budget plan and AWS OIDC trust placeholders. Include exact commands and proof for each AC. **Do not provision AWS infrastructure** or assume secrets/account credentials.

> **Region amendment:** ADR-018 supersedes ADR-016's default. Use `us-east-1` for this account; confirm current prices and service/model availability before any billable apply.
>
> Do not introduce PostgreSQL, Vercel, GCP, Cloud Run, React Vite SPA or extra orchestration choices. Main CI is GitHub Actions; AWS-only compute. Next.js export contains no server actions/routes. Bedrock is read-only; ECS rollback is the only initial executable runbook with human approval in P4. Maintain default-off lab flags and manual approval for all Terraform applies. Make each risk explicit: DynamoDB is NOT WORM, ECS drift check is not atomic, Budgets are NOT hard caps. Never label mock services as deployed integrations.
>
> Before coding a story, identify its exact ID, required files, tests and constraints. After coding, report modified files, tests run and result, security/cost risk, unmet ACs and next unblocked issue. When blocked by unavailable AWS credentials/entitlements, complete offline tasks and report one concrete blocker without inventing completion. Do not skip or re-order P0 security/budget checks. Never auto-run Terraform apply or destroy.

## Next phase prompt (only after P0 gate PASSES)

> Implement P1 story dependencies exactly from `04_PHASE_BACKLOG.md`, using the approved reviewed AWS plan. Build real ECS loopback HTTP 5xx test harness, CloudWatch logs metric filter alarm, Classic custom EventBridge bus, deployment recorder, inventory collector and audit outbox primitive. P1 success means real AWS evidence not a mocked dashboard. Stop before any AWS apply until the deployment plan, account/region, IAM security and expected costs are explicitly approved.
