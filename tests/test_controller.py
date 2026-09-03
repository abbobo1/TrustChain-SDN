import importlib.util
from pathlib import Path


CONTROLLER_PATH = Path(__file__).parents[1] / "sdn-controller" / "controller.py"
spec = importlib.util.spec_from_file_location("trustchain_controller", CONTROLLER_PATH)
controller = importlib.util.module_from_spec(spec)
spec.loader.exec_module(controller)


def policy(action="ALLOW", status="ACTIVE"):
    return {
        "policyID": "policy001",
        "tenantID": "tenantA",
        "source": "10.0.1.1/32",
        "destination": "10.0.2.1/32",
        "action": action,
        "priority": 100,
        "status": status,
    }


def test_allow_flow_outputs_normally():
    flow = controller.build_flow(policy())
    action = flow["instructions"]["instruction"][0]["apply-actions"]["action"][0]
    assert action["output-action"]["output-node-connector"] == "NORMAL"


def test_deny_flow_has_no_output_instruction():
    flow = controller.build_flow(policy("DENY"))
    assert flow["instructions"] == {"instruction": []}


def test_inactive_policy_produces_no_flow():
    assert controller.build_flow(policy(status="INACTIVE")) is None
