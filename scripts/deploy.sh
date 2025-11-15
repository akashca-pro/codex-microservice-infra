#!/bin/bash
set -euo pipefail

echo "=== Applying namespaces manifests ==="
kubectl apply -f k8s/00-namespaces.yaml

echo "=== Applying Helmfile for ingress and observability ==="
helmfile --file k8s/helm/helmfile.yaml sync

echo "=== Applying Kafka manifests ==="
kubectl apply -f k8s/kafka/

echo "=== Applying main k8s manifests ==="
kubectl apply -f k8s/

sleep 15

kubectl apply -f k8s/ingress.yaml

echo "✅ All manifests applied successfully!"

sleep 15

kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
echo " Local forwarding is active. Access your services via the Ingress on http://codex.com:8080 (Ctrl+C to stop)."