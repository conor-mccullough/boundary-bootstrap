#!/bin/bash
set -x
source ~/.bashrc 
kubectl apply -f postgres-config.yaml
kubectl apply -f postgres-pvc-pv.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
echo "Postgres install script done, waiting to come up healthy.."
