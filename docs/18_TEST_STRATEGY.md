# Test Strategy & Implementation Readiness

## CI quality ladder

1. **Static checks**: ESLint/TypeScript strict, Ruff/Black/Pyright (or mypy), Trivy image, Checkov Terraform, secret scanner, locked dependencies, `terraform fmt/validate`.
2. **Unit:** domain lifecycle, fingerprint+tenant hashing, time normalization, permission policy, action version validators, safe AI output parser; critical logic target ≥80% line coverage (must verify report).
3. **Contract:** OpenAPI structure + request/response fixtures, JSON Schema 2020-12 validation, Pydantic model parity, version-aware errors; no silent response schema drift. Validate architecture JSON examples against their schemas, compare persisted/API Action and Approval enums, and require the P4 release gate to cover UAT-01..UAT-20 (ADR-017).
4. **Integration:** DynamoDB local/test AWS transactional errors, audit outbox/DLQ replay, EventBridge alarm envelope parsing, inventory read API, provider HMAC verification.
5. **End-to-end:** UAT-01..UAT-20 on isolated AWS ECS demo; P5..P7 require actual opt-in resources, no fake pass.
6. **Security:** zero inbound ECS SG, OIDC trust tests, deny IAM drift, MFA/SoD tests, replay/timing/oversized payload cases, path traversal/presigned S3 authorization.
7. **Load/resilience:** p95 API target under 800ms excluding AI, event-to-incident p95 under 120 seconds from custom bus receipt, poison event redrive and concurrent event duplicates. Report sample size/environment/test tool; targets not achieved until measured.

## Scenario fixtures

- `11_EVENT_SCHEMAS/fixtures/signal_event_valid.json`: normalized CloudWatch alarm.
- `11_EVENT_SCHEMAS/fixtures/deployment_event_valid.json`: GitHub CI `sha256` digested release.
- `11_EVENT_SCHEMAS/fixtures/cloudwatch_alarm_valid.json`: AWS default-bus envelope.
- `11_EVENT_SCHEMAS/fixtures/ai_analysis_report_valid.json`: report-level evidence/confidence and one optional rollback proposal; identical to the architecture example. Negative contract cases must reject object hypotheses, plural `recommended_actions` and unsupported action types; policy tests must reject cross-incident evidence and non-null actions for INCONCLUSIVE/FAILED.
- Generate negative cases: missing mandatory field, wrong version, duplicate ID across tenant, non-JSON webhook, bad HMAC, expired approval, self approval, drift, missing CloudWatch data, audit overwrite, S3 evidence expired.

## Evidence standards

An accepted issue is backed by CI job permalink, commit SHA, test identifiers/results, AWS event IDs and CloudWatch metric references, policy/resource hash diff and cost/teardown record. Never paste raw task token, secret, AWS account keys or identifiable logs into GitHub issue. Use sanitized screenshots or links with access control.

## Definition of external verification

- In P0, syntactic schema/CSV dependency verification can be done offline; this does **not** prove AWS integration.
- On P1/P4, require a real AWS test deployment in a test account with documented approvals.
- On P6/P7, version compatibility, quota, support subscription, actual provisioning and cross-tool data flow remain acceptance tests to execute, not design assertions.
