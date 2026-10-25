# 03 – Rapport til ledelsen

**Til:** Ledelsen i Fjellvik Helse AS
**Fra:** Abshir Ahmed Arale
**Tema:** Sikkerheten i Azure etter flyttingen til skyen

---

## Kort fortalt

Dere spurte: *«Hvor står vi, og hva bør vi fikse først?»*

Svaret er at grunnmuren mangler, men at det meste kan rettes raskt og uten store kostnader. Jeg fant **ni avvik**. **Tre av dem er kritiske** og bør fikses denne uken:

1. **Det er nok med et passord for å logge inn.** MFA er ikke påkrevd, heller ikke for administratorene.
2. **Pasientvedlegg kan leses av hvem som helst på internett.** Det er helseopplysninger, og en lekkasje må meldes til Datatilsynet.
3. **En tidligere ansatt har fortsatt full tilgang** til hele miljøet, nesten ett år etter at han sluttet.

Ingen av disse krever nye lisenser eller innkjøp. De tre kan fikses på under en time.

## Hvorfor det har blitt slik

Flyttingen til Azure ble gjort raskt av et lite team med en tidsfrist. Det var et fornuftig valg der og da å få ting til å virke først. Problemet er at de midlertidige løsningene ble permanente. Det er ingen sin feil, men det viser at bedriften mangler faste rutiner for tilganger og sikkerhet.

## Det viktigste: tilgangene

Det meste av det jeg fant handler om **hvem som har tilgang til hva**. I dag har mange folk mye mer tilgang enn de trenger:

| Hvem | Har i dag | Trenger |
|---|---|---|
| Hele IT-avdelingen (5) | Full kontroll over alt | Tilgang til miljøene de jobber i |
| Global Administrator | 4 kontoer | 2 (IT-sjef og en nødkonto) |
| Eksterne konsulenter | Kan endre alt, også produksjon | Bare utviklingsmiljøet |
| Kundestøtte | Kan se hele oppsettet | Ingen tilgang til Azure |
| Per Olsen (sluttet) | Full kontroll | Ingenting |

Jo flere som har full tilgang, jo flere kontoer kan en angriper bruke for å komme inn. Det øker også faren for at noen gjør en alvorlig feil ved et uhell.

## Tiltaksplan

Planen er laget slik at det lille IT-teamet faktisk klarer å gjennomføre den. Det som fjerner mest risiko for minst innsats kommer først.

### Denne uken

| Tiltak | Fjerner risiko | Innsats |
|---|---|---|
| Slå på MFA for alle (security defaults) | R1 | 10 minutter, pluss at alle må registrere MFA |
| Stenge offentlig tilgang til lagringskontoen | R2 | 5 minutter |
| Stenge kontoen til Per Olsen og fjerne tilgangene | R3 | 5 minutter |

### Innen 30 dager

| Tiltak | Fjerner risiko | Innsats |
|---|---|---|
| Gi IT-avdelingen tilgang bare der de jobber | R4 | 1 time |
| Redusere Global Administrator til to | R5 | 30 minutter |
| Begrense konsulentene til utviklingsmiljøet | R6 | 30 minutter |
| Begrense tjenestekontoen til backup | R7 | 30 minutter |
| Fjerne tilgangen til kundestøtte | R9 | 5 minutter |
| Lage rutine for når folk begynner og slutter | R3 | Et møte mellom HR og IT |

### Innen 90 dager

| Tiltak | Fjerner risiko | Innsats |
|---|---|---|
| Ta vare på aktivitetsloggen | R8 | 1 time, liten løpende kostnad |
| Bytte tjenestekontoen ut med en managed identity | R7 | En halv dag for utviklerne |
| Gå gjennom alle tilganger hvert kvartal | Alle | 1 time per kvartal |
| Vurdere Entra ID P1 eller P2 | R1, R5, R6 | Lisenskostnad per bruker |

Alle tiltakene for de første 30 dagene er også laget som et script (`scripts/04-utbedring.sh`), så de kan gjennomføres likt og dokumenteres.

## Hva Entra ID P1/P2 gir dere

Med gratisversjonen av Entra ID kommer dere langt, men noe krever lisens. Med **P1** får dere Conditional Access, som gir mer kontroll over MFA, for eksempel å kreve det ved innlogging utenfra Norge. Med **P2** får dere i tillegg midlertidig administratortilgang (PIM) og automatiske tilgangsgjennomganger. For en bedrift som behandler helseopplysninger mener jeg dette er verdt å se på når de akutte tiltakene er gjort.

## Resultat etter utbedring

Statusrapporten kjøres før og etter utbedringsscriptet. Målet er:

| | Før | Mål etter |
|---|---|---|
| Kontroller med avvik | 9 av 9 | 1 av 9 |
| Kritiske avvik | 3 | 0 |

Det eneste som skal stå igjen er tjenestekontoen (R7), til den er byttet ut med en managed identity.

De faktiske statusrapportene fra før og etter, med dato og klokkeslett, ligger i mappen [`bevis/`](../bevis/).

## Videre

Jeg anbefaler å gjøre en ny gjennomgang om tre måneder, når alle tiltakene er på plass. Da kan vi også se på Microsoft 365, som ikke var med denne gangen.

Ta gjerne kontakt hvis noe er uklart.

*Abshir Ahmed Arale*
