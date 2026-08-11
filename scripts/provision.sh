#!/usr/bin/env bash
# provision.sh — GatherLoop static site infrastructure
# Provisions an Azure Storage Account with static website hosting enabled,
# uploads the current site/ contents, and prints the live endpoint.
#
# Usage: ./provision.sh
# Requires: az CLI logged in (az login), a target subscription set (az account set --subscription "<name>")

set -euo pipefail

# ---- Config — edit these before running ----
RESOURCE_GROUP="rg-gatherloop-prod"
LOCATION="westeurope"
STORAGE_ACCOUNT="stgatherloop$RANDOM"   # storage account names must be globally unique, 3-24 chars, lowercase+digits only
SITE_DIR="../site"
INDEX_DOC="index.html"
ERROR_DOC="404.html"
# ---------------------------------------------

echo "== Step 1: Resource group =="
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

echo "== Step 2: Storage account (StorageV2, LRS, hierarchical namespace disabled) =="
# hns explicitly set to false — a storage account with Data Lake Gen2 (hierarchical
# namespace) enabled CANNOT serve a static website. This is the #1 cause of a
# "static website" config option not appearing in the portal/CLI later.
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hns false \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access true \
  --output table

echo "== Step 3: Enable static website hosting =="
az storage blob service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --static-website \
  --index-document "$INDEX_DOC" \
  --404-document "$ERROR_DOC" \
  --auth-mode login

echo "== Step 4: Fetch storage account key for upload auth =="
ACCOUNT_KEY=$(az storage account keys list \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[0].value" -o tsv)

echo "== Step 5: Upload site content to \$web container =="
az storage blob upload-batch \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --destination '$web' \
  --source "$SITE_DIR" \
  --overwrite

echo "== Step 6: Live endpoint =="
ENDPOINT=$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "primaryEndpoints.web" -o tsv)

echo ""
echo "Deployed. Site is live at: $ENDPOINT"
echo ""
echo "Save these for GitHub Actions secrets:"
echo "  AZURE_STORAGE_ACCOUNT = $STORAGE_ACCOUNT"
echo "  AZURE_STORAGE_KEY     = (from az storage account keys list — do not print/commit this)"
