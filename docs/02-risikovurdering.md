# 02 – Risikovurdering

Her går jeg gjennom de største risikoene i Azure-miljøet til Fjellvik Helse AS. Funnene kommer fra statusrapporten (`scripts/03-statusrapport.py`) og fra gjennomgangen av tilganger i Entra ID.

## Slik har jeg vurdert

Hver risiko får en score for **sannsynlighet** og **konsekvens** fra 1 til 5. Risikoen er de to ganget sammen.

| Score | Nivå | Hva det betyr |
|---|---|---|
| 20–25 | **Kritisk** | Må fikses nå |
| 12–19 | **Høy** | Fikses innen 30 dager |
| 6–11 | **Middels** | Fikses innen 90 dager |
| 1–5 | **Lav** | Kan aksepteres eller tas senere |

Konsekvens er vurdert ut fra at bedriften behandler helseopplysninger. Et brudd på konfidensialitet er derfor det verste som kan skje, både for pasientene, kundene og bedriftens rykte. Et slikt brudd må også meldes til Datatilsynet innen 72 timer.

## Risikoene

| # | Risiko | S | K | Score | Nivå |
|---|---|---|---|---|---|
| R1 | Innlogging uten MFA | 5 | 5 | 25 | **Kritisk** |
| R2 | Pasientvedlegg kan leses fra internett | 4 | 5 | 20 | **Kritisk** |
| R3 | Tidligere ansatt har fortsatt full tilgang | 4 | 5 | 20 | **Kritisk** |
| R4 | Hele IT-avdelingen er Owner på abonnementet | 3 | 5 | 15 | **Høy** |
| R5 | For mange Global Administrator | 3 | 5 | 15 | **Høy** |
| R6 | Eksterne konsulenter har tilgang til alt | 3 | 5 | 15 | **Høy** |
| R7 | Tjenestekonto med passord og bred tilgang | 3 | 4 | 12 | **Høy** |
| R8 | Aktivitetsloggen tas ikke vare på | 3 | 3 | 9 | Middels |
| R9 | Kundestøtte har unødvendig tilgang | 2 | 3 | 6 | Middels |

## Risikomatrise

| Sannsynlighet ↓ / Konsekvens → | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| **5** | | | | | R1 |
| **4** | | | | | R2, R3 |
| **3** | | | R8 | R7 | R4, R5, R6 |
| **2** | | | R9 | | |
| **1** | | | | | |

---

## R1 – Innlogging uten MFA

**Hva vi fant:** Security defaults er skrudd av, og det finnes ingen andre regler som krever MFA. Et passord er alt som trengs for å logge inn.

**Hvorfor det er alvorlig:** Passordangrep (password spraying og lekkede passord) er en av de vanligste måtene angripere kommer seg inn i skytjenester på. Det gjelder også kontoene som er Global Administrator. Blir en av dem tatt over, har angriperen full kontroll over hele bedriften i Azure.

**Tiltak:** Slå på security defaults med en gang. Det er gratis og tar to minutter. Når bedriften får Entra ID P1, bør dette byttes ut med Conditional Access, som gir mer kontroll.

**Krav:** ISO 27001 8.5 · NSM 2.6 · CIS (Identity)

## R2 – Pasientvedlegg kan leses fra internett

**Hva vi fant:** Lagringskontoen tillater offentlig tilgang, og containeren `pasientvedlegg` er satt til offentlig lesing. Alle som kjenner eller gjetter adressen kan laste ned filene. Lagringskontoen kan også nås fra hele internett og bruker kontonøkler i stedet for Entra ID.

**Hvorfor det er alvorlig:** Dette er helseopplysninger, som er særlig beskyttet etter GDPR. Åpne lagringskontoer blir aktivt lett etter av automatiserte verktøy. En lekkasje her må meldes til Datatilsynet, og kan føre til bøter og at kunder sier opp avtalen.

**Tiltak:** Skru av offentlig tilgang på hele lagringskontoen, ikke bare containeren. Slå på soft delete, så slettede filer kan hentes tilbake. På sikt: privat nettverkstilgang og innlogging med Entra ID i stedet for nøkler.

**Krav:** ISO 27001 8.3, 8.9 · NSM 2.3, 2.7 · CIS (Storage) · GDPR art. 32

## R3 – Tidligere ansatt har fortsatt full tilgang

**Hva vi fant:** Per Olsen sluttet 30.11.2025, men kontoen hans er fortsatt aktiv. Han har Owner på abonnementet og er Global Administrator.

**Hvorfor det er alvorlig:** En misfornøyd tidligere ansatt, eller noen som har fått tak i passordet hans, kan gjøre hva som helst i miljøet. Ingen følger med på kontoen, så misbruk vil trolig ikke bli oppdaget.

**Tiltak:** Steng kontoen og fjern alle tilganger nå. Lag en fast rutine der HR sier fra til IT samme dag noen slutter, og der IT stenger kontoen på siste arbeidsdag.

**Krav:** ISO 27001 6.5, 5.18 · NSM 1.3, 2.6

## R4 – Hele IT-avdelingen er Owner på abonnementet

**Hva vi fant:** Gruppen `grp-it-utvikling` har Owner på hele abonnementet. Det gir fem personer full kontroll, inkludert retten til å gi andre tilgang.

**Hvorfor det er alvorlig:** Jo flere som har de høyeste rettighetene, jo flere kontoer kan en angriper bruke for å ta over alt. Det er også lettere å gjøre feil ved et uhell, som å slette produksjonsdata.

**Tiltak:** Gi IT-gruppen Contributor på ressursgruppene de faktisk jobber i. Owner bør bare ligge på én eller to navngitte admin-kontoer.

**Krav:** ISO 27001 8.2, 5.15 · NSM 2.6 · CIS (Identity)

## R5 – For mange Global Administrator

**Hva vi fant:** Fire kontoer er Global Administrator, inkludert den tidligere ansatte.

**Hvorfor det er alvorlig:** Global Administrator er den mektigste rollen i Entra ID. Microsoft anbefaler færre enn fem, og for en bedrift med to IT-ansatte holder det med to: IT-sjefen og en nødkonto.

**Tiltak:** Behold Lars Berg (IT-sjef) og admin-kontoen. Fjern rollen fra de andre og gi dem mer avgrensede roller ved behov. Med Entra ID P2 kan rollen gjøres midlertidig med Privileged Identity Management (PIM).

**Krav:** ISO 27001 8.2 · NSM 2.6 · CIS (Identity)

## R6 – Eksterne konsulenter har tilgang til alt

**Hva vi fant:** De to eksterne konsulentene har Contributor på hele abonnementet, også produksjon. Ingen hadde oversikt over dette.

**Hvorfor det er alvorlig:** Bedriften har ingen kontroll på hvordan konsulentfirmaet sikrer sine egne kontoer. Blir de angrepet, kan angriperen gå videre inn hos Fjellvik Helse. Konsulentene trenger heller ikke tilgang til produksjon for å gjøre jobben sin.

**Tiltak:** Gi dem Contributor bare på utviklingsmiljøet (`rg-fjellvik-dev`). Sett en sluttdato på tilgangen og gå gjennom den hvert kvartal. Skriv sikkerhetskrav inn i avtalen med konsulentfirmaet.

**Krav:** ISO 27001 5.19, 5.15 · NSM 2.6

## R7 – Tjenestekonto med passord og bred tilgang

**Hva vi fant:** `svc-backup` er en vanlig brukerkonto der passordet aldri utløper. Den har Contributor på hele abonnementet, men brukes bare til backup av lagringskontoen.

**Hvorfor det er alvorlig:** Passordet ligger trolig i et script eller en konfigurasjonsfil. Tjenestekontoer kan ikke bruke MFA, så et lekket passord gir direkte tilgang til hele abonnementet.

**Tiltak:** Fjern Contributor og gi kontoen bare tilgang til lagringskontoen. På sikt bør den byttes ut med en managed identity, som ikke har noe passord i det hele tatt.

**Krav:** ISO 27001 5.17, 8.2 · NSM 2.6

## R8 – Aktivitetsloggen tas ikke vare på

**Hva vi fant:** Aktivitetsloggen sendes ikke videre noe sted og slettes automatisk etter 90 dager.

**Hvorfor det er alvorlig:** Skjer det en hendelse, er det ofte uker før noen oppdager den. Da kan sporene allerede være borte, og bedriften klarer ikke å finne ut hva som skjedde eller hvilke data som ble berørt.

**Tiltak:** Send aktivitetsloggen til et Log Analytics-arbeidsområde. Neste steg er varsler på viktige hendelser, som nye Owner-tildelinger.

**Krav:** ISO 27001 8.15 · NSM 3.2 · CIS (Logging)

## R9 – Kundestøtte har unødvendig tilgang

**Hva vi fant:** Gruppen `grp-kundestotte` har Reader på hele abonnementet.

**Hvorfor det er alvorlig:** Kundestøtte trenger ikke tilgang til Azure for å gjøre jobben sin. Lesetilgang gir likevel innsyn i hvordan hele miljøet er satt opp, noe en angriper kan bruke til å planlegge et angrep.

**Tiltak:** Fjern tilgangen.

**Krav:** ISO 27001 5.15, 8.3 · NSM 1.3, 2.6

---

## Restrisiko etter tiltakene

Når tiltakene i [rapporten](03-rapport.md) er gjennomført, er de kritiske risikoene borte. Det som gjenstår:

- **R7** står igjen som **middels** til `svc-backup` er byttet ut med en managed identity.
- Uten Entra ID P1/P2 mangler bedriften Conditional Access, PIM og automatiske tilgangsgjennomganger. Det må kompenseres med manuelle rutiner til lisensene er på plass.
- Risikovurderingen bør gjøres på nytt minst én gang i året, og hver gang noe stort endrer seg.
