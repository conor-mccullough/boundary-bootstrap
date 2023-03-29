kubectl apply -f postgres-config.yaml
# probably need some sleep timers in here or something
kubectl apply -f postgres-pvc-pv.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Run on with the rest of the installations:
#./install.sh
