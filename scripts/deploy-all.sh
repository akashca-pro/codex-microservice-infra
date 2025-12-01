#!/bin/bash
#
# Master script to deploy the entire stack.
# Runs from 'scripts/'
# 1. Deploys Platform (helmfile) from 'helm/'
# 2. Deploys Application (codex) by calling 'deploy-app.sh'

# Exit immediately if any command fails
set -e

# --- Path Configuration ---
# Paths are relative to this script's location (root/scripts/)
HELMFILE_DIR="../helm/"
APP_DEPLOY_SCRIPT="./helm-deploy.sh"
# ---------------------------

# --- Namespaces to ensure ---
# Add all namespaces your stack needs here
NAMESPACES=("app-services" "observability" "ingress-nginx")
# ---------------------------

echo "--- Pre-flight: Ensuring namespaces exist ---"
for ns in "${NAMESPACES[@]}"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done
echo "✅ Namespaces are ready."
echo ""

echo "--- Step 1: Deploying Platform Services (Helmfile) ---"

echo "Changing directory to $HELMFILE_DIR..."
cd $HELMFILE_DIR

echo "Syncing Helmfile repositories..."
helmfile repos

echo "Applying Helmfile platform charts..."
helmfile apply

echo "✅ Platform services are up."
echo ""

echo "Changing directory back to scripts..."
cd ../scripts/ 

echo "--- Step 2: Deploying Codex Application ---"

# Make sure the app script is executable and run it
chmod +x $APP_DEPLOY_SCRIPT
$APP_DEPLOY_SCRIPT

echo "✅ Full Stack Deployment Complete! ✅"