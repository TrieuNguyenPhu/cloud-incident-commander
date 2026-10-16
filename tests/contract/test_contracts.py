import importlib
import json
import re
from pathlib import Path

import pytest
import yaml
from jsonschema import Draft202012Validator, FormatChecker
from openapi_spec_validator import validate
from pydantic import ValidationError

ROOT = Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / "docs/11_EVENT_SCHEMAS"
EVENTS = [
    ("signal_event", "SignalEvent"),
    ("deployment_event", "DeploymentEvent"),
    ("cloudwatch_alarm", "CloudWatchAlarmEventEnvelope"),
    ("ai_analysis_report", "AIAnalysisReport"),
    ("approval_decision_event", "ApprovalDecisionEvent"),
]


def event_contract(fixture, title):
    schema = json.loads((SCHEMAS / f"{title}.schema.json").read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", title)
    name = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", name).lower()
    model = getattr(importlib.import_module(f"cic_contracts.generated.{name}"), title)
    location = (
        ROOT / "tests/fixtures/approval_decision_event_valid.json"
        if title == "ApprovalDecisionEvent"
        else SCHEMAS / "fixtures" / f"{fixture}_valid.json"
    )
    payload = json.loads(location.read_text(encoding="utf-8"))
    return schema, validator, model, payload


@pytest.mark.parametrize(("fixture", "title"), EVENTS)
def test_event_fixtures_and_pydantic_roundtrip(fixture, title):
    _, validator, model, payload = event_contract(fixture, title)
    validator.validate(payload)
    parsed = model.model_validate_json(json.dumps(payload))
    validator.validate(parsed.model_dump(mode="json", by_alias=True, exclude_unset=True))


@pytest.mark.parametrize(("fixture", "title"), EVENTS)
def test_every_required_field_is_required(fixture, title):
    schema, validator, model, payload = event_contract(fixture, title)
    for field in schema["required"]:
        invalid = {key: value for key, value in payload.items() if key != field}
        assert not validator.is_valid(invalid), field
        with pytest.raises(ValidationError):
            model.model_validate_json(json.dumps(invalid))


@pytest.mark.parametrize(("fixture", "title"), EVENTS)
def test_reject_unsupported_versions_and_malformed_timestamps(fixture, title):
    _, validator, model, payload = event_contract(fixture, title)
    version_key = "version" if title == "CloudWatchAlarmEventEnvelope" else "schema_version"
    timestamp_key = {
        "CloudWatchAlarmEventEnvelope": "time",
        "ApprovalDecisionEvent": "decided_at",
    }.get(title, "ingested_at")
    invalid_cases = [{**payload, version_key: "99"}]
    if timestamp_key in payload:
        invalid_cases.append({**payload, timestamp_key: "not-a-timestamp"})
    for invalid in invalid_cases:
        assert not validator.is_valid(invalid)
        with pytest.raises(ValidationError):
            model.model_validate_json(json.dumps(invalid))


@pytest.mark.parametrize(
    "changes",
    [
        {"hypotheses": [{"summary": "invented structure"}]},
        {"recommended_actions": []},
        {
            "recommended_action": {
                "action_type": "shell.exec",
                "resource_uid": "x",
                "target_revision": "x",
            }
        },
    ],
)
def test_ai_contract_rejects_unsafe_or_stale_shapes(changes):
    _, validator, model, payload = event_contract("ai_analysis_report", "AIAnalysisReport")
    invalid = {**payload, **changes}
    assert not validator.is_valid(invalid)
    with pytest.raises(ValidationError):
        model.model_validate_json(json.dumps(invalid))


def test_signal_unknown_source_and_legacy_timestamp_rejected():
    _, validator, model, payload = event_contract("signal_event", "SignalEvent")
    for invalid in [
        {**payload, "observed_at": payload["occurred_at"]},
        {**payload, "source": "unknown"},
    ]:
        assert not validator.is_valid(invalid)
        with pytest.raises(ValidationError):
            model.model_validate_json(json.dumps(invalid))


def test_openapi_is_valid_and_contains_required_operations():
    spec = yaml.safe_load((ROOT / "docs/10_API_OPENAPI.yaml").read_text(encoding="utf-8"))
    validate(spec)
    operations = {
        (method.upper(), path)
        for path, item in spec["paths"].items()
        for method in item
        if method in {"get", "post", "put", "patch", "delete"}
    }
    summary = (ROOT / "docs/02_SERVICE_ARCHITECTURE.md").read_text(encoding="utf-8")
    for method, path in re.findall(r"\| (GET|POST) \| `([^`]+)`", summary):
        path = path.split("?")[0]
        if path != "/healthz" and not path.startswith("/webhooks/"):
            path = "/v1" + path
        normalized = re.sub(r"\{[^}]+\}", "{id}", path)
        assert any(
            m == method and re.sub(r"\{[^}]+\}", "{id}", p) == normalized for m, p in operations
        )
    assert len(operations) == 21
    for method, path in operations:
        security = spec["paths"][path][method.lower()].get("security", [])
        assert security == ([{"CognitoJWT": []}] if path.startswith("/v1/") else [])


def test_architecture_examples_match_schemas():
    text = (ROOT / "docs/02_SERVICE_ARCHITECTURE.md").read_text(encoding="utf-8")
    examples = [json.loads(block) for block in re.findall(r"```json\n(.*?)\n```", text, re.S)]
    for (fixture, title), payload in zip(
        [EVENTS[0], EVENTS[1], EVENTS[3]], examples[:3], strict=True
    ):
        _, validator, _, _ = event_contract(fixture, title)
        validator.validate(payload)


@pytest.mark.parametrize("entity", ["Action", "Approval"])
def test_storage_and_api_share_status_enums(entity):
    spec = yaml.safe_load((ROOT / "docs/10_API_OPENAPI.yaml").read_text(encoding="utf-8"))
    database = (ROOT / "docs/03_DATABASE_DESIGN.md").read_text(encoding="utf-8")
    match = re.search(rf"^{entity}\.status: (.+)$", database, re.M)
    assert match
    assert set(match[1].split(" | ")) == set(
        spec["components"]["schemas"][entity]["properties"]["status"]["enum"]
    )
