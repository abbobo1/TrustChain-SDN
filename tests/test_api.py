import importlib.util
import json
from pathlib import Path
from unittest.mock import patch


APP_PATH = Path(__file__).parents[1] / "blockchain-api" / "app.py"
spec = importlib.util.spec_from_file_location("trustchain_api", APP_PATH)
api = importlib.util.module_from_spec(spec)
spec.loader.exec_module(api)


def test_health():
    response = api.app.test_client().get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "UP"


def test_rejects_invalid_policy_id():
    response = api.app.test_client().get("/policy/invalid$id")
    assert response.status_code == 400


@patch.object(api.subprocess, "run")
def test_returns_blockchain_policy(run):
    policy = {"policyID": "policy001", "action": "ALLOW"}
    run.return_value.returncode = 0
    run.return_value.stdout = json.dumps(policy)
    run.return_value.stderr = ""
    response = api.app.test_client().get("/policy/policy001")
    assert response.status_code == 200
    assert response.get_json() == policy
