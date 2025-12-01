#!/bin/bash
#
# This script safely deploys or updates the 'codex' umbrella chart.
#
# It automatically:
# 1. Updates dependencies (if Chart.yaml changed).
# 2. Installs or upgrades the release.
# 3. Rolls back automatically if the upgrade fails.
#
# Run this from the 'codex' directory: ./deploy.sh

# --- Configuration ---
CHART_DIR="../helm/codex" 
RELEASE_NAME="codex"
NAMESPACE="app-services"
# ---------------------

echo "Updating Helm dependencies for '$RELEASE_NAME' in $CHART_DIR..."

helm dependency update $CHART_DIR

echo "Deploying/Updating '$RELEASE_NAME' in namespace '$NAMESPACE'..."


helm upgrade --install $RELEASE_NAME $CHART_DIR \
  --namespace $NAMESPACE \
  --atomic \
  --create-namespace \
  --timeout 15m \
  --wait

echo "✅ '$RELEASE_NAME' application deployment complete."