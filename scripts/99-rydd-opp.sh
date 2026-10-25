#!/usr/bin/env bash
# =============================================================================
# 99-rydd-opp.sh
# Sletter alt prosjektet har laget, så du ikke bruker opp Azure-kreditten.
# Rører ikke din egen admin-konto.
# =============================================================================
set -uo pipefail

GRAPH="https://graph.microsoft.com/v1.0"
SUB_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUB_ID"
DOMAIN=$(az rest --method get --url "$GRAPH/domains" --query "value[?isDefault].id | [0]" -o tsv)

read -r -p "Slette ALT fra Fjellvik Helse-laben i $DOMAIN? Skriv 'slett': " SVAR
[[ "$SVAR" == "slett" ]] || { echo "Avbrutt."; exit 1; }

echo "Sletter ressursgrupper (tar noen minutter)..."
az group delete -n rg-fjellvik-prod --yes --no-wait 2>/dev/null
az group delete -n rg-fjellvik-dev  --yes --no-wait 2>/dev/null

echo "Sletter policy-tildelinger og aktivitetslogg-innstilling..."
az policy assignment delete -n cis-azure --scope "$SCOPE" 2>/dev/null
az policy assignment delete -n iso-27001 --scope "$SCOPE" 2>/dev/null
az monitor diagnostic-settings subscription delete -n aktivitetslogg --yes 2>/dev/null

slett_objekt() {
  # $1 objekt-ID  $2 navn
  [[ -z "$1" || "$1" == "None" ]] && return 0
  for r in $(az role assignment list --assignee "$1" --all --query "[].id" -o tsv 2>/dev/null); do
    az role assignment delete --ids "$r" 2>/dev/null
  done
  az rest --method delete --url "$GRAPH/directoryObjects/$1" -o none 2>/dev/null && echo "  - $2"
}

echo "Sletter brukere og gjester..."
for u in kari.nordmann ole.hansen lars.berg ingrid.lie ahmed.ali sofie.dahl per.olsen \
         maria.johansen jonas.moe emma.strand nina.bakken svc-backup; do
  id=$(az rest --method get --url "$GRAPH/users/$u@$DOMAIN" --query id -o tsv 2>/dev/null)
  slett_objekt "$id" "$u"
done
for e in konsulent1@example.com konsulent2@example.com; do
  id=$(az rest --method get --url "$GRAPH/users?\$filter=mail eq '$e'" --query "value[0].id" -o tsv 2>/dev/null)
  slett_objekt "$id" "$e"
done

echo "Sletter grupper..."
for g in grp-ledelse grp-it-utvikling grp-kundestotte grp-salg-marked grp-okonomi-hr; do
  id=$(az rest --method get --url "$GRAPH/groups?\$filter=displayName eq '$g'" --query "value[0].id" -o tsv 2>/dev/null)
  slett_objekt "$id" "$g"
done

echo
echo "Ferdig. Husk å slå på security defaults igjen hvis du skrudde dem av:"
echo "  Entra ID > Overview > Properties > Manage security defaults > Enabled"
