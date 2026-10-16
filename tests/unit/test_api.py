from pathlib import Path

import yaml
from cic_api.main import app, handler
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator

client = TestClient(app)


def test_health_matches_authoritative_contract():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "0.1.0"}
    spec = yaml.safe_load(
        (Path(__file__).resolve().parents[2] / "docs/10_API_OPENAPI.yaml").read_text(
            encoding="utf-8"
        )
    )
    Draft202012Validator(spec["components"]["schemas"]["Health"]).validate(response.json())
    assert callable(handler)
    live = client.get("/openapi.json").json()
    assert (
        live["paths"]["/healthz"]["get"]["operationId"]
        == spec["paths"]["/healthz"]["get"]["operationId"]
    )


def test_future_routes_are_not_exposed_without_authentication():
    assert client.get("/v1/resources").status_code == 404
    assert client.post("/webhooks/example", json={}).status_code == 404
    assert set(client.get("/openapi.json").json()["paths"]) == {"/healthz"}


def test_cors_is_limited_to_the_local_web_origin():
    allowed = client.get("/healthz", headers={"Origin": "http://127.0.0.1:3000"})
    denied = client.get("/healthz", headers={"Origin": "https://untrusted.example"})
    assert allowed.headers["access-control-allow-origin"] == "http://127.0.0.1:3000"
    assert "access-control-allow-origin" not in denied.headers
