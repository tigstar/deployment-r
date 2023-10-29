#!/bin/bash

DEPLOY_INCREMENTS=1

function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "Number of V1 Pods: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "Number of V2 Pods: $NUM_OF_V2_PODS"

  echo "Scaling V1 down and V2 up incrementally ..."

  kubectl scale deployment canary-v2 -n udacity --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS))
  kubectl scale deployment canary-v1 -n udacity --replicas=$((NUM_OF_V1_PODS - $DEPLOY_INCREMENTS))
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
}

# Create the html page config
kubectl apply -f starter/apps/canary/index_v2_html.yml
# Create canary-v2 deployment
kubectl apply -f starter/apps/canary/canary-v2.yml
# Create canary svc
kubectl apply -f starter/apps/canary/canary-svc.yml

sleep 1
# Begin canary deployment and stop when it reaches 50%
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -ne 2 $(kubectl get pods -n udacity | grep -c canary-v2) ]
do
  canary_deploy
done

echo "Canary deployment of v2 is done by 50%"