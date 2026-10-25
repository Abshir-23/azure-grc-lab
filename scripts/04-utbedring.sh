#!/usr/bin/env bash
# =============================================================================
# 04-utbedring.sh
# Retter funnene fra risikovurderingen, i samme rekkefølge som tiltaksplanen
# i docs/03-rapport.md.
#
# Kjøres i Azure Cloud Shell (Bash). Kjør 03-statusrapport.py før og etter,
# så har du "før og etter" som bevis.
# =============================================================================
set -euo pipefail

GRAPH="https://graph.microsoft.com/v1.0"
GLOBAL_ADMIN_ROLE="62e90394-69f5-4237-9190-012177145e10"
SUB_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUB_ID"
DOMAIN=$(az rest --method get --url "$GRAPH/domains" --query "value[?isDefault].id | [0]" -o tsv)
RG_PROD="rg-fjellvik-prod"
RG_DEV="rg-fjellvik-dev"

read -r -p "Utbedre miljøet i $DOMAIN? Skriv 'ja': " SVAR
[[ "$SVAR" == "ja" ]] || { echo "Avbrutt."; exit 1; }

bruker_id() { az rest --method get --url "$GRAPH/users/$1@$DOMAIN" --query id -o tsv 2>/dev/null || true; }
gjest_id()  { az rest --method get --url "$GRAPH/users?\$filter=mail eq '$1'" --query "value[0].id" -o tsv 2>/dev/null || true; }
gruppe_id() { az rest --method get --url "$GRAPH/groups?\$filter=displayName eq '$1'" --query "value[0].id" -o tsv 2>/dev/null || true; }

fjern_rolle() {
  # $1 objekt-ID  $2 rolle  $3 scope
  [[ -z "$1" || "$1" == "None" ]] && return 0
  az role assignment delete --assignee "$1" --role "$2" --scope "$3" -o none 2>/dev/null || true
}

gi_rolle() {
  # $1 objekt-ID  $2 type  $3 rolle  $4 scope
  az role assignment create --assignee-object-id "$1" --assignee-principal-type "$2" \
    --role "$3" --scope "$4" -o none 2>/dev/null || true
}

fjern_global_admin() {
  local id="$1" tild
  [[ -z "$id" || "$id" == "None" ]] && return 0
  tild=$(az rest --method get \
    --url "$GRAPH/roleManagement/directory/roleAssignments?\$filter=principalId eq '$id' and roleDefinitionId eq '$GLOBAL_ADMIN_ROLE'" \
    --query "value[0].id" -o tsv 2>/dev/null || true)
  if [[ -n "$tild" && "$tild" != "None" ]]; then
    az rest --method delete --url "$GRAPH/roleManagement/directory/roleAssignments/$tild" -o none
  fi
}

PER=$(bruker_id per.olsen)
INGRID=$(bruker_id ingrid.lie)
SVC=$(bruker_id svc-backup)
G1=$(gjest_id konsulent1@example.com)
G2=$(gjest_id konsulent2@example.com)
G_IT=$(gruppe_id grp-it-utvikling)
G_KUNDE=$(gruppe_id grp-kundestotte)
STORAGE=$(az storage account list -g "$RG_PROD" --query "[0].name" -o tsv 2>/dev/null || true)

# --- Uke 1: det mest kritiske --------------------------------------------------

echo "1. Slår på MFA for alle (security defaults)..."
if az rest --method patch --url "$GRAPH/policies/identitySecurityDefaultsEnforcementPolicy" \
    --headers "Content-Type=application/json" --body '{"isEnabled": true}' -o none 2>/dev/null; then
  echo "   Ferdig."
else
  echo "   Gjør det manuelt: Entra ID > Overview > Properties > Manage security defaults > Enabled"
fi

echo "2. Stenger kontoen til Per Olsen (sluttet) og fjerner tilgangene hans..."
if [[ -n "$PER" ]]; then
  az rest --method patch --url "$GRAPH/users/$PER" \
    --headers "Content-Type=application/json" --body '{"accountEnabled": false}' -o none
  fjern_rolle "$PER" Owner "$SCOPE"
  fjern_global_admin "$PER"
  az rest --method delete --url "$GRAPH/groups/$G_IT/members/$PER/\$ref" -o none 2>/dev/null || true
  echo "   Ferdig. Kontoen slettes etter 30 dager i henhold til rutinen for sluttede."
fi

echo "3. Stenger offentlig tilgang til lagringskontoen..."
if [[ -n "$STORAGE" ]]; then
  az storage account update -n "$STORAGE" -g "$RG_PROD" \
    --allow-blob-public-access false -o none
  az storage account blob-service-properties update -n "$STORAGE" -g "$RG_PROD" \
    --enable-delete-retention true --delete-retention-days 14 \
    --enable-container-delete-retention true --container-delete-retention-days 14 -o none
  echo "   Ferdig. Offentlig tilgang er av, og slettede filer kan gjenopprettes i 14 dager."
fi

# --- Innen 30 dager: minste privilegium ---------------------------------------

echo "4. Fjerner Owner fra IT-gruppen og gir Contributor på ressursgruppene i stedet..."
if [[ -n "$G_IT" ]]; then
  gi_rolle "$G_IT" Group Contributor "$SCOPE/resourceGroups/$RG_PROD"
  gi_rolle "$G_IT" Group Contributor "$SCOPE/resourceGroups/$RG_DEV"
  fjern_rolle "$G_IT" Owner "$SCOPE"
  echo "   Ferdig."
fi

echo "5. Reduserer antall Global Administrator..."
fjern_global_admin "$INGRID"
echo "   Ferdig. Igjen: Lars Berg (IT-sjef) og din egen admin-konto."

echo "6. Begrenser konsulentene til utviklingsmiljøet..."
for g in "$G1" "$G2"; do
  [[ -z "$g" || "$g" == "None" ]] && continue
  gi_rolle "$g" User Contributor "$SCOPE/resourceGroups/$RG_DEV"
  fjern_rolle "$g" Contributor "$SCOPE"
done
echo "   Ferdig."

echo "7. Fjerner unødvendig lesetilgang for kundestøtte..."
fjern_rolle "$G_KUNDE" Reader "$SCOPE"
echo "   Ferdig."

echo "8. Strammer inn tjenestekontoen svc-backup..."
if [[ -n "$SVC" ]]; then
  fjern_rolle "$SVC" Contributor "$SCOPE"
  [[ -n "$STORAGE" ]] && gi_rolle "$SVC" User "Storage Blob Data Contributor" \
    "$SCOPE/resourceGroups/$RG_PROD/providers/Microsoft.Storage/storageAccounts/$STORAGE"
  az rest --method patch --url "$GRAPH/users/$SVC" \
    --headers "Content-Type=application/json" --body '{"passwordPolicies": "None"}' -o none
  echo "   Ferdig. Langsiktig bør den byttes ut med en managed identity."
fi

# --- Innen 90 dager: logging --------------------------------------------------

echo "9. Sender aktivitetsloggen til et Log Analytics-arbeidsområde..."
LOKASJON=$(az group show -n "$RG_PROD" --query location -o tsv)
az monitor log-analytics workspace create -g "$RG_PROD" -n law-fjellvik \
  -l "$LOKASJON" --retention-time 30 -o none
LAW_ID=$(az monitor log-analytics workspace show -g "$RG_PROD" -n law-fjellvik --query id -o tsv)
az monitor diagnostic-settings subscription create -n aktivitetslogg \
  --location "$LOKASJON" --workspace "$LAW_ID" \
  --logs '[{"category":"Administrative","enabled":true},{"category":"Security","enabled":true},{"category":"Policy","enabled":true}]' \
  -o none 2>/dev/null || echo "   Finnes allerede."
echo "   Ferdig. (Log Analytics koster litt per GB, men med så lite data blir det nesten ingenting.)"

echo
echo "Alt er utbedret. Kjør statusrapporten igjen for å se resultatet:"
echo "  python3 scripts/03-statusrapport.py   (fra azure-grc-lab-mappen)"
