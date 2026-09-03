#!/bin/bash

set -u

CHANNEL_NAME="mychannel"
CC_NAME="trustchain"
TOTAL_TX=30

RESULTS="$HOME/TrustChain-SDN/throughput_results.csv"
RAW_LOG="$HOME/TrustChain-SDN/throughput_raw.log"

echo "Run,PolicyID,Status" > "$RESULTS"
: > "$RAW_LOG"

echo "=========================================="
echo "TrustChain 30-Transaction Throughput Benchmark"
echo "=========================================="
echo ""

START_TIME=$(date +%s%N)

for ((i=1; i<=TOTAL_TX; i++))
do
   POLICY_ID=$(printf "throughputB%03d" "$i")

    echo "===== Run $i / Policy $POLICY_ID =====" >> "$RAW_LOG"

    OUTPUT=$(peer chaincode invoke \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.example.com \
      --tls \
      --cafile "$ORDERER_CA" \
      -C "$CHANNEL_NAME" \
      -n "$CC_NAME" \
      --peerAddresses localhost:7051 \
      --tlsRootCertFiles "$PEER0_ORG1_CA" \
      --peerAddresses localhost:9051 \
      --tlsRootCertFiles "$PEER0_ORG2_CA" \
      -c "{\"function\":\"CreatePolicy\",\"Args\":[\"$POLICY_ID\",\"tenantA\",\"10.0.1.$i\",\"10.0.2.$i\",\"ALLOW\",\"1\",\"ThroughputTest\"]}" 2>&1)

    EXIT_CODE=$?

    echo "$OUTPUT" >> "$RAW_LOG"
    echo "Exit code: $EXIT_CODE" >> "$RAW_LOG"
    echo "" >> "$RAW_LOG"

    if [ "$EXIT_CODE" -eq 0 ]; then
        STATUS="SUCCESS"
        echo "$i,$POLICY_ID,$STATUS" >> "$RESULTS"
        echo "Run $i/$TOTAL_TX | $POLICY_ID | SUCCESS"
    else
        STATUS="FAILED"
        echo "$i,$POLICY_ID,$STATUS" >> "$RESULTS"
        echo "Run $i/$TOTAL_TX | $POLICY_ID | FAILED"
        echo "$OUTPUT"
    fi
done

END_TIME=$(date +%s%N)

ELAPSED_NS=$((END_TIME - START_TIME))
ELAPSED_SEC=$(awk -v ns="$ELAPSED_NS" 'BEGIN {printf "%.6f", ns/1000000000}')

SUCCESSFUL=$(awk -F',' 'NR > 1 && $3 == "SUCCESS" {count++} END {print count+0}' "$RESULTS")
FAILED=$(awk -F',' 'NR > 1 && $3 == "FAILED" {count++} END {print count+0}' "$RESULTS")

THROUGHPUT=$(awk -v s="$SUCCESSFUL" -v t="$ELAPSED_SEC" \
    'BEGIN {if (t > 0) printf "%.3f", s/t; else print "0"}')

echo ""
echo "=========================================="
echo "THROUGHPUT BENCHMARK COMPLETE"
echo "=========================================="
echo "Total transactions : $TOTAL_TX"
echo "Successful         : $SUCCESSFUL"
echo "Failed             : $FAILED"
echo "Total elapsed time : $ELAPSED_SEC seconds"
echo "Throughput         : $THROUGHPUT transactions/second"
echo ""
echo "CSV results:"
echo "$RESULTS"
echo ""
echo "Raw logs:"
echo "$RAW_LOG"
