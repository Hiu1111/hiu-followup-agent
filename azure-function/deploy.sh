#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
LOCATION="${LOCATION:-eastus}"
RESOURCE_GROUP="${RESOURCE_GROUP:-hiu-followup-rg}"
SUFFIX="$(openssl rand -hex 3)"
STORAGE_ACCOUNT="hiufollowup${SUFFIX}"
FUNCTION_APP="hiu-followup-${SUFFIX}"
TOKEN_FILE="../token.json"
command -v az >/dev/null   || { echo "Azure CLI missing: brew install azure-cli"; exit 1; }
[ -f "$TOKEN_FILE" ]       || { echo "token.json not found at $TOKEN_FILE. Run main.py in the parent folder once."; exit 1; }
az account show >/dev/null 2>&1 || { echo "Not signed in to Azure. Run: az login"; exit 1; }
echo "Subscription: $(az account show --query name -o tsv)"
echo "Registering Azure resource providers..."
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.Storage --wait
echo "Creating resource group '$RESOURCE_GROUP' in $LOCATION..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" -o none
echo "Creating storage account '$STORAGE_ACCOUNT'..."
az storage account create --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --location "$LOCATION" --sku Standard_LRS --allow-blob-public-access false -o none
echo "Creating Function App '$FUNCTION_APP'..."
if ! az functionapp create --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" --storage-account "$STORAGE_ACCOUNT" --consumption-plan-location "$LOCATION" --runtime python --runtime-version 3.11 --functions-version 4 --os-type Linux -o none; then
  echo "Consumption plan unavailable, trying Flex Consumption..."
  az functionapp create --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" --storage-account "$STORAGE_ACCOUNT" --flexconsumption-location "$LOCATION" --runtime python --runtime-version 3.11 -o none
fi
echo "Applying settings..."
az functionapp config appsettings set --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" -o none --settings "NOTIFY_EMAIL=hiu3648@gmail.com" "LABEL_NAME=founders" "FOLLOWUP_DAYS=7" "MAX_FOLLOWUPS=2" "RESPONDED_LABEL=responded" "SHEET_ID=" "STATE_CONTAINER=followup-state" "WEBSITE_TIME_ZONE=Eastern Standard Time" "AzureWebJobsFeatureFlags=EnableWorkerIndexing"
az functionapp config appsettings set --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" -o none --settings "GMAIL_TOKEN_JSON=$(cat "$TOKEN_FILE")"
echo "Publishing code (first build takes a few minutes)..."
zip -qr app.zip . -x "*.md" "deploy.*" "*.ps1" "local.settings*" "__pycache__/*" && az functionapp deployment source config-zip --name "$FUNCTION_APP" --resource-group "$RESOURCE_GROUP" --src app.zip --build-remote true
echo
echo "Done. Function App: $FUNCTION_APP  (resource group: $RESOURCE_GROUP)"
echo "Remove the Mac schedule now with:  crontab -r"
