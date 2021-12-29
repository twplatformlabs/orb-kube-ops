#!/usr/bin/env bash

kubectl apply -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml && sleep 10

kubectl logs -n ${NAMESPACE} -f job.batch/kube-bench --all-containers=true | grep "\[FAIL" > temp.results
if [[ $(cat temp.results) ]]; then
  echo "kube-bench conformance results error:"
  cat temp.results
  exit 1
fi
rm temp.results

kubectl delete -n ${NAMESPACE} -f cis-benchmarks-deployment.yaml
