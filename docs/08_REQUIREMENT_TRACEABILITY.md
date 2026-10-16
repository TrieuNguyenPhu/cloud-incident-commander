# Requirement Traceability Matrix v1.1

**All 28 functional requirements mapped to owned service boundaries, backlog and UAT.** These are planned test cases, not results.

| Requirement | Service | Stories | Tests |
|---|---|---|---|
| FR-001 | SVC-02/03 | P1-02 | UAT-03,UAT-11 |
| FR-002 | SVC-07 | P1-10 | UAT-12 |
| FR-003 | SVC-03 | P2-07 | UAT-13 |
| FR-004 | SVC-05 | P2-01,P2-02 | UAT-01 |
| FR-005 | SVC-04 | P1-06,P1-09 | UAT-01,UAT-12 |
| FR-006 | SVC-06 | P2-03 | UAT-02 |
| FR-007 | SVC-03/06 | P2-04 | UAT-14 |
| FR-008 | SVC-08 | P2-05,P2-06 | UAT-01,UAT-15 |
| FR-009 | SVC-09 | P3-01,P3-03 | UAT-04 |
| FR-010 | SVC-10 | P3-04 | UAT-04,UAT-16 |
| FR-011 | SVC-11 | P4-01,P4-02,P4-03 | UAT-05,UAT-11 |
| FR-012 | SVC-13 | P4-04,P4-05 | UAT-06,UAT-07 |
| FR-013 | SVC-14 | P4-06 | UAT-08 |
| FR-014 | SVC-15 | P1-11,P4-07 | UAT-09,UAT-17 |
| FR-015 | SVC-16 | P4-08 | UAT-09 |
| FR-016 | SVC-03 | P5-07 | UAT-21 |
| FR-017 | SVC-18 | P5-01,P5-02 | UAT-22 |
| FR-018 | SVC-18 | P5-03 | UAT-23 |
| FR-019 | SVC-17 | P5-04 | UAT-24 |
| FR-020 | SVC-16 | P5-05,P5-06 | UAT-25 |
| FR-021 | SVC-17 | P6-03,P6-04 | UAT-26 |
| FR-022 | SVC-17 | P6-05 | UAT-27 |
| FR-023 | SVC-17 | P7-08,P7-09 | UAT-28 |
| FR-024 | SVC-17 | P7-03,P7-04 | UAT-29 |
| FR-025 | SVC-17 | P7-05,P7-06,P7-15,P7-16 | UAT-30 |
| FR-026 | SVC-17 | P7-07,P7-13,P7-14 | UAT-31 |
| FR-027 | SVC-17 | P7-01,P7-02 | UAT-32 |
| FR-028 | SVC-03 | P0-05,P6-01,P7-08 | UAT-10,UAT-18 |

## NFR coverage — exact IDs matching `01_SRS.md`

| NFR | Actual requirement | Stories | Test evidence / acceptance |
|---|---|---|---|
| NFR-001 | API latency | P1-04,P4-09 | 10 concurrent users; p95 read under 800ms excluding AI |
| NFR-002 | Incident detection latency | P2-08 | p95 below 120s **after EventBridge receipt**, excludes alarm evaluation |
| NFR-003 | Availability | P1-08,P5-09 | measured uptime during planned demo-on hours, target >=99%, not SLA |
| NFR-004 | Reliability | P2-03,P5-09 | retries, DLQ, duplicate/redrive, no repeat remediation |
| NFR-005 | Security | P1-02,P4-01,P5-08 | JWT/RBAC/least-privilege/OIDC and no-static-key tests |
| NFR-006 | Encryption | P1-03,P2-06,P1-11 | TLS, S3 encryption, DDB at-rest, Secrets Manager proof |
| NFR-007 | Recovery | P5-09 | measured restore drill vs RPO 24h/RTO 4h target |
| NFR-008 | Audit | P1-11,P4-07 | actor/time/outcome correlation, outbox audit reconciliation, conditional overwrite test |
| NFR-009 | AI quality | P3-02,P3-06 | evidence ID checks, INCONCLUSIVE for missing context, prompt injection rejected |
| NFR-010 | Retention | P1-08,P2-06,P4-07 | CloudWatch 14d, evidence 90d lab, audit >=365d, expired metadata visible |
| NFR-011 | Accessibility | P1-07,P2-07 | keyboard and contrast usability smoke |
| NFR-012 | Budget | P0-05,P6-01,P7-08 | opt-in false by default; cost approval and teardown |
| NFR-013 | Tests | P0-06,P4-09 | coverage report and critical-path UAT results |
| NFR-014 | Observability | P1-08,P5-02 | correlation trace IDs, failed Lambda / DLQ alarm evidence |

NFR objectives are **design targets pending measurement**, never pass indicators until evidence is attached.

## Change control

A new FR requires service ownership, backlog ID, schema impact assessment and UAT ID before merging. A story cannot be marked done when relevant UAT has no recorded evidence.
