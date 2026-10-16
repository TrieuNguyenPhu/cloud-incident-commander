# Contracts

Source of truth: `docs/10_API_OPENAPI.yaml` and `docs/11_EVENT_SCHEMAS/*.schema.json`.
`npm run contracts:generate` generates Pydantic models and TypeScript API types.
`npm run contracts:check` regenerates into a temporary directory and rejects drift
without modifying the checkout. Generated files are committed; do not edit them.

Python: `from cic_contracts.generated.signal_event import SignalEvent`.
TypeScript: `import type { components, paths } from "@cic/contracts"`.

The OpenAPI file describes the target v1.1 API. P0 implements only `/healthz`;
FastAPI's live `/openapi.json` intentionally lists only implemented routes. Contract
tests validate the full target document and the implemented health response.
Schema validation does not implement authentication, tenant/resource authorization,
AI citation policy, approval separation or event deduplication. Those remain at
their backlog phases; do not use generated models as an authorization boundary.
