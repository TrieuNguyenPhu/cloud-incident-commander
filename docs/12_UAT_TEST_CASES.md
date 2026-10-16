# User Acceptance Test Plan v1.1

**Status: All tests NOT EXECUTED.** Test IDs specify future reproducible AWS experiments, not an assertion about existing infrastructure. Never run unsafe tests against production. Use bounded demo workload and budget-approved lab.

For each case store: `{test_id, commit_sha, executed_at_utc, tester, environment, terraform_state, input_fixture, logs_link, incident_id, action_id, expected, observed, PASS/FAIL/BLOCKED, rollback_result, cost_estimate}`. Hide account IDs, tokens, secrets and signed URLs in shared artifacts.

| Test | Phase | Scenario | Procedure | Pass/expected result |
|---|---|---|---|---|
| UAT-01 | P2 | 5xx to incident | Deploy faulty ECS revision; internal loopback client sends real HTTP requests | HTTP 500 access logs → metric filter → CloudWatch ALARM → default EventBridge → custom bus → SQS → incident linked to resource+SHA within target; timestamps recorded |
| UAT-02 | P2 | Idempotent event | Re-deliver same event_id 5 times and concurrently | Exactly 1 canonical incident and no duplicate timeline entry for same event ID; audit/outbox consistent |
| UAT-03 | P1 | JWT + RBAC | GET protected API without JWT then as Viewer call action/approval | 401 unauthenticated, 403 unauthorized; no mutation |
| UAT-04 | P3 | Grounded RCA | Send AI evidence set with missing entries and malicious log instructions | INCONCLUSIVE or safe RCA referencing existing evidence IDs only, no AWS write calls |
| UAT-05 | P4 | Separate approver | Operator requests rollback; same actor approves; different MFA-enabled Approver approves | Self approval rejected, qualified different approver accepted once, audit references actor IDs |
| UAT-06 | P4 | External deployment drift | Change target ECS service revision between request and executor preflight | PRECONDITION_FAILED, executor does not invoke UpdateService after observed change |
| UAT-07 | P4 | Duplicate callback/action | Replay decision and Step Functions callback, concurrent approval requests | Single conditional decision and single executor action; conflict/expired token safely rejected |
| UAT-08 | P4 | Verification states | Restore healthy revision then test persistent ALARM and missing metrics | VERIFIED only after stable 5m; FAILED if alarm stays ALARM; UNKNOWN if telemetry unavailable |
| UAT-09 | P4 | Postmortem and audit | Close incident after remediation and export report | Report includes exact timeline/evidence, audit events present and no secrets, editable version |
| UAT-10 | P4 | Scoped teardown | Review and destroy ephemeral ECS demo/lab state | Only lab resources removed, core state unchanged; residual billing inventory checked |
| UAT-11 | P4 | MFA/revoked role | Try approve without required assurance or after role removed | Denied before Step Functions callback; no token leaked; failed attempts auditable |
| UAT-12 | P1 | Real inventory and recorder | Deploy ECS revision using GitHub Actions OIDC then invoke inventory collector | Real ECS ARN, digest, SHA, task revision and pipeline run persisted and accessible in UI |
| UAT-13 | P2 | Pagination/filter | Create 100+ incidents across status/severity; page and filter | Opaque cursor, no Scan, stable unique results; exact resource and incident lookup |
| UAT-14 | P2 | Lifecycle/reopen | Attempt invalid NEW→CLOSED; complete legitimate close and reopen | Invalid transition 409, reasons/actor recorded, postmortem version preserved, no old approval reused |
| UAT-15 | P2 | Evidence retention/privacy | Upload evidence then simulate expired object and unauthorized GET | Metadata shows EXPIRED and digest, no broken links, presigned request unauthorized 403 |
| UAT-16 | P3 | Action allowlist | Model suggests execute arbitrary shell/EC2 delete/role escalation | Schema+policy validator refuses; only existing historical ECS rollback revision is eligible |
| UAT-17 | P4 | Audit overwrite/outbox retry | Retry same audit ID with differing digest and simulate writer outage | Conditional overwrite fails, divergent replay alarm, core outbox stays pending until delivered |
| UAT-18 | P4 | Cost default-off | Plan terraform with unconfigured lab flags and missing approval | No EKS/ROSA/Jenkins/ELK created; budget and expiry checks block lab apply |
| UAT-19 | P4 | DLQ and poison message | Enqueue invalid schema + redrive after patch | Retry reaches DLQ, replay does not multiply incident/audit; errors visible |
| UAT-20 | P2 | Out of order event | Send late deploy/alarm and identical fingerprint across tenants | Correlation uses source/ingest times consciously; tenant-specific resource hashes never collide |
| UAT-21 | P5 | Notifications | Change incident state with SNS/email subscription | Scoped notification, throttled, no sensitive token or presigned S3 URL |
| UAT-22 | P5 | Prometheus Grafana | Start lab metrics source and inspect alert-linked dashboard | Actual scraped metric and panel for same resource/correlation ID |
| UAT-23 | P5 | ELK logs | Send actual workload log via shipper pipeline | Log query by correlation ID in Kibana; private access and retention verified |
| UAT-24 | P5 | Security finding | Generate allowed GuardDuty test finding or fixture with genuine adapter | Canonical security signal, no autonomous remediation, source evidence retained |
| UAT-25 | P5 | Analytics | Export daily partition and compare counts/MTTR computation | Athena results reconcile with source, denominators and freshness documented |
| UAT-26 | P6 | EKS incident | Trigger real EKS CrashLoopBackOff/rollout failure with connector RBAC | Signal → incident with pod namespace and resource mapping, teardown proof |
| UAT-27 | P6 | Jenkins X | Run real supported Jenkins X GitOps pipeline and faulty release | Release SHA/event linked to incident; costs and lifecycle recorded |
| UAT-28 | P7 | ROSA/OpenShift | Provision approved ROSA/OpenShift lab and run a failing deployment | Verified cluster, real event/metric/log, adapter incident, teardown evidence |
| UAT-29 | P7 | Nomad | Schedule and fail Nomad allocation on AWS EC2 RHEL lab | Real job/allocation events mapped and incident generated, cleanup evidence |
| UAT-30 | P7 | CI provider connectors | Run Jenkins & GitLab CI real build/deploy/failure and spoof bad signatures | Accepted valid signed events, 401 invalid signatures, dedup, SHA/run URL matches source |
| UAT-31 | P7 | SCM connectors | Provide GitHub/GitLab/Bitbucket known commits/PR/MRs and replay delivery | Validated provider auth and correct commit mapping; replay safely ignored |
| UAT-32 | P7 | RHEL Packer Ansible | Build hardened RHEL AMI via Packer; configure EC2 with Ansible | Recorded AMI digest/version, idempotent config, vulnerability evidence and destroy |

## Detailed mandatory MVP demonstration steps

1. Deploy known-good `cic-demo:v1` via protected GitHub Actions deployment; verify ECS currently runs the task-definition ARN, recorder has SHA/digest/run URL and inventory returns it.
2. Enable synthetic traffic (client is within same ECS task), confirm baseline 2xx log count and `HTTP5xxCount=0` metric filter. Save CloudWatch log stream and alarm name.
3. Deploy `cic-demo:bad` revision from GitHub Actions. Confirm HTTP generator receives actual 500 from `localhost`; observe JSON `status_code=500`, metric filter increment and CloudWatch Alarm transition.
4. Capture timestamp of EventBridge custom bus message receipt; ensure SQS message delivers canonical signal; incident and evidence are created with correct resource/commit SHA within target NFR time window.
5. Trigger Bedrock investigation only with bounded/redacted evidence; inspect evidence IDs and optional competing hypotheses. Test injected untrusted log cannot change instructions.
6. Operator requests action on exact service and known previous task-definition ARN, sees pending approval. Same operator must fail; qualified other MFA-enabled approver makes decision.
7. Step Functions preflight checks exact approved resource, present task definition and lock, then `UpdateService` to approved existing revision. Observe logs, CloudTrail event and action state.
8. Verifier waits until rollout and alarm state are stable 5m (timeout bounded). The result is VERIFIED or explicit FAILED/UNKNOWN, never inferred success from API request alone.
9. Close incident and generate versioned postmortem with audit evidence, then inspect outbox audit reconciliation and prove cleanup does not touch core.

## Dangerous/negative test boundaries

Use synthetic demo app only, never real user data. UAT-06 intentionally changes ECS task revision in demo environment; do not automate on another service. For token/MFA tests, create dedicated test identities. For UAT-17 audit corruption, test alternate digest in isolated table and observe fail-closed behavior; do not write directly to production audit storage.
