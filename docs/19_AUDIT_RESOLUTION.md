# v1.0 Audit — Resolution Report v1.1

The original audit found **5 blockers, 8 high findings and 10 medium findings (23 total)**. This table records the **specification amendment**, not proof that any AWS code was written or security validation passed. `SPEC UPDATED / IMPLEMENTATION TODO` applies to every item until its backlog gate/test is executed.

| Finding | Resolution in v1.1 | Evidence document/story | Delivery status |
|---|---|---|---|
| B01 | P1 event bus and recorder before pipeline | 02_SERVICE_ARCHITECTURE.md,04_PHASE_BACKLOG.md,P1-09,P1-06 | SPEC UPDATED; IMPLEMENTATION TODO |
| B02 | Real ECS inventory/deployment collector and UI gate | P1-10,P1-07,17_TERRAFORM_TOPOLOGY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| B03 | Conditional PutItem app-only; IAM not WORM, Object Lock optional | 03_DATABASE_DESIGN.md,09_IAM_ACCESS_MATRIX.md | SPEC UPDATED; IMPLEMENTATION TODO |
| B04 | Audit outbox primitive P1-11 pre-dates approval; P4-07 coverage | P1-11,P4-03,P4-07 | SPEC UPDATED; IMPLEMENTATION TODO |
| B05 | Fixed public subnet task zero inbound plus localhost HTTP 5xx metric filter | 21_EVENT_TOPOLOGY.md,P1-12,P1-08 | SPEC UPDATED; IMPLEMENTATION TODO |
| H01 | Default AWS bus forwarding to Classic custom bus | 02_SERVICE_ARCHITECTURE.md,21_EVENT_TOPOLOGY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| H02 | Separate webhook ingress signature auth from JWT routes | 09_IAM_ACCESS_MATRIX.md,10_API_OPENAPI.yaml | SPEC UPDATED; IMPLEMENTATION TODO |
| H03 | occurred_at normalized; observed_at removed from normative contract | 01_SRS.md,11_EVENT_SCHEMAS/SignalEvent.schema.json | SPEC UPDATED; IMPLEMENTATION TODO |
| H04 | Unified verification statuses VERIFIED FAILED UNKNOWN | 01_SRS.md,10_API_OPENAPI.yaml,12_UAT_TEST_CASES.md | SPEC UPDATED; IMPLEMENTATION TODO |
| H05 | Resource hash uses tenant ID and UID | 03_DATABASE_DESIGN.md,08_REQUIREMENT_TRACEABILITY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| H06 | MVP scoped exact/status resource search, no fulltext | 01_SRS.md,03_DATABASE_DESIGN.md,10_API_OPENAPI.yaml | SPEC UPDATED; IMPLEMENTATION TODO |
| H07 | Best-effort ECS drift guard explicitly not atomic CAS | 01_SRS.md,02_SERVICE_ARCHITECTURE.md,14_OPERATIONS_RUNBOOKS.md | SPEC UPDATED; IMPLEMENTATION TODO |
| H08 | Machine-versioned OpenAPI+JSON Schemas | 10_API_OPENAPI.yaml,11_EVENT_SCHEMAS/ | SPEC UPDATED; IMPLEMENTATION TODO |
| M01 | FR/NFR-to-story/UAT matrix | 08_REQUIREMENT_TRACEABILITY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M02 | Default region, Bedrock gate, cost plan and flags | 06_ADR_DECISIONS.md,13_COST_BUDGET.md,17_TERRAFORM_TOPOLOGY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M03 | MFA mandatory and backend fail-closed | 01_SRS.md,09_IAM_ACCESS_MATRIX.md,12_UAT_TEST_CASES.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M04 | Real 5xx synthetic traffic in ECS task | 21_EVENT_TOPOLOGY.md,12_UAT_TEST_CASES.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M05 | Reopen lifecycle semantics and audit test | 01_SRS.md,12_UAT_TEST_CASES.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M06 | Retained evidence metadata EXPIRED and retention override | 03_DATABASE_DESIGN.md,12_UAT_TEST_CASES.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M07 | P6 security boundary before live adapters | P6-04,P6-03,P6-05 | SPEC UPDATED; IMPLEMENTATION TODO |
| M08 | Split per-provider SCM & CI signed connector tests | P7-07,P7-13,P7-14,P7-15,P7-16 | SPEC UPDATED; IMPLEMENTATION TODO |
| M09 | Budgets/estimated cost form, opt-in OFF; no hard cap claim | 13_COST_BUDGET.md,17_TERRAFORM_TOPOLOGY.md | SPEC UPDATED; IMPLEMENTATION TODO |
| M10 | Runbooks, IAM, Terraform contract, test and release checklist | 07_RELEASE_READINESS.md,09_IAM_ACCESS_MATRIX.md,14_OPERATIONS_RUNBOOKS.md | SPEC UPDATED; IMPLEMENTATION TODO |

## Non-goals of this correction

- Does not guarantee cloud pricing, Bedrock model availability, ROSA prerequisites or Jenkins X version compatibility.
- Does not make DynamoDB append-only cryptographically immutable; optional S3 Object Lock requires separate real configuration, retention policy and proof.
- Does not provide atomic compare-and-swap of external ECS `UpdateService` state. The remaining race must be accepted and mitigated with operational deployment freeze + monitoring.
- Does not make CloudWatch events exactly-once; dedup and outbox must be implemented/tested.
- Does not mean the 72 backlog stories are completed. Every story starts TODO.

## Review next

When code is implemented, run P0 contract checks and infrastructure plan before marking any design fixed item as VERIFIED. For security/financial guarantees, source current official AWS docs and account-specific quotes at implementation time.
