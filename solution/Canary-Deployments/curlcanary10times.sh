#!/bin/bash

CANARY_HOST_NAME=$(kubectl get service/canary-svc --output=jsonpath='{.status.loadBalancer.ingress[].hostname}')
echo "Canary app host name : $CANARY_HOST_NAME"
echo "Running 10 requests ..."

sleep 1
# Begin canary deployment and stop when it reaches 50%
for run in {1..10}; do

  curl $CANARY_HOST_NAME >> solution/Canary-Deployments/canary.txt
done
