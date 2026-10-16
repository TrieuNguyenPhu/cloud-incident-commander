import json
import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]


def test_oidc_placeholder_has_exact_audience_repository_and_environment():
    trust = json.loads((ROOT / "infra/bootstrap/github-oidc-trust.json.example").read_text())
    statement = trust["Statement"][0]
    assert statement["Action"] == "sts:AssumeRoleWithWebIdentity"
    assert statement["Condition"] == {
        "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            "token.actions.githubusercontent.com:sub": (
                "repo:TrieuNguyenPhu/cloud-incident-commander:environment:aws-plan"
            ),
        }
    }
    assert statement["Principal"]["Federated"].endswith(
        ":oidc-provider/token.actions.githubusercontent.com"
    )
    assert "*" not in json.dumps(trust)


def test_workflows_cannot_apply_or_destroy_and_actions_are_immutable():
    for path in (ROOT / ".github/workflows").glob("*.yaml"):
        workflow = yaml.load(path.read_text(), Loader=yaml.BaseLoader)
        assert "pull_request_target" not in workflow["on"]
        assert workflow["permissions"] == {"contents": "read"}
        for job in workflow["jobs"].values():
            for step in job["steps"]:
                if "uses" in step:
                    assert re.fullmatch(r"[^@]+@[0-9a-f]{40}", step["uses"])
                command = step.get("run", "")
                assert not re.search(r"terraform\b[^\n]*\b(apply|destroy)\b", command)
                assert "AWS_ACCESS_KEY_ID" not in json.dumps(step)
                assert "AWS_SECRET_ACCESS_KEY" not in json.dumps(step)


def test_only_manual_main_environment_job_can_request_aws_token():
    workflows = ROOT / ".github/workflows"
    ci = yaml.load((workflows / "ci.yaml").read_text(), Loader=yaml.BaseLoader)
    assert all("id-token" not in job.get("permissions", {}) for job in ci["jobs"].values())
    plan = yaml.load((workflows / "terraform-plan.yaml").read_text(), Loader=yaml.BaseLoader)
    assert set(plan["on"]) == {"workflow_dispatch"}
    job = plan["jobs"]["plan-core"]
    assert job["if"] == "github.ref == 'refs/heads/main'"
    assert job["environment"] == "aws-plan"
    assert job["permissions"]["id-token"] == "write"
    assert job["env"]["AWS_REGION"] == "us-east-1"
    assert job["env"]["AWS_ACCOUNT_ID"] == "${{ vars.AWS_ACCOUNT_ID }}"
    assert any("aws sts get-caller-identity" in step.get("run", "") for step in job["steps"])
