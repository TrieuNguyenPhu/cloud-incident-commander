# P0 setup evidence — 2026-10-16

**Local setup implemented and verified. External AWS release gates remain open.**
No AWS apply/destroy, deployment or issue-tracker import was run. The initial
specification was moved from `doc/` to `docs/`; ADR-018 then changed the active
region to `us-east-1` and the manifest was refreshed. The historical `legacy/`
documents and ADR-016 remain available for audit. GitHub CI and branch settings
must be checked from the published repository.

## Scope and story evidence

| Story | Files / work delivered | Verification | Remaining acceptance |
| --- | --- | --- | --- |
| P0-01 | v1.1 docs, ADR-018 region amendment, 23 audit dispositions and traceability; baseline/dependency tests | `tests/contract/test_spec_baseline.py`: current manifest hashes, 72 unique stories, acyclic dependency graph, 28 FR/14 NFR, 23 findings | Obtain independent review; CSV is validated, not imported into a tracker |
| P0-02 | npm workspaces, uv workspace/locks, Next.js static/Tailwind, FastAPI/Mangum health, sample envs, root README | `npm ci`, `uv sync --frozen --all-packages`, `npm run check`; actual local HTTP smoke | No local setup blocker |
| P0-03 | Pydantic models from all 5 event schemas and OpenAPI; TypeScript API declarations; deterministic generator | `npm run contracts:check`, TypeScript/mypy, `tests/contract/test_contracts.py`, health response contract | Business endpoints are intentionally owned by P1..P7, not exposed as unauthenticated stubs |
| P0-04 | Existing role matrix/threat model reviewed against scaffold; OIDC trust template and workflow restrictions tested | `tests/security/test_setup_security.py`; [IAM matrix](09_IAM_ACCESS_MATRIX.md), [threat model](16_SECURITY_THREAT_MODEL.md) | Account-specific IAM review/simulation and Cognito MFA/RBAC verification require P1/P4 work |
| P0-05 | State bootstrap module, encrypted/versioned private S3, budget configuration, owner/tag/TTL and region guards, 6 distinct backend examples and teardown instructions | `node scripts/check-infra.mjs`: 9 roots with mocked plan tests; Checkov | Real account/role/recipient, reviewed AWS plan/cost approval, bootstrap provisioning and received budget emails remain unverified |
| P0-06 | Windows/Linux CI, format/lint/typecheck/test/build, dependency/secret/IaC scan, immutable action refs, account-checked OIDC plan-only workflow, CODEOWNERS | Local quality/scans and workflow tests; [GitHub setup](../infra/README.md#github-oidc-and-branch-protection) | Verify published CI and branch protection; independent reviewer and protected `aws-plan` environment remain pending |

The original backlog and release checklists remain unchanged; no story or audit
finding was silently marked deployed/verified. Real AWS work requires the
account/role/recipient plus a reviewed plan and explicit billable-resource approval.

## Verification performed

| Command / check | Result |
| --- | --- |
| `npm ci` | Clean installation from lockfile succeeded |
| `uv sync --frozen --all-packages` | Workspace synchronized without changing resolution |
| `npm run check` | Prettier, ESLint, TypeScript, Ruff, mypy, contract drift, pytest and static build passed |
| `uv run pytest` | 31 passed; 100% line coverage of the 11-statement P0 health API only |
| `node scripts/check-infra.mjs` | fmt, isolated backend/region assertions, init/validate and mocked plan runs passed across 9 roots |
| `npm audit --audit-level=high` | 0 reported vulnerabilities |
| `uv run pip-audit --strict --no-deps --disable-pip -r artifacts/python-requirements.txt` | No known vulnerabilities in exported locked Python dependencies |
| `uvx --from checkov==3.3.29 checkov --directory infra --framework terraform --compact --quiet` | 14 checks passed, 0 failed, 4 explicit skips documented below |
| Gitleaks 8.30.1 `dir . --redact --no-banner` | No leaks in working tree; no Git history exists yet |
| Trivy 0.76.0 filesystem vulnerability scan including dev dependencies | 0 HIGH/CRITICAL findings in `package-lock.json` and `uv.lock` |
| Real local HTTP smoke | Uvicorn `/healthz` returned HTTP 200 with `{"status":"ok","version":"0.1.0"}`; built static homepage returned HTTP 200 with expected title |

Smoke servers used temporary loopback ports 18000/13000, were stopped afterwards,
and wrote local logs to ignored `artifacts/api-smoke.log` and `artifacts/web-smoke.log`.
The normal development commands use 8000/3000. Linux CI, live AWS behavior,
user authentication, domain coverage and UAT have not been executed.

Reproduce the additional Python audit in PowerShell:

```powershell
New-Item -ItemType Directory -Force artifacts | Out-Null
uv export --frozen --all-packages --no-emit-workspace --format requirements-txt --output-file artifacts/python-requirements.txt
uv run pip-audit --strict --no-deps --disable-pip -r artifacts/python-requirements.txt
```

Local verified scanner binaries are cached under ignored `.tools/`. Their archives
were checked against SHA-256 digests published by the official GitHub releases.
CI downloads pinned Linux archives and verifies the corresponding digests.

```powershell
.tools/gitleaks/gitleaks.exe dir . --redact --no-banner
.tools/trivy/trivy.exe fs --db-repository ghcr.io/aquasecurity/trivy-db:2 --scanners vuln --include-dev-deps --severity HIGH,CRITICAL --exit-code 1 --skip-dirs node_modules --skip-dirs .venv --skip-dirs .tools --skip-dirs artifacts --skip-dirs apps/web/.next --skip-dirs apps/web/out --skip-dirs apps/web/node_modules .
```

The default Trivy database mirror failed DNS locally. The scan succeeded using
Trivy's official GHCR database, which is also configured in CI. Security findings
are time-sensitive; rerun the scans before future releases.

## Security and cost review

- Only health is implemented. `/v1/*` and `/webhooks/*` return 404; no AWS SDK or
  AI execution path exists in the application. Authoritative endpoint security
  declarations are checked without pretending JWT/RBAC is implemented.
- Viewer/Operator/Approver/Admin permissions stay as defined in the IAM matrix.
  Self-approval, missing MFA, cross-tenant reads, webhook replay, prompt injection,
  fabricated evidence and external ECS drift remain explicit negative scenarios
  for their owning phases. Generated models alone do not enforce those policies.
- OIDC template allows only the exact repository and `aws-plan` environment with
  the AWS STS audience. Branch restriction requires real GitHub environment
  settings as described in the infrastructure README; local YAML alone cannot
  prove them. The workflow also checks the expected account and `us-east-1` before
  planning. No static AWS key is configured in CI.
- State uses SSE-S3, versioning, public-access blocks, TLS-only access, explicit
  role restrictions and S3 locking. Bootstrap bucket destruction is protected.
  No application-data tables or evidence buckets were created in P0.
- Four Checkov skips are scoped to the state bucket: logging destination pending
  pre-apply review, single-region dev without replication, approved baseline
  SSE-S3 instead of KMS, and no event consumer. See [exceptions](../infra/README.md#security-scan-exceptions).
- All provisioning flags default off. Enabling an unimplemented environment
  fails validation. Enabled future labs require an owner and RFC3339 expiry
  within the approved window, at most four hours in this baseline.
- USD 25/month is an account-wide budget notification threshold at 50/80/100%,
  **not a cost estimate or spending cap**. Budget emails are not active until
  bootstrap is approved, provisioned and notifications are verified. Tags/TTL
  are not an automatic shutdown. No AWS resources were created by this setup.
- Preserve the known design limits: DynamoDB audit is not WORM; the future ECS
  drift check is not atomic against external deployers; model output grants no
  AWS authority. No design limit is represented as a passed integration test.

## Tooling choices and known warnings

Dependencies and CI actions were pinned using package registries/official release
metadata. Next.js uses static export and trailing slashes, matching the
[official static export configuration](https://nextjs.org/docs/app/guides/static-exports).
Python/TypeScript models are generated from the supplied contracts; the generator
never fetches remote schema references. See [Pydantic code generation](https://docs.pydantic.dev/latest/integrations/datamodel_code_generator/).

The Next.js ESLint bundle pulled an unpatched `braces` development dependency
([GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm)). The scaffold
uses the existing TypeScript, React, Hooks and JSX accessibility rule packages
directly, removing that dependency rather than suppressing the advisory. ESLint
9.39.5 is pinned for those plugins' compatibility; npm reports its deprecation.
Upgrade together with compatible React/accessibility plugins. TypeScript 5.9.3
is also deliberately pinned; dependencies are not automatically major-upgraded.

Test execution reports two upstream deprecation warnings from Mangum's event-loop
initialization and Starlette's HTTPX test client. They do not fail the current
Python 3.12 health tests; the pinned versions and warnings remain visible.
