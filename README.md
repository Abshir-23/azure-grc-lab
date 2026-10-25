# Azure GRC Lab

**Compliance as code og IAM-gjennomgang for en fiktiv norsk bedrift i Microsoft Azure.**

Dette prosjektet viser hvordan jeg ville gått frem som sikkerhetsrådgiver: sette opp et realistisk Azure-miljø, måle det mot anerkjente rammeverk, automatisere innsamlingen av dokumentasjon og gjøre funnene om til en rapport som ledelsen kan bruke.

> **Status:** Alt materiale er ferdig. Statusrapporter fra kjøring i Azure legges i `bevis/`.

---

## Scenarioet

*Fjellvik Helse AS* er en fiktiv norsk bedrift med rundt 40 ansatte som leverer digital timebestilling og oppfølging til fysioterapiklinikker. Bedriften har nylig flyttet IT-driften til Microsoft Azure. Ingen har sett ordentlig på sikkerheten etter flyttingen, og ledelsen vil vite:

> *«Hvor står vi, og hva bør vi fikse først?»*

Hele bedriftsprofilen ligger i [`docs/01-virksomhet.md`](docs/01-virksomhet.md).

**Bedriften er fiktiv.** Alle brukere, data og navn i denne laben er oppdiktet.

---

## Hva prosjektet dekker

| Område | Hva jeg gjør |
|---|---|
| **Identitet og tilgang (IAM)** | Brukere, grupper og roller i Microsoft Entra ID. Gjennomgang av MFA, privilegerte roller, gjestekontoer og minste privilegium. |
| **Compliance as code** | Azure Policy koblet mot anerkjente rammeverk, med automatisk måling av etterlevelse. |
| **Sikkerhetsstatus i skyen** | Anbefalinger og secure score fra Microsoft Defender for Cloud. |
| **Automatisering** | Script som henter ut data om etterlevelse og tilganger og lager en rapport som kan kjøres på nytt. |
| **Risiko og rådgivning** | Risikovurdering, prioriterte funn og anbefalinger skrevet for ledelsen. |

### Rammeverk

- **CIS Microsoft Azure Foundations Benchmark** for tekniske kontroller
- **ISO/IEC 27001:2022** (vedlegg A) for å koble funn til et styringssystem for informasjonssikkerhet
- **NSMs grunnprinsipper for IKT-sikkerhet** for norsk kontekst
- **GDPR** der funnene berører personopplysninger

---

## Veikart

- [x] **Fase 1 – Grunnmur:** repo, scenario og bedriftsprofil
- [x] **Fase 2 – Bygge miljøet:** brukere, grupper, tilganger og ressurser med bevisste feil
- [x] **Fase 3 – Måle:** Azure Policy (CIS og ISO 27001) og Defender for Cloud
- [x] **Fase 4 – Automatisere:** statusrapport som sjekker ni kontroller og kobler funn til rammeverkene
- [x] **Fase 5 – Vurdere:** [risikovurdering](docs/02-risikovurdering.md) med ni risikoer og risikomatrise
- [x] **Fase 6 – Gi råd:** [rapport til ledelsen](docs/03-rapport.md), utbedringsscript og før/etter

---

## Hovedfunn

| # | Risiko | Nivå |
|---|---|---|
| R1 | Innlogging uten MFA | Kritisk |
| R2 | Pasientvedlegg kan leses fra internett | Kritisk |
| R3 | Tidligere ansatt har fortsatt full tilgang | Kritisk |
| R4 | Hele IT-avdelingen er Owner på abonnementet | Høy |
| R5 | For mange Global Administrator | Høy |
| R6 | Eksterne konsulenter har tilgang til alt | Høy |
| R7 | Tjenestekonto med passord og bred tilgang | Høy |
| R8 | Aktivitetsloggen tas ikke vare på | Middels |
| R9 | Kundestøtte har unødvendig tilgang | Middels |

Hele vurderingen med begrunnelse og tiltak ligger i [`docs/02-risikovurdering.md`](docs/02-risikovurdering.md).

---

## Kjør det selv

Alt kjøres i **Azure Cloud Shell (Bash)**, i en egen lab-tenant. Ikke bruk en tenant som tilhører en skole eller arbeidsgiver.

```bash
git clone https://github.com/Abshir-23/azure-grc-lab
cd azure-grc-lab

bash scripts/01-opprett-identiteter.sh      # brukere, grupper og tilganger
bash scripts/02-ressurser-og-policyer.sh    # lagringskonto og Azure Policy
# vent 15 til 30 minutter på compliance-skanningen
python3 scripts/03-statusrapport.py         # statusrapport FØR
bash scripts/04-utbedring.sh                # retter funnene
python3 scripts/03-statusrapport.py         # statusrapport ETTER
bash scripts/99-rydd-opp.sh                 # sletter alt når du er ferdig
```

---

## Struktur

```
azure-grc-lab/
├── README.md
├── docs/
│   ├── 01-virksomhet.md            # den fiktive bedriften og omfanget
│   ├── 02-risikovurdering.md       # risikoer, sannsynlighet, konsekvens og tiltak
│   └── 03-rapport.md               # funn og tiltaksplan til ledelsen
├── scripts/
│   ├── 01-opprett-identiteter.sh   # Entra ID: brukere, grupper, roller
│   ├── 02-ressurser-og-policyer.sh # lagringskonto og Azure Policy
│   ├── 03-statusrapport.py         # sjekker miljøet og lager rapport
│   ├── 04-utbedring.sh             # retter funnene
│   └── 99-rydd-opp.sh              # sletter alt
├── data/
│   └── sluttede-ansatte.csv        # fiktiv liste fra HR
├── bevis/                          # statusrapporter fra før og etter
└── screenshots/                    # skjermbilder fra Azure-portalen
```

---

## Kostnad og sikkerhet

- Kjører på et **Azure for Students**-abonnement med budsjettvarsling.
- Prosjektet bruker ingen virtuelle maskiner, så kostnaden er nesten null.
- Kjør `99-rydd-opp.sh` når du er ferdig, så ingenting står og går.
- Ingen hemmeligheter, nøkler eller tenant-ID-er legges i dette repoet.

---

## Om meg

**Abshir Ahmed Arale**, siste år på Bachelor i informasjonsteknologi med fordypning i cybersikkerhet ved Høyskolen Kristiania i Oslo. Interessert i GRC, skysikkerhet og IAM, med mål om å jobbe med sikkerhetsrådgivning.

- LinkedIn: [linkedin.com/in/abshir-arale](https://www.linkedin.com/in/abshir-arale)
- GitHub: [github.com/Abshir-23](https://github.com/Abshir-23)
