# Azure GRC Lab

**Compliance as code og IAM-gjennomgang for en fiktiv norsk bedrift i Microsoft Azure.**

Dette prosjektet viser hvordan jeg ville gått frem som sikkerhetsrådgiver: sette opp et realistisk Azure-miljø, måle det mot anerkjente rammeverk, automatisere innsamlingen av dokumentasjon og gjøre funnene om til en rapport som ledelsen kan bruke.

> **Status:** Under arbeid. Veikartet nedenfor oppdateres etter hvert som fasene blir ferdige.

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
- [ ] **Fase 2 – Bygge miljøet:** brukere, grupper og roller i Entra ID, pluss noen få Azure-ressurser, med bevisste feilkonfigurasjoner
- [ ] **Fase 3 – Måle:** Azure Policy og Defender for Cloud mot de valgte rammeverkene
- [ ] **Fase 4 – Automatisere:** script for innsamling av dokumentasjon om etterlevelse og tilganger
- [ ] **Fase 5 – Vurdere:** risikovurdering av funnene
- [ ] **Fase 6 – Gi råd:** rapport med prioriterte anbefalinger, deretter utbedring og før/etter

---

## Struktur

```
azure-grc-lab/
├── README.md
├── docs/
│   ├── 01-virksomhet.md        # den fiktive bedriften og omfanget
│   ├── 02-risikovurdering.md   # risikoer, sannsynlighet, konsekvens og tiltak
│   └── 03-rapport.md           # funn og anbefalinger til ledelsen
├── scripts/                    # innsamling av dokumentasjon (Python / PowerShell)
├── policies/                   # Azure Policy-definisjoner og tildelinger
└── screenshots/                # skjermbilder fra Azure-portalen
```

---

## Kostnad og sikkerhet

- Kjører på et **Azure for Students**-abonnement med budsjettvarsling.
- Virtuelle maskiner holdes små og skrus av når de ikke brukes.
- Ingen hemmeligheter, nøkler eller tenant-ID-er legges i dette repoet.

---

## Om meg

**Abshir Ahmed Arale**, siste år på Bachelor i informasjonsteknologi med fordypning i cybersikkerhet ved Høyskolen Kristiania i Oslo. Interessert i GRC, skysikkerhet og IAM, med mål om å jobbe med sikkerhetsrådgivning.

- LinkedIn: [linkedin.com/in/abshir-arale](https://www.linkedin.com/in/abshir-arale)
- GitHub: [github.com/Abshir-23](https://github.com/Abshir-23)
