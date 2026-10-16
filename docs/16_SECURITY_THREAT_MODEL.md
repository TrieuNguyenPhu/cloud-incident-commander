# Security Threat Model v1.1

## Assets / trust boundaries

- User and browser: untrusted client; Cognito supplies signed JWT, API owns all authorization decisions.
- FastAPI management plane: privileged read/query access, cannot directly perform arbitrary cloud mutation.
- Deployment producer: GitHub OIDC, limited events:PutEvents to custom bus; CI variables/secrets not echoed.
- Signal/connector boundary: logs, CloudWatch event data and webhooks are **untrusted content**, even when delivered from a trusted AWS envelope. Signature authenticity does not equal payload authorization.
- Bedrock model: untrusted proposed hypotheses/actions, **no permission for side effects**; only deterministic policy enforces safety.
- Action executor: high-impact isolated Lambda/Step Functions permission boundary, explicit service/task-definition checks and bounded retry.
- Audit/evidence: sensitive metadata, private S3 and DynamoDB. Application audits not equivalent to cryptographic immutability.

## STRIDE-like threat table

| Threat | Control | Proof |
|---|---|---|
| Stolen/forged JWT | Cognito issuer/audience/expiry validated, deny resource-scope mismatch, rotate session/revoke | UAT-03,UAT-11 |
| Privilege escalation through role/group changes | Server authorization on each mutation, MFA gate + no self approval, audit actor | UAT-05,UAT-11 |
| Prompt injection in logs | Redact/sanitize evidence, treat log as data not instruction, validate citations/action schema, no Bedrock AWS writes | UAT-04,UAT-16 |
| Forged deployment/source webhook | Provider signature/HMAC on original bytes, replay timestamps/delivery IDs, allowlist connector/resource, least privilege | UAT-30,UAT-31 |
| Replay of events / approvals | Canonical event_id+tenant/source fingerprint, DDB conditional transactions, expiring approval, callback token single use | UAT-02,UAT-07,UAT-19 |
| Unauthorized rollback | Requester≠Approver, resource/action allowlist, MFA, preflight ECS observed revision, scoped executor | UAT-05,UAT-06,UAT-16 |
| ECS external race | CIC lock, immediate re-read, deployment freeze SOP and post-action observe actual state | UAT-06; note known residual risk |
| Exfiltration through logs/S3 URL | Evidence redact, size/time bounds, 60s signed URL after RBAC, no URL logging, private buckets | UAT-09,UAT-15 |
| Audit overwrites | Conditional PutItem code, compare replay digest, outbox reconciliation, IAM denies Update/Delete; optional S3 Object Lock | UAT-17 |
| Unexpected cloud bills | Lab flag off, explicit apply approval, expiring lab, budget/anomaly alerts, teardown validation | UAT-10,UAT-18 |
| Service outage/poison event | Retry with exponential backoff, SQS DLQ alarm/redrive, synthetic chaos harness | UAT-19 |

## Security policy invariants

1. No `sudo aws ...` commands issued by model response; no generic remote shell/SSM action exposed.
2. No IAM wildcards for executor. For read-only `List*` actions without resource scope, use condition/role isolation and document the exception.
3. Credential secrets never committed and never sent to Bedrock; Terraform backend state restricted/encrypted.
4. API requests must include trace IDs, version checks for stateful writes and resource-level tenant checks.
5. Webhook verification is done before JSON parsing and event canonicalization; no unauthenticated generic `PutEvents` proxy.
6. Threat model re-review required before ROSA/EKS/third-party CI integration, cross-account or production release.
