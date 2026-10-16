# Infrastructure setup

P0 validated configuration and mocked plans; it created no account resources.
`bootstrap` defaults to `provision_bootstrap=false`, and all six environment flags
default to `false`. The dev core now includes the P1-01 static web hosting module;
all other unfinished phases still fail closed. No AWS resources are created by
this repository until an operator applies an approved plan. See
[module ownership](modules/README.md).
ADR-018 sets `us-east-1` as the active region; the Terraform guardrails reject
other regions until a new reviewed decision. This changes no existing AWS resource.

## P1-01 static web hosting

`infra/environments/dev/core` optionally provisions a private S3 bucket and a
CloudFront distribution using Origin Access Control. The bucket blocks all public
access, enforces TLS and SSE-S3, and cannot delete uploaded objects during destroy.
It versions assets and expires noncurrent versions after 30 days; incomplete uploads
expire after seven days.
CloudFront redirects viewers to HTTPS and rewrites trailing-slash paths to the
Next.js static export's `index.html`. The distribution uses the default CloudFront
certificate, AWS's managed security headers policy, and `PriceClass_100`; no
custom domain, DNS, or asset upload is configured.

`create_core` remains `false` by default. To prepare a plan, set it to `true` only
in an ignored `terraform.tfvars`, set a named `owner_tag`, and review the exact
S3, CloudFront, and function resources and regional pricing before apply. The
module outputs `web_bucket_name` and `web_distribution_domain_name`. This PR does
not apply the plan or verify a live HTTPS response; the bucket is empty until a
static export is uploaded.

The static-site Checkov exceptions are limited to optional failover, geo-restriction,
WAF, custom certificate, logging, cross-region replication, KMS, and event
notifications. Each is either absent from the product requirements or requires a
separate cost, retention, or domain decision; review them before production use.

## Offline checks

From the repository root:

```text
node scripts/check-infra.mjs
uvx --from checkov==3.3.29 checkov --directory infra --framework terraform --compact
```

Terraform **1.15.5** and AWS provider **6.69.1** are pinned; lockfiles include signed
Windows/Linux checksums. The check script runs `init -backend=false -lockfile=readonly`,
`validate` and `test` for every root. Mock providers prevent credential lookup and
AWS API calls. Provider downloads still require Internet on the first run.

| Root | Remote state key |
| --- | --- |
| `environments/dev/core` | `cic/dev/core.tfstate` |
| `environments/dev/ecs-lab` | `cic/dev/ecs-lab.tfstate` |
| `environments/lab/observability` | `cic/lab/observability.tfstate` |
| `environments/lab/eks` | `cic/lab/eks.tfstate` |
| `environments/lab/rosa` | `cic/lab/rosa.tfstate` |
| `environments/lab/nomad` | `cic/lab/nomad.tfstate` |

The bootstrap starts with local state because its S3 backend does not exist yet.
Keep that state encrypted with restricted filesystem access, outside Git; after
approval and creation, migrate it to the bucket under **`cic/bootstrap.tfstate`**
using an explicitly reviewed backend configuration and `terraform init -migrate-state`.
Never include bootstrap or core in routine lab teardown.

## Prepare the first real plan

1. Verify the AWS account alias, `us-east-1` and the deploy role. Prefer AWS SSO
   or an assumed role; run `aws sts get-caller-identity` and compare its account
   to the reviewed plan. Do not use a long-lived IAM user key for Terraform or
   paste credentials into this repository.
2. Copy `bootstrap/terraform.tfvars.example` to `bootstrap/terraform.tfvars`.
   Replace every placeholder: account, unique bucket name, owner, recipient and
   exact backend role ARNs. Keep all environment flags off.
3. Estimate S3 storage/version retention and any budget-related account charges.
   Record the [cost approval form](../docs/13_COST_BUDGET.md). The budget is an
   **account-wide monthly COST alert** at USD 25, with 50/80/100% actual-spend
   notifications. It is not a cap, not project-tag-filtered, and does not stop AWS.
4. Explicitly enable `provision_bootstrap` only for the reviewed bootstrap plan:

   ```text
   terraform -chdir=infra/bootstrap init -input=false -lockfile=readonly
   terraform -chdir=infra/bootstrap plan -out=reviewed.tfplan
   terraform -chdir=infra/bootstrap show -no-color reviewed.tfplan
   ```

5. Review the exact seven resources: S3 bucket, versioning, SSE-S3 configuration,
   public-access block, TLS/role-restriction bucket policy, incomplete-upload
   lifecycle and AWS Budget. Confirm recipient ownership and backend IAM access
   before approval. `prevent_destroy` and `force_destroy=false` protect the bucket.
6. Only after explicit plan/cost approval may an operator apply that saved plan.
   Confirm budget notifications arrive and record account evidence. This repository
   intentionally contains no apply/destroy workflow.

Each state root has `backend.hcl.example`. Copy to ignored `backend.hcl`, replace
the bucket, then initialize the **exact** root with `-backend-config=backend.hcl`.
S3 backend uses `encrypt=true` and `use_lockfile=true`, plus bucket versioning.
Grant each role only its own state prefix: bucket ListBucket for the exact prefix,
GetObject/PutObject on its `.tfstate`, and GetObject/PutObject/DeleteObject on the
matching `.tfstate.tflock`. The bucket's deny policy does not grant IAM permissions.
Core/lab deployment permissions also need separate least-privilege policies in P1;
separate state keys alone do not prove IAM isolation.

## GitHub OIDC and branch protection

After the initial code is published, verify these settings on GitHub:

- Protect `main`: require PR review, code-owner review, fresh approvals, resolved
  conversations and required checks `quality (ubuntu-latest)`,
  `quality (windows-latest)`, `terraform`, `security`; prohibit force pushes and
  branch deletion. Currently the repository has only its owner as a collaborator;
  add an independent reviewer before enabling mandatory approval. The CI check
  gate and the review gate are separate settings.
- Create environment **`aws-plan`**, allow only `main`, require a reviewer and
  prevent self-review. Verify these controls are supported by the repository's plan.
- Use `bootstrap/github-oidc-trust.json.example` as a reviewed template, replace
  account ID and verify the actual OIDC subject for this repository. It restricts
  `aud=sts.amazonaws.com` and exact repository/environment via `StringEquals`.
  An environment-style subject does **not** also contain a branch: the GitHub
  environment's `main` restriction and workflow ref guard enforce that boundary.
- Provision a dedicated least-privilege plan role only after review. Set environment
  variables `AWS_ACCOUNT_ID`, `AWS_PLAN_ROLE_ARN` and `TF_STATE_BUCKET`. The manual
  workflow verifies role/account and `us-east-1` before planning. No static AWS keys
  are used. It fails when configuration is absent, runs only on `main`, uploads a
  plan and checksum for three days, and never applies it. Treat plan artifacts as
  sensitive; review repository access before enabling the workflow.

## Lab cleanup

`expires_at` tags and a four-hour plan validation are **not an automatic shutdown**.
Assign a cleanup owner and timer whenever enabling a future lab. For example,
after verifying the initialized backend is `cic/dev/ecs-lab.tfstate`:

```text
terraform -chdir=infra/environments/dev/ecs-lab state list
terraform -chdir=infra/environments/dev/ecs-lab plan -destroy -out=reviewed-destroy.tfplan
terraform -chdir=infra/environments/dev/ecs-lab show -no-color reviewed-destroy.tfplan
```

Review the exact resource list and confirm no core/bootstrap resources occur.
Apply the saved destroy plan only after explicit approval; then verify residual
tasks, volumes, IPs, logs, snapshots and delayed charges using RB-07 in the
[operations runbooks](../docs/14_OPERATIONS_RUNBOOKS.md). No destroy was run in P0.

## Security scan exceptions

Four scoped Checkov exceptions are annotated on the state bucket: access logging
destination deferred pending CloudTrail/data-event review (`CKV_AWS_18`), no
cross-region replication in single-region dev (`CKV_AWS_144`), SSE-S3 instead of
additional KMS cost/key lifecycle (`CKV_AWS_145`), and no bucket event consumer
(`CKV2_AWS_62`). They are visible skips, not validated controls. Revisit logging
before AWS apply, and all four before any production state backend.

References checked during setup: [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3),
[AWS Budget resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget),
[GitHub OIDC for AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws).
