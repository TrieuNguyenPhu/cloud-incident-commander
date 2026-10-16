# Cloud Incident Commander — Operational Runbooks v1.1

All commands below are **templates**. Replace variables from approved Terraform outputs and role sessions. Never use root credentials, static AWS secret keys, `-auto-approve`, wildcard destroy, or execute remediation against production by copy/paste.

## RB-01: preflight release

1. `aws sts get-caller-identity` (verify account before any change); `aws configure get region` and `terraform workspace show` (if workspaces used).
2. Confirm Git SHA, Terraform target state, cost gate and allowed resource IDs.
3. `terraform fmt -check -recursive`; `terraform validate`; `terraform plan -out=reviewed.tfplan` within the EXACT target environment directory; collect plan digest and human review.
4. Run CI, provider lockfile check, Scan, and approval. Apply **exactly** approved reviewed plan via protected GitHub Actions job; store CloudTrail and deployment event IDs.
5. Smoke test API `/healthz` and authenticated `/v1/resources`. For ECS demo, check exact task definition and log filter metric.

## RB-02: incident triage (read-only)

1. Open incident by ID, confirm tenant/resource/status/severity, deployment link and evidence timestamps.
2. Review bounded CloudWatch logs/metrics and actual image digest. Distinguish symptom from evidence-grounded cause.
3. Execute AI investigation only on redacted bounded evidence, validate evidence IDs, and choose `INCONCLUSIVE` when data insufficient.
4. For action requests, require exact task revision, manual approver different from requester and explicit expiry.
5. If source/drift/telemetry not verifiable: **do not rollback**; mark PRECONDITION_FAILED/UNKNOWN; escalate.

## RB-03: ECS rollback action (MVP)

1. Backend checks action type allowlist, exact service/resource, approved historical task-definition ARN, actor and MFA/separation-of-duties.
2. Store expected-current and target revision plus incident/action/policy version, idempotency key; create Step Functions Standard execution.
3. Approver decides once before expiry; callback task token is server-only. Any rejection/expiry ends without mutation.
4. Executor takes conditional CIC resource lock, performs ECS DescribeServices / DescribeTaskDefinition, checks observed current revision and policy allowlist. A concurrent external update remains a known race and must be monitored.
5. Only then ECS UpdateService to approved task definition; subsequent status and result recorded in action/timeline/outbox.
6. Verifier polls stable rollout and CloudWatch alarm for 5 minutes; returns VERIFIED/FAILED/UNKNOWN. Never automatically retry risky UpdateService on unknown outcome without reconciling actual ECS state.

## RB-04: DLQ replay

1. Determine producer error, inspect schema/tenant/resource/signature; avoid replaying poison events without a fix.
2. Redact payload before analysis; preserve stable `event_id` and `correlation_id`.
3. Replay in batches with low concurrency and verify dedup count, no duplicate incidents, and outbox delivery.
4. Record replay actor, time, original event reference and post-replay status.

## RB-05: Audit delivery issue

1. Stop marking action complete if required outbox audit cannot reconcile; alert on pending outbox age.
2. Inspect consumer timeout/permission/schema failure; retry idempotently with `PutItem` conditional `attribute_not_exists(PK) AND attribute_not_exists(SK)`.
3. If conditional failure, strongly read existing audit event; compare content digest. Identical = valid replay; mismatch = security incident, no overwrite.
4. For durability retention, export with SHA256 manifests to S3; Object Lock only when separately approved and configured. Do not claim DDB is WORM.

## RB-06: restore/DR drill

1. Record baseline application objects and evidence manifests (counts + digests); verify PITR/backup availability and costs.
2. Restore DynamoDB into **new isolated table** (never overwrite production blindly). Reconcile incident/action/approval statuses and outbox delivery.
3. Verify S3 versioning/object recovery according to lifecycle; metadata whose evidence has expired must show EXPIRED.
4. Deploy IaC into isolated environment; use read-only smoke tests first. Measure RPO/RTO against target; report gaps, do not claim achieved target without measured results.

## RB-07: cleanup opt-in lab

1. Collect current approved environment path and `terraform state list`; verify **NO core state** appears.
2. Disable/terminate lab workloads before teardown, then create/inspect `terraform plan -destroy -out=reviewed-destroy.tfplan`.
3. Require human approval of exact destroy plan; apply reviewed destroy plan.
4. Query residual ECS/EC2/EBS/IP/EKS/ROSA/ELB/NAT/S3/secrets/log resources and tag inventory; confirm no unrelated resources affected.
5. Record final resource inventory and later Cost Explorer change; don't assume instantaneous billing stop.

## RB-08: secrets / compromised connector

Disable connector and bus rule, rotate provider secret, invalidate stored challenge nonce/replay window, investigate CloudTrail + application audit, test invalid signature rejection, and re-enable only after review.
