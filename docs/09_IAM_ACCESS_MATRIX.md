# IAM / Authorization Matrix v1.1

**Default deny.** The table lists **intended** capabilities; actual IAM policies are generated and reviewed from Terraform. Resource scoping must be validated per AWS action documentation and tested with Access Analyzer/simulation where feasible.

| Identity / role | Allowed (narrow scope) | Explicit deny / security condition | Phase |
|---|---|---|---|
| Browser User JWT | HTTPS API after authentication | No AWS credentials in UI; role/tenant/resource server-side | P1 |
| GitHubOIDCDeploy | ECR push (target repo), ECS Describe/UpdateService (demo only), iam:PassRole of approved task/execution roles, events:PutEvents on `cic-events` ARN | OIDC audience/subject restricted to protected repo, branch and environment; no account-wide `*` | P1 |
| ApiLambdaRole | Read/query core, conditional domain writes, S3 short GET signing, Step Functions execution for allowlisted state machine, Bedrock request by delegated investigator | Cannot call ECS UpdateService; no IAM admin | P1-P4 |
| InventoryCollector | `ecs:ListClusters`, `ecs:ListServices`, `ecs:DescribeServices`, `ecs:DescribeTaskDefinition`, scoped DynamoDB writes | List* may need `Resource:*` where service doesn't support resource scope; isolate and filter known clusters | P1 |
| DeploymentRecorder | Read permitted event payload, core deployment Put/Update and outbox | No ECS UpdateService | P1 |
| AuditWriter | Get/read core outbox + `dynamodb:PutItem` only on audit table, write approved S3 export prefix | No Update/Delete audit; **application must use conditional PutItem** | P1 |
| IngestWorker | SQS Receive/Delete/Visibility, core conditional writes + outbox, limited EventBridge | No ECS mutation; SQS source ARN restriction | P2 |
| EvidenceWorker | CloudWatch Logs Filter/Get, GetMetricData, ECS Describe, S3 Put evidence prefix, core evidence metadata writes | bounded resource/window/byte/timeout | P2 |
| BedrockInvestigator | `bedrock:InvokeModel` on configured model resource, read sanitized evidence, core analysis writes | No ECS/EC2/IAM mutation, model access configurable | P3 |
| ApprovalManager | Strong consistent read/write approval states + encrypted callback token secret + `states:SendTaskSuccess/Failure` | TTL/MFA/separation checks, never disclose token | P4 |
| StepFunctionsService | Invoke only preflight/executor/verifier functions and callback/wait | No direct dynamic AWS CLI arbitrary commands | P4 |
| RemediationExecutor | `ecs:DescribeServices`, `ecs:DescribeTaskDefinition`, `ecs:UpdateService` ONLY approved demo ECS service resources; core lock read/write | Never permit `ecs:RunTask` arbitrary role/image, no EKS mutation | P4 |
| VerificationWorker | ECS Describe + CloudWatch metric/alarm read | No ECS/DB destructive action | P4 |
| AuditReadAdmin | Time-bounded audit Query via API | No raw S3 audit-object write/delete | P4 |
| WebhookIngress | Secret Manager read by connector ID, EventBridge PutEvents custom bus | No Cognito JWT requirement; provider signature + replay + rate/size checks | P7 |
| LabTerraformRole | Explicit opt-in lab module operations only, conditions and tags | Separate core state; cannot destroy core resources | P6-P7 |

## Cognito role matrix

| Operation | Viewer | Operator | Approver | Admin |
|---|---:|---:|---:|---:|
| Read incident/evidence in scope | yes | yes | yes | yes |
| Ack/transition in scope | no | yes | yes | yes |
| Request AI investigation | no | yes | yes | yes |
| Propose ECS remediation | no | yes | yes | yes |
| Approve others' action in scope, MFA | no | no | yes | yes |
| Approve own action | no | no | **never** | **never** |
| Configure connectors/policies | no | no | no | yes |
| Audit reporting | no | no | no | yes |

## Authentication model

- Browser: Cognito OAuth Authorization Code + PKCE; API Gateway JWT authorizer with exact issuer/audience; API verifies `tenant_id`, RBAC groups/claims, resource allowlist, approval actor separation and token expiry.
- Approver/Admin: MFA must be enforced through Cognito policy/flow, not UI toggle alone. Verify token auth assurance claims/session state using supported Cognito mechanism; if assurance cannot be reliably verified, deny the high-risk action.
- GitHub Actions: scoped AWS OIDC trust `aud=sts.amazonaws.com`, precise `sub` claim; AWS credentials ephemeral.
- Provider webhooks: separate route with connector secret/signature; no JWT; request body bytes verified before parsing; timestamp or delivery ID window; dedup/idempotency; 64 KiB default max payload unless provider documented need.
- Secrets: Secrets Manager/SSM SecureString, secret names per environment, rotation and TTL. No secrets in Terraform state when avoidable; state still sensitive and encrypted with restrictive backend access.
- Preflight: IAM and application policy **both** required, with explicit service allowlist and previously known rollback revision.
