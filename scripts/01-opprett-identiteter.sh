#!/usr/bin/env bash
# =============================================================================
# 01-opprett-identiteter.sh
# Setter opp brukere, grupper og tilganger for den fiktive bedriften
# Fjellvik Helse AS i Microsoft Entra ID og Azure-abonnementet.
#
# Kjøres i Azure Cloud Shell (Bash), innlogget som admin i LAB-tenanten.
#
# NB: Miljøet har BEVISSTE sikkerhetsfeil som skal finnes og rettes senere
# i prosjektet. Ikke bruk dette oppsettet i et ekte miljø.
#
# Bevisste feil (det IT-teamet gjorde "for å spare tid"):
#   1. Hele IT-gruppen har Owner på abonnementet
#   2. Tre personer er Global Administrator
#   3. En tidligere ansatt (sluttet i fjor) har fortsatt aktiv konto og Owner
#   4. En tjenestekonto med passord som aldri utløper og Contributor-rolle
#   5. Eksterne konsulenter (gjester) har Contributor på hele abonnementet
#   6. Kundestøtte har lesetilgang til hele abonnementet
# =============================================================================
set -euo pipefail

GRAPH="https://graph.microsoft.com/v1.0"
GLOBAL_ADMIN_ROLE="62e90394-69f5-4237-9190-012177145e10"  # Global Administrator

# --- Sikkerhetssjekk: riktig tenant? -----------------------------------------
TENANT_ID=$(az account show --query tenantId -o tsv)
SUB_ID=$(az account show --query id -o tsv)
SUB_NAME=$(az account show --query name -o tsv)
DOMAIN=$(az rest --method get --url "$GRAPH/domains" \
  --query "value[?isDefault].id | [0]" -o tsv)

echo "Tenant:      $TENANT_ID"
echo "Domene:      $DOMAIN"
echo "Abonnement:  $SUB_NAME ($SUB_ID)"

if [[ "$DOMAIN" == *kristiania* ]]; then
  echo "STOPP: Dette ser ut som skolens tenant. Bruk din egen lab-tenant." >&2
  exit 1
fi

read -r -p "Er dette din egen lab-tenant? Skriv 'ja' for å fortsette: " SVAR
[[ "$SVAR" == "ja" ]] || { echo "Avbrutt."; exit 1; }

# --- Hjelpefunksjoner ---------------------------------------------------------
nytt_passord() {
  # Tilfeldig passord. Testbrukerne skal aldri logge inn, så det lagres ikke.
  echo "$(openssl rand -base64 18 | tr -d '/+=')Aa1!"
}

opprett_bruker() {
  # $1 fornavn.etternavn  $2 visningsnavn  $3 avdeling  $4 stilling  $5 passordpolicy
  local upn="$1@$DOMAIN" id
  id=$(az rest --method get --url "$GRAPH/users/$upn" --query id -o tsv 2>/dev/null || true)
  if [[ -z "$id" ]]; then
    local body
    body=$(cat <<JSON
{
  "accountEnabled": true,
  "displayName": "$2",
  "mailNickname": "$1",
  "userPrincipalName": "$upn",
  "department": "$3",
  "jobTitle": "$4",
  "companyName": "Fjellvik Helse AS",
  "usageLocation": "NO",
  "passwordPolicies": "${5:-None}",
  "passwordProfile": {
    "forceChangePasswordNextSignIn": false,
    "password": "$(nytt_passord)"
  }
}
JSON
)
    id=$(az rest --method post --url "$GRAPH/users" \
      --headers "Content-Type=application/json" --body "$body" --query id -o tsv)
    echo "  + Bruker: $2" >&2
  else
    echo "  = Finnes: $2" >&2
  fi
  echo "$id"
}

opprett_gruppe() {
  # $1 navn  $2 beskrivelse
  local id
  id=$(az rest --method get \
    --url "$GRAPH/groups?\$filter=displayName eq '$1'" --query "value[0].id" -o tsv)
  if [[ -z "$id" || "$id" == "None" ]]; then
    id=$(az rest --method post --url "$GRAPH/groups" \
      --headers "Content-Type=application/json" \
      --body "{\"displayName\":\"$1\",\"description\":\"$2\",\"mailEnabled\":false,\"mailNickname\":\"$1\",\"securityEnabled\":true}" \
      --query id -o tsv)
    echo "  + Gruppe: $1" >&2
  else
    echo "  = Finnes: $1" >&2
  fi
  echo "$id"
}

legg_til_medlem() {
  # $1 gruppe-ID  $2 bruker-ID
  az rest --method post --url "$GRAPH/groups/$1/members/\$ref" \
    --headers "Content-Type=application/json" \
    --body "{\"@odata.id\":\"$GRAPH/directoryObjects/$2\"}" >/dev/null 2>&1 || true
}

inviter_gjest() {
  # $1 e-post  $2 visningsnavn
  local id
  id=$(az rest --method get \
    --url "$GRAPH/users?\$filter=mail eq '$1'" --query "value[0].id" -o tsv)
  if [[ -z "$id" || "$id" == "None" ]]; then
    id=$(az rest --method post --url "$GRAPH/invitations" \
      --headers "Content-Type=application/json" \
      --body "{\"invitedUserEmailAddress\":\"$1\",\"invitedUserDisplayName\":\"$2\",\"inviteRedirectUrl\":\"https://myapps.microsoft.com\",\"sendInvitationMessage\":false}" \
      --query invitedUser.id -o tsv)
    echo "  + Gjest: $2" >&2
  else
    echo "  = Finnes: $2" >&2
  fi
  echo "$id"
}

gi_azure_rolle() {
  # $1 objekt-ID  $2 type (User/Group)  $3 rolle
  local feil
  if feil=$(az role assignment create --assignee-object-id "$1" --assignee-principal-type "$2" \
      --role "$3" --scope "/subscriptions/$SUB_ID" -o none 2>&1); then
    echo "  + $3 på abonnementet"
  elif [[ "$feil" == *RoleAssignmentExists* || "$feil" == *"already exists"* ]]; then
    echo "  = $3 finnes allerede"
  else
    echo "  ! Feilet: $feil" >&2
  fi
}

gi_global_admin() {
  # $1 bruker-ID
  local feil
  if feil=$(az rest --method post --url "$GRAPH/roleManagement/directory/roleAssignments" \
      --headers "Content-Type=application/json" \
      --body "{\"principalId\":\"$1\",\"roleDefinitionId\":\"$GLOBAL_ADMIN_ROLE\",\"directoryScopeId\":\"/\"}" \
      -o none 2>&1); then
    echo "  + Global Administrator"
  elif [[ "$feil" == *"already exist"* || "$feil" == *Conflict* ]]; then
    echo "  = Global Administrator finnes allerede"
  else
    echo "  ! Feilet: $feil" >&2
  fi
}

# --- Grupper ------------------------------------------------------------------
echo; echo "Oppretter grupper..."
G_LEDELSE=$(opprett_gruppe "grp-ledelse" "Ledelsen")
G_IT=$(opprett_gruppe "grp-it-utvikling" "IT og utvikling")
G_KUNDE=$(opprett_gruppe "grp-kundestotte" "Kundestøtte")
G_SALG=$(opprett_gruppe "grp-salg-marked" "Salg og markedsføring")
G_OKHR=$(opprett_gruppe "grp-okonomi-hr" "Økonomi og HR")

# --- Brukere (alle fiktive) ---------------------------------------------------
echo; echo "Oppretter brukere..."
U_KARI=$(opprett_bruker "kari.nordmann" "Kari Nordmann" "Ledelse" "Daglig leder")
U_OLE=$(opprett_bruker "ole.hansen" "Ole Hansen" "Ledelse" "Økonomisjef")
U_LARS=$(opprett_bruker "lars.berg" "Lars Berg" "IT og utvikling" "IT-sjef")
U_INGRID=$(opprett_bruker "ingrid.lie" "Ingrid Lie" "IT og utvikling" "Utvikler")
U_AHMED=$(opprett_bruker "ahmed.ali" "Ahmed Ali" "IT og utvikling" "Utvikler")
U_SOFIE=$(opprett_bruker "sofie.dahl" "Sofie Dahl" "IT og utvikling" "Driftstekniker")
U_PER=$(opprett_bruker "per.olsen" "Per Olsen" "IT og utvikling" "Driftstekniker")  # sluttet i fjor
U_MARIA=$(opprett_bruker "maria.johansen" "Maria Johansen" "Kundestøtte" "Kundebehandler")
U_JONAS=$(opprett_bruker "jonas.moe" "Jonas Moe" "Kundestøtte" "Kundebehandler")
U_EMMA=$(opprett_bruker "emma.strand" "Emma Strand" "Salg og markedsføring" "Salgssjef")
U_NINA=$(opprett_bruker "nina.bakken" "Nina Bakken" "Økonomi og HR" "HR-rådgiver")
U_SVC=$(opprett_bruker "svc-backup" "svc-backup" "IT og utvikling" "Tjenestekonto" "DisablePasswordExpiration")

# --- Gjester (eksterne konsulenter, fiktive adresser) ------------------------
echo; echo "Inviterer gjester..."
U_GJEST1=$(inviter_gjest "konsulent1@example.com" "Konsulent 1 (ekstern)")
U_GJEST2=$(inviter_gjest "konsulent2@example.com" "Konsulent 2 (ekstern)")

# --- Gruppemedlemskap ---------------------------------------------------------
echo; echo "Legger brukere i grupper..."
for u in "$U_KARI" "$U_OLE"; do legg_til_medlem "$G_LEDELSE" "$u"; done
for u in "$U_LARS" "$U_INGRID" "$U_AHMED" "$U_SOFIE" "$U_PER"; do legg_til_medlem "$G_IT" "$u"; done
for u in "$U_MARIA" "$U_JONAS"; do legg_til_medlem "$G_KUNDE" "$u"; done
legg_til_medlem "$G_SALG" "$U_EMMA"
legg_til_medlem "$G_OKHR" "$U_NINA"

echo; echo "Venter 30 sekunder så Entra ID rekker å replikere..."
sleep 30

# --- Tilganger (her ligger de bevisste feilene) ------------------------------
echo; echo "Gir tilganger i Azure..."
echo "grp-it-utvikling:";  gi_azure_rolle "$G_IT" Group Owner
echo "per.olsen:";         gi_azure_rolle "$U_PER" User Owner
echo "svc-backup:";        gi_azure_rolle "$U_SVC" User Contributor
echo "Konsulent 1:";       gi_azure_rolle "$U_GJEST1" User Contributor
echo "Konsulent 2:";       gi_azure_rolle "$U_GJEST2" User Contributor
echo "grp-kundestotte:";   gi_azure_rolle "$G_KUNDE" Group Reader

echo; echo "Gir Global Administrator..."
for u in "$U_LARS" "$U_INGRID" "$U_PER"; do gi_global_admin "$u"; done

echo
echo "Ferdig! Fjellvik Helse AS er satt opp i $DOMAIN."
echo "Ta skjermbilder av Users, Groups og Access control (IAM) til screenshots/."
