#!/usr/bin/env bash
# =============================================================================
# 02-ressurser-og-policyer.sh
# Lager et lite "produksjonsmiljø" for Fjellvik Helse AS og kobler
# abonnementet mot CIS og ISO 27001 med Azure Policy.
#
# Kjøres i Azure Cloud Shell (Bash) etter 01-opprett-identiteter.sh.
#
# Bevisst feil:
#   8. Lagringskontoen tillater offentlig tilgang, og containeren med
#      "pasientvedlegg" kan leses av hvem som helst på internett.
#
# Kostnad: Lagringskonto uten data og Azure Policy koster tilnærmet ingenting.
# =============================================================================
set -euo pipefail

LOKASJON="${LOKASJON:-norwayeast}"   # Feiler det? Prøv: LOKASJON=swedencentral bash ...
RG_PROD="rg-fjellvik-prod"
RG_DEV="rg-fjellvik-dev"
SUB_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUB_ID"

# --- Ressursgrupper -----------------------------------------------------------
echo "Lager ressursgrupper i $LOKASJON..."
az group create -n "$RG_PROD" -l "$LOKASJON" --tags miljo=prod eier=it -o none
az group create -n "$RG_DEV"  -l "$LOKASJON" --tags miljo=dev  eier=it -o none

# --- Lagringskonto med svake innstillinger -----------------------------------
STORAGE=$(az storage account list -g "$RG_PROD" --query "[0].name" -o tsv)
if [[ -z "$STORAGE" ]]; then
  STORAGE="fjellvikdata$(openssl rand -hex 3)"
  echo "Lager lagringskonto $STORAGE..."
  az storage account create -n "$STORAGE" -g "$RG_PROD" -l "$LOKASJON" \
    --sku Standard_LRS --kind StorageV2 \
    --allow-blob-public-access true \
    --allow-shared-key-access true \
    --public-network-access Enabled \
    --min-tls-version TLS1_2 \
    --tags data=pasientdata -o none
else
  echo "Lagringskonto finnes: $STORAGE"
fi

KEY=$(az storage account keys list -n "$STORAGE" -g "$RG_PROD" --query "[0].value" -o tsv)
az storage container create -n pasientvedlegg --account-name "$STORAGE" \
  --account-key "$KEY" --public-access blob -o none
echo "  + Container 'pasientvedlegg' med offentlig lesetilgang (bevisst feil)"

# Én fiktiv fil, så funnet blir konkret
echo "Fiktivt testdokument. Ingen ekte pasientdata." > /tmp/test-vedlegg.txt
az storage blob upload --account-name "$STORAGE" --account-key "$KEY" \
  -c pasientvedlegg -n test-vedlegg.txt -f /tmp/test-vedlegg.txt --overwrite -o none
rm -f /tmp/test-vedlegg.txt

# --- Azure Policy: koble abonnementet mot rammeverkene -----------------------
tildel_initiativ() {
  # $1 søketekst i navnet  $2 navn på tildelingen
  local def visningsnavn
  def=$(az policy set-definition list \
    --query "sort_by([?policyType=='BuiltIn' && contains(displayName, '$1')], &displayName)[-1].name" -o tsv)
  visningsnavn=$(az policy set-definition show -n "$def" --query displayName -o tsv)
  if az policy assignment show -n "$2" --scope "$SCOPE" -o none 2>/dev/null; then
    echo "  = Finnes: $visningsnavn"
  else
    az policy assignment create -n "$2" --display-name "$visningsnavn" \
      --policy-set-definition "$def" --scope "$SCOPE" \
      --mi-system-assigned --location "$LOKASJON" -o none
    echo "  + Tildelt: $visningsnavn"
  fi
}

echo; echo "Kobler abonnementet mot rammeverk i Azure Policy..."
tildel_initiativ "CIS Microsoft Azure Foundations Benchmark" "cis-azure"
tildel_initiativ "ISO 27001" "iso-27001"

echo; echo "Starter en compliance-skanning (tar ofte 15 til 30 minutter)..."
az policy state trigger-scan --no-wait

echo
echo "Ferdig! Vent til skanningen er ferdig og kjør så:"
echo "  python3 scripts/03-statusrapport.py   (fra azure-grc-lab-mappen)"
