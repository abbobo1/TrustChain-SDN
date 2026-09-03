from flask import Flask, jsonify
import subprocess
import json
import os
import re

app = Flask(__name__)
POLICY_ID_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{1,64}$")
SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "read_policy.sh")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "UP",
        "service": "TrustChain-SDN Blockchain API"
    })


@app.route("/policy/<policy_id>", methods=["GET"])
def get_policy(policy_id):
    if not POLICY_ID_PATTERN.fullmatch(policy_id):
        return jsonify({"error": "Invalid policy ID"}), 400

    try:
        result = subprocess.run(
            [SCRIPT_PATH, policy_id],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        if result.returncode != 0:
            return jsonify({
                "error": "Blockchain query failed",
                "details": result.stderr
            }), 500

        try:
            return jsonify(json.loads(result.stdout))
        except json.JSONDecodeError:
            return jsonify({
                "error": "Blockchain returned invalid JSON",
                "details": result.stdout
            }), 502

    except subprocess.TimeoutExpired:
        return jsonify({"error": "Blockchain query timed out"}), 504

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true"
    )
