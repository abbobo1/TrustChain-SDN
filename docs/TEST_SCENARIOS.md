# Test Scenarios

## Automated tests

| ID | Scenario | Input | Expected result |
| --- | --- | --- | --- |
| UT-01 | API health | `GET /health` | HTTP 200 and status `UP` |
| UT-02 | Invalid policy identifier | `GET /policy/invalid$id` | HTTP 400 |
| UT-03 | Successful mocked Fabric query | `policy001` | Policy JSON and HTTP 200 |
| UT-04 | Active ALLOW translation | Active `ALLOW` policy | Flow outputs to `NORMAL` |
| UT-05 | Active DENY translation | Active `DENY` policy | Flow has no output action |
| UT-06 | Inactive-policy translation | Status `INACTIVE` | No flow is produced |

Execute all automated tests:

```bash
source .venv/bin/activate
pytest -q
```

## Integration tests

### IT-01: Create and retrieve an ALLOW policy

Create `policy001` using the command in `README.md`. Query it directly with the
Fabric CLI and through the API. Both outputs must contain the same policy ID,
source, destination, action, priority and status.

### IT-02: Controller ALLOW decision

Run the API and controller with `policy001` active. The controller must display
`Traffic PERMITTED`, the matching endpoints and `OUTPUT:NORMAL`.

### IT-03: Controller DENY decision

Create a different policy with action `DENY`, then set `POLICY_API_URL` to its
API URL before starting the controller. It must display `Traffic BLOCKED` and
`DROP`.

### IT-04: Duplicate policy protection

Invoke `CreatePolicy` twice using the same policy ID. The second transaction
must fail with a message stating that the policy already exists.

### IT-05: Unknown policy

Query a policy ID that was never created. Fabric must return `policy ... does
not exist`, and the API must return an error response rather than fabricated
policy data.

### IT-06: Optional OpenDaylight installation

With a compatible OpenDaylight instance and OpenFlow node connected, set
`ODL_APPLY=true`. Run the controller and verify both the successful RESTCONF
response and the flow in OpenDaylight's inventory. Keep dry-run mode enabled if
the distribution exposes a different RESTCONF resource path.

## Performance tests

| ID | Script | Measurement |
| --- | --- | --- |
| PT-01 | `benchmark_write_latency.sh` | Min, max, mean and standard deviation of successful writes |
| PT-02 | `benchmark_throughput.sh` | Successful committed submissions divided by elapsed time |

Policy IDs must be unique between benchmark executions. If an ID already exists,
change the `latencyB` or `throughputB` prefix before rerunning.
