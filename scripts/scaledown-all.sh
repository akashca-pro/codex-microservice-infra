#!/bin/bash

# --- Scale Down ALL Deployments to 0 Replicas ---

NAMESPACE=${1:-"default"} # Use the first argument as namespace, default to 'default'
TARGET_REPLICAS=0

echo "🚨 WARNING: Scaling ALL Deployments in namespace '$NAMESPACE' to $TARGET_REPLICAS replicas."
read -r -p "Are you sure? (y/N): " response

if [[ "$response" != "y" ]]; then
  echo "Operation cancelled."
  exit 0
fi

echo "🔍 Finding Deployments in namespace '$NAMESPACE'..."

# Get a list of all Deployment names in the specified namespace
DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

if [ -z "$DEPLOYMENTS" ]; then
  echo "✅ No Deployments found in namespace '$NAMESPACE'. Nothing to scale."
  exit 0
fi

# Loop through each Deployment and scale it down
for DEPLOYMENT in $DEPLOYMENTS; do
  echo "⬇️ Scaling Deployment '$DEPLOYMENT' to $TARGET_REPLICAS..."
  kubectl scale deployment/"$DEPLOYMENT" -n "$NAMESPACE" --replicas=$TARGET_REPLICAS
done

echo ""
echo "✨ Scale-down operation finished."
echo "Verify status: kubectl get deployments -n $NAMESPACE"