# P0 verification

`uv run pytest` runs contract, API smoke and setup security checks. Contracts cover
all five event schemas, required fields, versions, invalid timestamps, unsafe AI
shapes, OpenAPI endpoints/auth declarations, architecture examples and shared
Action/Approval enums. Baseline tests check the original spec manifest and the
72-story dependency graph. The tiny health implementation has a coverage gate;
that percentage is not a claim about the future incident domain.

`npm run contracts:check` checks deterministic generated Python/TypeScript output.
`node scripts/check-infra.mjs` validates isolated backend keys, Terraform format,
all configuration roots and mock-provider plan assertions. It requires no AWS
identity and never applies infrastructure. The infrastructure script includes
assertions and Terraform failures propagate as nonzero exits.

Live DynamoDB/EventBridge/Cognito integration and UAT-01..20 are pending their
backlog phases. No placeholder integration test reports them as passed.
