#!/usr/bin/env python3
"""
03-statusrapport.py

Går gjennom Azure-miljøet til Fjellvik Helse AS og lager en statusrapport
i Markdown med funn koblet til CIS, ISO 27001 og NSMs grunnprinsipper.

Kjøres i Azure Cloud Shell:
    python3 azure-grc-lab/scripts/03-statusrapport.py

Rapporten havner i mappen bevis/. Den inneholder ingen tenant-ID-er,
objekt-ID-er eller nøkler, så den kan legges i repoet.

Scriptet bruker bare Azure CLI (az), som allerede finnes i Cloud Shell.
Det leser og endrer ingenting.
"""

import csv
import datetime as dt
import json
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote, urlencode

GRAPH = "https://graph.microsoft.com/v1.0"
GLOBAL_ADMIN_ROLE = "62e90394-69f5-4237-9190-012177145e10"
REPO = Path(__file__).resolve().parent.parent

# Bedriftens egne krav (fra docs/01-virksomhet.md og risikovurderingen)
MAKS_GLOBAL_ADMIN = 2
MAKS_OWNER = 2


# --- Hjelpefunksjoner ---------------------------------------------------------

def az(*args):
    """Kjører en az-kommando og returnerer JSON, eller None hvis den feiler."""
    res = subprocess.run(["az", *args, "-o", "json"], capture_output=True, text=True)
    if res.returncode != 0:
        return None
    try:
        return json.loads(res.stdout) if res.stdout.strip() else {}
    except json.JSONDecodeError:
        return None


def graph(path, **params):
    """GET mot Microsoft Graph, med paging. Returnerer liste, dict eller None."""
    url = f"{GRAPH}/{path}"
    if params:
        url += "?" + urlencode(params, quote_via=quote, safe="$,'")
    data = az("rest", "--method", "get", "--url", url)
    if data is None:
        return None
    if "value" not in data:
        return data
    items = list(data["value"])
    while data.get("@odata.nextLink"):
        data = az("rest", "--method", "get", "--url", data["@odata.nextLink"])
        if data is None:
            break
        items.extend(data.get("value", []))
    return items


def er_gjest(navn):
    return "#EXT#" in (navn or "")


# --- Sjekkene -----------------------------------------------------------------

class Funn:
    def __init__(self, nr, tittel, alvor, refs):
        self.nr, self.tittel, self.alvor, self.refs = nr, tittel, alvor, refs
        self.status = "UKJENT"
        self.detaljer = []

    def ok(self, *tekst):
        self.status = "OK"
        self.detaljer += tekst

    def avvik(self, *tekst):
        self.status = "AVVIK"
        self.detaljer += tekst

    def ukjent(self, *tekst):
        self.status = "UKJENT"
        self.detaljer += tekst


def hent_data():
    konto = az("account", "show")
    if not konto:
        sys.exit("Fant ikke Azure-konto. Er du logget inn i Cloud Shell?")
    sub_id = konto["id"]
    scope = f"/subscriptions/{sub_id}"

    domener = graph("domains") or []
    domene = next((d["id"] for d in domener if d.get("isDefault")), "ukjent")

    tildelinger = az("role", "assignment", "list", "--scope", scope) or []
    tildelinger = [t for t in tildelinger if (t.get("scope") or "").lower() == scope.lower()]

    brukere = graph("users", **{
        "$select": "displayName,userPrincipalName,accountEnabled,userType,"
                   "passwordPolicies,department,mail",
        "$top": "999",
    }) or []

    return {
        "sub_navn": konto.get("name", ""),
        "domene": domene,
        "scope": scope,
        "tildelinger": tildelinger,
        "brukere": brukere,
    }


def gruppemedlemmer(gruppe_id):
    medlemmer = graph(f"groups/{gruppe_id}/members", **{"$select": "displayName,userPrincipalName"})
    return medlemmer or []


def sjekk_mfa():
    f = Funn(1, "MFA er påkrevd for alle brukere", "Kritisk",
             "CIS: Identity · ISO 27001: 8.5 · NSM: 2.6")
    sd = graph("policies/identitySecurityDefaultsEnforcementPolicy")
    if sd is None:
        f.ukjent("Fikk ikke lest innstillingen for security defaults. Sjekk manuelt i portalen.")
        return f
    if sd.get("isEnabled"):
        f.ok("Security defaults er på. Alle må registrere og bruke MFA.")
        return f
    ca = graph("identity/conditionalAccess/policies")
    mfa_regler = [p for p in (ca or []) if p.get("state") == "enabled"
                  and "mfa" in json.dumps(p.get("grantControls") or {}).lower()]
    if mfa_regler:
        f.ok(f"Security defaults er av, men {len(mfa_regler)} Conditional Access-regel(er) krever MFA.")
    else:
        f.avvik("Security defaults er av, og ingen Conditional Access-regler krever MFA.",
                "Det betyr at et lekket passord er nok til å logge inn.")
    return f


def sjekk_global_admin():
    f = Funn(2, f"Maks {MAKS_GLOBAL_ADMIN} Global Administrator", "Høy",
             "CIS: Identity · ISO 27001: 8.2 · NSM: 2.6")
    tild = graph("roleManagement/directory/roleAssignments", **{
        "$filter": f"roleDefinitionId eq '{GLOBAL_ADMIN_ROLE}'",
        "$expand": "principal",
    })
    if tild is None:
        f.ukjent("Fikk ikke lest rolletildelinger i Entra ID.")
        return f
    navn = sorted((t.get("principal") or {}).get("displayName", "?") for t in tild)
    tekst = f"{len(navn)} har Global Administrator: {', '.join(navn)}."
    (f.ok if len(navn) <= MAKS_GLOBAL_ADMIN else f.avvik)(tekst)
    return f


def sjekk_owner(data):
    f = Funn(3, f"Maks {MAKS_OWNER} personer med Owner på abonnementet", "Høy",
             "CIS: Identity · ISO 27001: 8.2, 5.15 · NSM: 2.6")
    personer = set()
    linjer = []
    for t in data["tildelinger"]:
        if t.get("roleDefinitionName") != "Owner":
            continue
        if t.get("principalType") == "Group":
            medl = gruppemedlemmer(t["principalId"])
            personer.update(m.get("displayName", "?") for m in medl)
            linjer.append(f"Gruppen {t.get('principalName')} ({len(medl)} medlemmer)")
        else:
            personer.add(t.get("principalName", "?"))
            linjer.append(t.get("principalName", "?"))
    tekst = f"{len(personer)} personer har Owner. Tildelt til: {'; '.join(linjer) or 'ingen'}."
    (f.ok if len(personer) <= MAKS_OWNER else f.avvik)(tekst)
    return f


def sjekk_sluttede(data):
    f = Funn(4, "Sluttede ansatte har ikke aktive kontoer", "Kritisk",
             "ISO 27001: 6.5, 5.18 · NSM: 1.3, 2.6")
    fil = REPO / "data" / "sluttede-ansatte.csv"
    if not fil.exists():
        f.ukjent("Fant ikke data/sluttede-ansatte.csv.")
        return f
    with fil.open(encoding="utf-8") as fh:
        sluttede = {r["brukernavn"].strip().lower(): r for r in csv.DictReader(fh)}
    aktive = [b for b in data["brukere"]
              if b.get("accountEnabled")
              and (b.get("userPrincipalName") or "").split("@")[0].lower() in sluttede]
    if aktive:
        for b in aktive:
            bnavn = b["userPrincipalName"].split("@")[0].lower()
            roller = [t["roleDefinitionName"] for t in data["tildelinger"]
                      if (t.get("principalName") or "").lower() == b["userPrincipalName"].lower()]
            dato = dt.date.fromisoformat(sluttede[bnavn]["siste_arbeidsdag"]).strftime("%d.%m.%Y")
            f.avvik(f"{b['displayName']} sluttet {dato}, "
                    f"men kontoen er aktiv. Roller på abonnementet: {', '.join(roller) or 'ingen'}.")
    else:
        f.ok("Ingen sluttede ansatte har aktive kontoer.")
    return f


def sjekk_gjester(data):
    f = Funn(5, "Eksterne har ikke brede tilganger på abonnementet", "Høy",
             "ISO 27001: 5.19, 5.15 · NSM: 2.6")
    gjester = [t for t in data["tildelinger"] if er_gjest(t.get("principalName"))]
    brede = [t for t in gjester if t.get("roleDefinitionName") in ("Owner", "Contributor")]
    if brede:
        for t in brede:
            navn = t["principalName"].split("#EXT#")[0]
            f.avvik(f"Gjestekontoen {navn} har {t['roleDefinitionName']} på hele abonnementet.")
    else:
        f.ok("Ingen gjester har Owner eller Contributor på abonnementsnivå.")
    return f


def sjekk_tjenestekontoer(data):
    f = Funn(6, "Tjenestekontoer er ikke vanlige brukere med passord", "Middels",
             "ISO 27001: 5.17, 8.2 · NSM: 2.6")
    svc = [b for b in data["brukere"]
           if (b.get("userPrincipalName") or "").lower().startswith("svc")
           and b.get("accountEnabled")]
    if not svc:
        f.ok("Fant ingen aktive tjenestekontoer som er vanlige brukerkontoer.")
        return f
    for b in svc:
        roller = [t["roleDefinitionName"] for t in data["tildelinger"]
                  if (t.get("principalName") or "").lower() == b["userPrincipalName"].lower()]
        utloper = ("der passordet aldri utløper" if "DisablePasswordExpiration" in (b.get("passwordPolicies") or "")
                   else "med passord")
        f.avvik(f"{b['displayName']} er en vanlig brukerkonto {utloper}. "
                f"Roller på abonnementet: {', '.join(roller) or 'ingen'}.")
    return f


def sjekk_unodvendig_tilgang(data):
    f = Funn(7, "Bare IT har tilgang på abonnementsnivå", "Middels",
             "ISO 27001: 5.15, 8.3 · NSM: 1.3, 2.6")
    avd = {(b.get("userPrincipalName") or "").lower(): b.get("department") or "" for b in data["brukere"]}
    utenfor = []
    for t in data["tildelinger"]:
        navn = t.get("principalName") or ""
        if er_gjest(navn):
            continue  # dekkes av sjekk 5
        if t.get("principalType") == "Group":
            if "it" not in navn.lower().split("-"):
                utenfor.append(f"Gruppen {navn} har {t['roleDefinitionName']}")
        elif t.get("principalType") == "User":
            d = avd.get(navn.lower(), "")
            if d and "IT" not in d:
                utenfor.append(f"{navn} ({d}) har {t['roleDefinitionName']}")
    if utenfor:
        f.avvik(*utenfor)
    else:
        f.ok("Ingen utenfor IT har tilgang på abonnementsnivå.")
    return f


def sjekk_lagring():
    f = Funn(8, "Lagringskontoer er ikke åpne for internett", "Kritisk",
             "CIS: Storage · ISO 27001: 8.3, 8.9 · NSM: 2.3, 2.7 · GDPR art. 32")
    kontoer = az("storage", "account", "list")
    if kontoer is None:
        f.ukjent("Fikk ikke listet lagringskontoer.")
        return f
    if not kontoer:
        f.ok("Ingen lagringskontoer i abonnementet.")
        return f
    alt_ok = True
    for k in kontoer:
        navn = k["name"]
        if k.get("allowBlobPublicAccess"):
            alt_ok = False
            nokler = az("storage", "account", "keys", "list", "-n", navn,
                        "-g", k["resourceGroup"]) or []
            apne = []
            if nokler:
                cont = az("storage", "container", "list", "--account-name", navn,
                          "--account-key", nokler[0]["value"]) or []
                apne = [c["name"] for c in cont
                        if (c.get("properties") or {}).get("publicAccess")]
            f.avvik(f"{navn} tillater offentlig tilgang."
                    + (f" Åpne containere: {', '.join(apne)}." if apne else ""))
        if k.get("allowSharedKeyAccess", True) is not False:
            f.detaljer.append(f"{navn} tillater tilgang med kontonøkler (bør bruke Entra ID).")
        if (k.get("publicNetworkAccess") or "Enabled") == "Enabled" and not (k.get("networkRuleSet") or {}).get("ipRules"):
            f.detaljer.append(f"{navn} kan nås fra hele internett (ingen nettverksbegrensning).")
    if alt_ok:
        f.status = "OK"
        f.detaljer.insert(0, "Ingen lagringskontoer tillater offentlig tilgang til data.")
    return f


def sjekk_logging(data):
    f = Funn(9, "Aktivitetslogg sendes til et sted den tas vare på", "Middels",
             "CIS: Logging · ISO 27001: 8.15 · NSM: 3.2")
    diag = az("monitor", "diagnostic-settings", "subscription", "list")
    if diag is None:
        f.ukjent("Fikk ikke lest diagnoseinnstillinger.")
        return f
    liste = diag.get("value", diag) if isinstance(diag, dict) else diag
    if liste:
        f.ok(f"{len(liste)} diagnoseinnstilling(er) sender aktivitetsloggen videre.")
    else:
        f.avvik("Aktivitetsloggen sendes ikke noe sted. Den slettes automatisk etter 90 dager.")
    return f


def policy_status():
    linjer = []
    oppsum = az("policy", "state", "summarize")
    if not oppsum:
        return ["Fant ingen resultater fra Azure Policy ennå. Vent på skanningen og kjør igjen."]
    for a in oppsum.get("policyAssignments", []):
        navn = a.get("policyAssignmentId", "").split("/")[-1]
        res = a.get("results", {})
        detaljer = {d["complianceState"]: d["count"] for d in res.get("resourceDetails", [])}
        ok, ikke = detaljer.get("compliant", 0), detaljer.get("noncompliant", 0)
        prosent = f"{100 * ok / (ok + ikke):.0f} %" if ok + ikke else "ingen data"
        linjer.append(f"| {navn} | {prosent} | {ikke} | {res.get('nonCompliantPolicies', 0)} |")
    return linjer


def secure_score():
    scores = az("security", "secure-scores", "list")
    if not scores:
        return "Ikke tilgjengelig"
    s = scores[0]
    score = s.get("score") or s.get("properties", {}).get("score") or {}
    if "percentage" in score:
        return f"{score['percentage'] * 100:.0f} %"
    if score.get("max"):
        return f"{100 * score['current'] / score['max']:.0f} %"
    return "Ikke tilgjengelig"


# --- Rapporten ----------------------------------------------------------------

def lag_rapport(data, funn):
    na = dt.datetime.now()
    avvik = [f for f in funn if f.status == "AVVIK"]
    ikon = {"OK": "✅", "AVVIK": "❌", "UKJENT": "⚠️"}

    ut = [
        f"# Statusrapport, {na:%d.%m.%Y kl. %H:%M}",
        "",
        f"**Miljø:** {data['domene']} · **Abonnement:** {data['sub_navn']}",
        "",
        f"**{len(avvik)} av {len(funn)} kontroller har avvik.** "
        f"Kritiske avvik: {sum(1 for f in avvik if f.alvor == 'Kritisk')}.",
        "",
        "## Oversikt",
        "",
        "| # | Kontroll | Alvor | Status |",
        "|---|---|---|---|",
    ]
    for f in funn:
        ut.append(f"| {f.nr} | {f.tittel} | {f.alvor} | {ikon[f.status]} {f.status} |")

    ut += ["", "## Detaljer", ""]
    for f in funn:
        ut += [f"### {f.nr}. {f.tittel}", "",
               f"**Status:** {ikon[f.status]} {f.status} · **Alvor:** {f.alvor} · **Krav:** {f.refs}", ""]
        ut += [f"- {d}" for d in f.detaljer] + [""]

    ut += ["## Azure Policy og Defender for Cloud", "",
           f"**Secure score:** {secure_score()}", "",
           "| Tildeling | Etterlevelse | Ressurser med avvik | Policyer med avvik |",
           "|---|---|---|---|"]
    ut += policy_status()
    ut += ["", "---", "*Laget automatisk av scripts/03-statusrapport.py*", ""]
    return "\n".join(ut), na


def main():
    print("Henter data fra Azure og Entra ID...")
    data = hent_data()
    funn = [
        sjekk_mfa(),
        sjekk_global_admin(),
        sjekk_owner(data),
        sjekk_sluttede(data),
        sjekk_gjester(data),
        sjekk_tjenestekontoer(data),
        sjekk_unodvendig_tilgang(data),
        sjekk_lagring(),
        sjekk_logging(data),
    ]
    tekst, na = lag_rapport(data, funn)

    mappe = REPO / "bevis"
    mappe.mkdir(exist_ok=True)
    fil = mappe / f"statusrapport-{na:%Y-%m-%d-%H%M}.md"
    fil.write_text(tekst, encoding="utf-8")

    print()
    for f in funn:
        print(f"  {f.status:7} {f.nr}. {f.tittel}")
    print(f"\nRapporten er lagret i {fil}")


if __name__ == "__main__":
    main()
