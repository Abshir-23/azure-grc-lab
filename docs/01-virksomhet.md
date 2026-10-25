# 01 – Virksomheten

> **Fjellvik Helse AS er en fiktiv bedrift laget for denne laben.** Eventuell likhet med en ekte virksomhet er tilfeldig.

## Om bedriften

| | |
|---|---|
| **Navn** | Fjellvik Helse AS (fiktiv) |
| **Sted** | Oslo |
| **Ansatte** | Rundt 40 |
| **Virksomhet** | Skytjeneste (SaaS) for timebestilling og pasientoppfølging, solgt til fysioterapiklinikker |
| **Kunder** | Rundt 120 klinikker i Norge |
| **IT-ansatte** | To personer, som også tar intern brukerstøtte |

## Organisering

| Avdeling | Ansatte | Typisk tilgangsbehov |
|---|---|---|
| Ledelse | 4 | Rapporter, økonomi, strategidokumenter |
| IT og utvikling | 10 | Azure-abonnementet, kildekode, produksjonssystemer |
| Kundestøtte | 12 | Kundeportal, lesetilgang til timebestillinger |
| Salg og markedsføring | 8 | CRM og markedsføringsverktøy |
| Økonomi og HR | 6 | Lønn, fakturaer, personalmapper |

Bedriften bruker også **to eksterne konsulenter** (gjestekontoer) som hjelper til med utvikling.

## Informasjon bedriften behandler

| Type | Eksempler | Hvorfor det er viktig |
|---|---|---|
| **Personopplysninger om pasienter** | Navn, kontaktinfo, timehistorikk | GDPR gjelder |
| **Helseopplysninger** | Notater om behandling og fremgang | Særlige kategorier etter GDPR artikkel 9, så det forventes et høyere sikkerhetsnivå |
| **Kundedata** | Avtaler med klinikker, fakturaer | Fortrolige forretningsdata |
| **Ansattdata** | Lønn, kontrakter, sykefravær | Personopplysninger og fortrolig |
| **Kildekode** | Selve SaaS-plattformen | Bedriftens viktigste verdi |

## Situasjonen i dag

Fjellvik Helse AS flyttet fra egne servere til Microsoft Azure for omtrent seks måneder siden. Flyttingen ble gjort raskt av det lille IT-teamet for å rekke en frist, og fokuset var å få ting til å virke, ikke sikkerhet.

Dette vet ledelsen i dag:

- Alle i IT-teamet fikk brede admin-rettigheter under flyttingen «for å spare tid».
- MFA er ikke slått på for alle.
- De eksterne konsulentene fikk tilgang, men ingen vet helt hva de har tilgang til.
- Det finnes ingen oversikt over hvilke sikkerhetstiltak som er på plass.
- Det er ikke gjort noen risikovurdering etter flyttingen til skyen.

## Spørsmålet fra ledelsen

> *«Hvor står vi, og hva bør vi fikse først?»*

Ledelsen vil ha et kort og praktisk svar. De ber ikke om en full ISO 27001-sertifisering, men de vil vite hva de største risikoene er og få en prioritert plan som det lille IT-teamet faktisk klarer å gjennomføre.

## Omfang

**Med i vurderingen**

- Microsoft Entra ID: brukere, grupper, roller, gjestekontoer, MFA og innloggingsinnstillinger
- Azure-abonnementet: konfigurasjon av ressurser, policyer og sikkerhetsanbefalinger
- Kobling av funn mot CIS Azure Foundations Benchmark, ISO/IEC 27001:2022 og NSMs grunnprinsipper for IKT-sikkerhet

**Ikke med**

- Microsoft 365-apper (Exchange, SharePoint, Teams)
- Klienter og fysisk sikkerhet
- Penetrasjonstesting av selve SaaS-løsningen
- Juridisk vurdering etter GDPR (funn blir flagget, ikke vurdert juridisk)

## Forutsetninger

- Bedriften behandler helseopplysninger, så konfidensialitet har høyest prioritet.
- IT-teamet har lite tid, så tiltakene prioriteres etter hvor mye risiko de fjerner sammenlignet med innsatsen.
- All data i labmiljøet er fiktive testdata.
