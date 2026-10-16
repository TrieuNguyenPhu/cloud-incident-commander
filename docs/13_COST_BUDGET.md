# Cost / Quota / Run-Cost Controls — v1.1

## Important limitation

This is **not a current AWS price quote**. Account region, credit eligibility, actual rates, use and residual storage/IPv4 fees must be checked in AWS Pricing Calculator / Cost Explorer immediately before provisioning. AWS Budgets alerts **do not enforce a hard spend ceiling**. Lab quotas and OpenShift ROSA prerequisites require explicit validation.

The active MVP region is `us-east-1` (ADR-018). Its price advantage for this
specific workload has not been measured. Compare the same resource inventory in
`us-east-1` and `ap-southeast-1` in AWS Pricing Calculator before the first
billable apply; record the selected-region quote and timestamp in the approval
form below. Existing resources in a different region need a separate migration
plan and cost review.

## Planning thresholds — editable after user approval

| Budget level | Initial planning threshold | Action |
|---|---:|---|
| Core dev monthly alert | USD 25 / month | AWS Budget alerts at 50%, 80%, 100%; investigate trending cost |
| Core daily anomaly watch | USD 5 / day | Daily human review of unexpected accrual |
| EKS lab budget | **NO DEFAULT APPROVAL** | Manual AWS estimate and written upper cost per run before enable; lab TTL 4h |
| ROSA/OpenShift | **NO DEFAULT APPROVAL** | Support/ROSA fees, worker costs, cluster minimum duration and cleanup billing terms independently quoted; may be prohibitive |
| ELK/Jenkins/Nomad EC2 lab | **NO DEFAULT APPROVAL** | Instance/EBS/IP/logs quote; lab TTL 4h and teardown |
| Bedrock AI | Planning max 20 requests/day during P3 | Model-specific pricing/quotas approval; input/output token caps; throttle and safe fallback |

USD 25/$5 are **notification planning values**, not commitments that Core will cost less or automatically stop. If already above threshold, the developer must request budget decision, reduce runtime or stop the lab.

## High-risk charge sources

| Component | Expense drivers | Default |
|---|---|---|
| ECS Fargate demo | vCPU/memory running time, public IPv4, outbound data | OFF when not testing |
| API Gateway/Lambda | requests/duration, CloudWatch Logs | On-demand |
| CloudFront/S3 | requests, transfers, object retention; log copies | Private origin, lifecycle |
| Cognito | active users and feature tier | Verify tier/pricing |
| DynamoDB | on-demand read/write, storage, backup PITR | Small bounded volume |
| CloudWatch | log ingest, metric filters, custom metrics/alarms, Logs Insights | 14d log retention and query window caps |
| EventBridge/SQS | events/requests and event duplication | Filters, DLQ alarms |
| Public IPv4 | per address-hour even for lab | Count + teardown verify |
| Secrets Manager | secret-month and API calls | Only required secrets |
| Bedrock | model tokens, inference routing / provisioned throughput | Pay-per-request only |
| EKS | per cluster-hour plus nodes, EBS, LB, IP, egress | Manual P6, destroy soon |
| ROSA/OpenShift | ROSA service/contract fees plus AWS compute/network/storage | Strict manual P7 gate |
| EC2/Jenkins/Nomad/ELK | instance-hour, EBS, snapshots, IP, egress | Manual P7 gate |
| GuardDuty/Athena/Glue | event volume, scanned bytes, catalog | Enable stage-specific |

## Approval form per lab run (record in issue, do not write secrets)

```
Issue ID:
AWS account alias/region:
Exact Terraform state:
Planned create/update/destroy resources:
Pricing source URL and checked UTC timestamp:
Cost estimate by component for max runtime:
Upper lab-run exposure estimate (including residual resources):
TTL expiry and manual cleanup owner:
Approval by role + timestamp:
Terraform plan checksum:
CloudWatch/Budget alerts validated:
Teardown commands and verification query:
```

## Teardown verification

Query AWS Cost Explorer for trailing charges after delay; inspect AWS console/CLI for ECS services/tasks, EC2, EBS volumes/snapshots, public IPv4, NAT/ALB, EKS/ROSA clusters, secrets, S3 data, CloudWatch groups, EventBridge rules and IAM trust. Deletion of Terraform objects does not guarantee immediate elimination of all incurred charges.

Pricing references: https://aws.amazon.com/pricing/ ; https://calculator.aws/ ; https://aws.amazon.com/eks/pricing/ ; https://aws.amazon.com/rosa/pricing/ ; https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
