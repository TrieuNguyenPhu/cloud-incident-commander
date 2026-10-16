# Full Technology Integration Matrix v1.1

**Real integration:** A completed story has a running workload/tool (on AWS where deployable), an actual signal/deployment/log/metric entering CIC, retained evidence, and a cost/cleanup record. Mock data is allowed for unit tests but not for full-scope exit gate.

| Technology | Role and precise workload | AWS placement or external provider | Phase | Proof |
|---|---|---|---|---|
| Next.js + TypeScript | Console, Auth PKCE, incident workflow | S3+CloudFront | P1 | Authenticated dashboard and protected API |
| FastAPI Python | Backend API and domain validation | Lambda | P1 | OpenAPI and CI contract tests |
| AWS IAM/Cognito | Identity, OIDC, RBAC, MFA | AWS managed | P0–P4 | 401/403/MFA/least-privilege tests |
| Docker | All sample workloads and CI reproducibility | Build, ECR and ECS/EKS/EC2 | P1 | Pinned digest |
| ECS/Fargate | Bad deployment lab | AWS public subnet without ingress | P1 | Real 5xx → CloudWatch alarm |
| Git/GitHub | Primary source repository and pipeline linkage | GitHub SaaS SCM | P0+ | Git SHA in deployment and incident |
| GitHub Actions | Primary CI/CD via AWS OIDC | GitHub hosted → AWS | P0+ | Attested build/test/scan and deployment event |
| AWS ECR | Container image storage | AWS | P1 | Scanned immutable digest |
| Terraform | IaC Core and opt-in Labs | AWS | P0+ | Plan, controlled apply and destroy |
| CloudWatch/EventBridge/SQS | Telemetry→incident | AWS | P1–P2 | Alarm route and DLQ replay |
| DynamoDB/S3 | Source records/evidence/audit | AWS | P1+ | Conditional writes and digest |
| Bedrock | Read-only RCA | AWS Region verified P3 | P3 | Evidence-grounded response no mutation |
| Step Functions | Human approval + constrained rollback | AWS | P4 | Callback/token and verifier |
| Prometheus | Pull Kubernetes/EC2 demo metrics | AWS lab | P5 | Scraped metric with exact resource labels |
| Grafana | Incident-correlated dashboard | AWS lab | P5 | Linked panel with metric range |
| ELK (Elasticsearch/Logstash/Kibana) | Lab logs ingest/search | Docker/EC2 in AWS | P5,P7 | Correlation ID searchable |
| GuardDuty/CloudTrail | Security evidence and detection | AWS | P5 | Normalized security incident |
| Kubernetes | Workload manifest/controller mechanics | EKS | P6 | Real unhealthy Pod/Deployment |
| Amazon EKS | Kubernetes managed control-plane lab | AWS, opt-in | P6 | Real incident + teardown |
| Jenkins X | GitOps release event from EKS | AWS EKS lab, availability/version gate | P6 | Real supported pipeline and release event |
| Jenkins | Legacy CI controller and signed deploy events | EC2/RHEL on AWS | P7 | Pipeline output/signature accepted |
| GitLab CI/CD | Separate real CI pipeline runner | Runner on AWS, GitLab SaaS | P7 | Pipeline job and event linked to SHA |
| GitLab SCM | Merge request, commit and webhook mapping | External GitLab SaaS → AWS ingress | P7 | Validated webhook signature and link |
| Bitbucket | PR, commit and webhook mapping | External Bitbucket SaaS → AWS ingress | P7 | Validated webhook signature and link |
| OpenShift | Kubernetes distribution lab with failing rollout | ROSA/OpenShift cluster on AWS | P7 | Real pod event/metric/log |
| Nomad | Job scheduler and allocation failure | EC2 RHEL on AWS | P7 | Job fail event → incident |
| Red Hat/RHEL | Hardened Linux base for labs | RHEL AMI / EC2 AWS | P7 | Versioned AMI and host inventory |
| Packer | Image build pipeline | AWS AMI creation | P7 | AMI ID/provenance and scan |
| Ansible | Repeatable RHEL/EC2/Nomad/Jenkins configuration | AWS EC2 lab | P7 | Idempotent playbook with drift check |

**Not cloud multi-provider:** GitHub/GitLab/Bitbucket SaaS are SCM/CI services, **not deployment cloud targets**. Workloads are deployed to AWS only. OpenShift may remain blocked if ROSA financial/support/quota requirements cannot be met; do not downgrade a real deployment criterion into a stub.
