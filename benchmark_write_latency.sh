#!/bin/bash

# TrustChain-SDN: 30-run CreatePolicy write-latency benchmark

RESULTS="$HOME/TrustChain-SDN/write_latency_results.csv"
LOG="$HOME/TrustChain-SDN/write_latency_raw.log"

echo "Run,PolicyID,Latency_ms,Status" > "$RESULTS"
: > "$LOG"

echo "Starting 30-run TrustChain write-latency benchmark..."
echo "Results: $RESULTS"
echo

for i in $(seq 3 32)
do
   POLICY_ID=$(printf "latencyB%03d" "$i")

    SOURCE="10.0.1.$i"
    DESTINATION="10.0.2.$i"

    START=$(date +%s%N)

    OUTPUT=$(peer chaincode invoke \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.example.com \
      --tls \
      --cafile "$ORDERER_CA" \
      -C mychannel \
      -n trustchain \
      --peerAddresses localhost:7051 \
      --tlsRootCertFiles "$PEER0_ORG1_CA" \
      --peerAddresses localhost:9051 \
      --tlsRootCertFiles "$PEER0_ORG2_CA" \
      -c "{\"function\":\"CreatePolicy\",\"Args\":[\"$POLICY_ID\",\"tenantA\",\"$SOURCE\",\"$DESTINATION\",\"ALLOW\",\"1\",\"Benchmark\"]}" 2>&1)

    EXIT_CODE=$?

    END=$(date +%s%N)

    LATENCY_NS=$((END - START))
    LATENCY_MS=$(awk "BEGIN {printf \"%.3f\", $LATENCY_NS/1000000}")

    if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "Chaincode invoke successful"
    then
        STATUS="SUCCESS"
    else
        STATUS="FAILED"
    fi

    echo "$i,$POLICY_ID,$LATENCY_MS,$STATUS" >> "$RESULTS"

    {
        echo "===== Run $i / Policy $POLICY_ID ====="
        echo "Latency: ${LATENCY_MS} ms"
        echo "Status: $STATUS"
        echo "$OUTPUT"
        echo
    } >> "$LOG"

    echo "Run $i/30 | $POLICY_ID | ${LATENCY_MS} ms | $STATUS"

    sleep 1
done

echo
echo "=========================================="
echo "30-RUN BENCHMARK COMPLETE"
echo "=========================================="

awk -F',' '
NR > 1 && $4 == "SUCCESS" {
    count++
    sum += $3

    if (min == "" || $3 < min)
        min = $3

    if ($3 > max)
        max = $3

    values[count] = $3
}
END {
    if (count == 0) {
        print "No successful transactions recorded."
        exit
    }

    mean = sum / count

    for (i = 1; i <= count; i++)
        variance += (values[i] - mean)^2

    variance = variance / count
    stddev = sqrt(variance)

    printf "\nSuccessful transactions : %d\n", count
    printf "Average latency         : %.3f ms\n", mean
    printf "Minimum latency         : %.3f ms\n", min
    printf "Maximum latency         : %.3f ms\n", max
    printf "Standard deviation      : %.3f ms\n", stddev
}' "$RESULTS"

echo
echo "CSV results saved to:"
echo "$RESULTS"

echo
echo "Raw transaction logs saved to:"
echo "$LOG"
