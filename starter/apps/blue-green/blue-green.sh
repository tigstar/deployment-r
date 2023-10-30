#!/bin/bash

function green_deployment {
  kubectl apply -f starter/apps/blue-green/green.yml -n udacity
  sleep 1
  GREEN_PODS=$(kubectl get pods -n udacity | grep -c green)
  echo "GREEN PODS: $GREEN_PODS"
  
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/green -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Green deployment has been successfull !"
}

# Deploy the green version
green_deployment