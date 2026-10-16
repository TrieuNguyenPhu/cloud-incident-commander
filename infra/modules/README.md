# Module ownership

P0 implements `state_backend` (isolated bootstrap bucket and budget) and
`environment_guardrails` (mandatory owner/tags and bounded lab expiry).

The topology below is reserved for the owning backlog story. Environment flags
currently reject `true`, so an empty skeleton cannot be mistaken for a deployed
integration. Create each module when implementing its story; no AWS resource is
implicitly instantiated by a directory or README.

| Module | First story |
| --- | --- |
| cloudfront_static | P1-01 |
| cognito | P1-02 |
| api_gateway_lambda | P1-04 |
| dynamodb_core | P1-03 |
| evidence_s3 | P2-06 |
| event_bus_classic | P1-09 |
| deployment_recorder | P1-09 |
| inventory_collector | P1-10 |
| audit_outbox | P1-11 |
| ecs_demo_public | P1-05 |
| cloudwatch_5xx_alarm | P1-08 |
| sqs_ingest | P2-01 |
| step_functions_approval | P4-02 |
| executor_restricted | P4-05 |
| observability_lab | P5-01..03 |
| eks_lab | P6-01 |
| rosa_lab | P7-08 |
| nomad_lab | P7-03 |
