#!/usr/bin/env bash

echo "deploy benchmark job"
kubectl apply -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml

echo "sleep for 10 seconds"
sleep 10

echo "check job logs for FAILURE"
kubectl logs -n ${NAMESPACE} -f job.batch/kube-bench --all-containers=true | grep "\[FAIL" > temp.results

echo "eval temp.results file"
#if [[ $(cat temp.results) ]]; then
if [[ -f temp.results ]] && [[ ! -s temp.results ]]; then
  echo "kube-bench conformance results error:"
  cat temp.results
  exit 1
fi

echo "delete benchmark job"
kubectl delete -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml
