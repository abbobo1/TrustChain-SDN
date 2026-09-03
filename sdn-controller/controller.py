import hashlib
import json
import os

import requests

API_URL = os.getenv("POLICY_API_URL", "http://localhost:5000/policy/policy001")
ODL_URL = os.getenv("ODL_URL", "http://localhost:8181")
ODL_USER = os.getenv("ODL_USER", "admin")
ODL_PASSWORD = os.getenv("ODL_PASSWORD", "admin")
ODL_APPLY = os.getenv("ODL_APPLY", "false").lower() == "true"


def build_flow(policy):
    """Translate a blockchain policy into an OpenFlow-style flow document."""
    action = policy.get("action", "").upper()
    if policy.get("status") != "ACTIVE":
        return None
    if action not in {"ALLOW", "DENY"}:
        raise ValueError(f"Unsupported policy action: {action}")

    flow_id = "trustchain-" + hashlib.sha256(
        policy["policyID"].encode("utf-8")
    ).hexdigest()[:12]
    instructions = ({
        "instruction": [{
            "order": 0,
            "apply-actions": {
                "action": [{"order": 0, "output-action": {"output-node-connector": "NORMAL"}}]
            },
        }]
    } if action == "ALLOW" else {"instruction": []})

    return {
        "id": flow_id,
        "table_id": 0,
        "priority": int(policy.get("priority", 1)),
        "flow-name": policy["policyID"],
        "match": {
            "ethernet-match": {"ethernet-type": {"type": 2048}},
            "ipv4-source": policy["source"],
            "ipv4-destination": policy["destination"],
        },
        "instructions": instructions,
    }


def install_flow(flow):
    """Install a flow through OpenDaylight's RESTCONF API."""
    node = os.getenv("ODL_NODE", "openflow:1")
    url = (
        f"{ODL_URL}/restconf/config/opendaylight-inventory:nodes/"
        f"node/{node}/table/0/flow/{flow['id']}"
    )
    response = requests.put(
        url,
        auth=(ODL_USER, ODL_PASSWORD),
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        data=json.dumps({"flow": [flow]}),
        timeout=15,
    )
    response.raise_for_status()


def enforce_policy(policy):
    print("\n========== POLICY ENFORCEMENT ==========")

    if policy["status"] != "ACTIVE":
        print("Policy Status : INACTIVE")
        print("Decision      : No flow rule installed.")
        return "INACTIVE"

    if policy["action"].upper() == "ALLOW":
        print("Decision      : Traffic PERMITTED")
        print(f"Installing flow rule:")
        print(f"Match  : {policy['source']} --> {policy['destination']}")
        print("Action : OUTPUT:NORMAL")

    elif policy["action"].upper() == "DENY":
        print("Decision      : Traffic BLOCKED")
        print(f"Blocking traffic:")
        print(f"Match  : {policy['source']} --> {policy['destination']}")
        print("Action : DROP")

    else:
        raise ValueError("Unknown policy action")

    flow = build_flow(policy)
    if ODL_APPLY:
        install_flow(flow)
        print("OpenDaylight : Flow installed successfully")
    else:
        print("Mode          : DRY RUN (set ODL_APPLY=true to install the flow)")

    print("========================================\n")
    return policy["action"].upper()


def get_policy():
    try:
        response = requests.get(API_URL, timeout=15)

        if response.status_code == 200:
            policy = response.json()

            print("\n========== BLOCKCHAIN POLICY ==========")
            print(f"Policy ID   : {policy['policyID']}")
            print(f"Tenant      : {policy['tenantID']}")
            print(f"Source      : {policy['source']}")
            print(f"Destination : {policy['destination']}")
            print(f"Action      : {policy['action']}")
            print(f"Priority    : {policy['priority']}")
            print(f"Status      : {policy['status']}")
            print("=======================================\n")

            enforce_policy(policy)

        else:
            print("Unable to retrieve blockchain policy.")
            print(response.text)

    except Exception as e:
        print("Connection Error:")
        print(e)


if __name__ == "__main__":
    get_policy()
