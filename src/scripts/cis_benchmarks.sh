#!/usr/bin/env bash

echo "deploy benchmark job"
kubectl apply -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml

echo "sleep for 30 seconds"
sleep 30

echo "check job logs for FAILURE"
RESULTS=$(kubectl logs -n ${NAMESPACE} -f job.batch/kube-bench --all-containers=true | grep "0 checks FAIL")

echo "evaluate RESULTS"
if [[ -z "$RESULTS" ]]; then
  echo "kube-bench conformance results error:"
  cat temp.results
  exit 1
fi

echo "delete benchmark job"
kubectl delete -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml
