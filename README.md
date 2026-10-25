# Azure GRC Lab

**Compliance as code and IAM review for a fictional Norwegian company in Microsoft Azure.**

This project shows how I would approach a security assessment as a consultant: set up a realistic Azure environment, measure it against recognised frameworks, automate the evidence collection, and turn the findings into a report that management can act on.

> **Status:** In progress. The roadmap below is updated as each phase is completed.

---

## The scenario

*Fjellvik Helse AS* is a fictional Norwegian company with around 40 employees that provides digital booking and follow-up services to physiotherapy clinics. It has recently moved its IT to Microsoft Azure. Nobody has looked properly at security since the migration, and management wants to know:

> *"Where do we stand, and what should we fix first?"*

The full company profile is in [`docs/01-company-profile.md`](docs/01-company-profile.md).

**The company is fictional.** All users, data and names in this lab are made up.

---

## What this project covers

| Area | What I do |
|---|---|
| **Identity and access (IAM)** | Users, groups and roles in Microsoft Entra ID. Review of MFA, privileged roles, guest accounts and least privilege. |
| **Compliance as code** | Azure Policy assignments mapped to recognised frameworks, with compliance measured automatically. |
| **Cloud security posture** | Microsoft Defender for Cloud recommendations and secure score. |
| **Automation** | Scripts that collect compliance and IAM data and produce a repeatable report. |
| **Risk and advisory** | Risk assessment, prioritised findings and recommendations written for management. |

### Frameworks used

- **CIS Microsoft Azure Foundations Benchmark** for technical controls
- **ISO/IEC 27001:2022** (Annex A) for mapping findings to an ISMS
- **NSM Grunnprinsipper for IKT-sikkerhet** for a Norwegian context
- **GDPR** where the findings touch personal data

---

## Roadmap

- [x] **Phase 1 – Foundation:** repository, scenario and company profile
- [ ] **Phase 2 – Build the environment:** Entra ID users, groups and roles, plus a small set of Azure resources, including deliberate misconfigurations
- [ ] **Phase 3 – Measure:** Azure Policy and Defender for Cloud against the chosen frameworks
- [ ] **Phase 4 – Automate:** scripts for collecting compliance and IAM evidence
- [ ] **Phase 5 – Assess:** risk assessment of the findings
- [ ] **Phase 6 – Advise:** report with prioritised recommendations, then remediate and show before/after

---

## Repository structure

```
azure-grc-lab/
├── README.md
├── docs/
│   ├── 01-company-profile.md   # the fictional company and scope
│   ├── 02-risk-assessment.md   # risks, likelihood, impact, treatment
│   └── 03-report.md            # findings and recommendations for management
├── scripts/                    # evidence collection (Python / PowerShell)
├── policies/                   # Azure Policy definitions and assignments
└── screenshots/                # evidence from the Azure portal
```

---

## Cost and safety

- Runs on an **Azure for Students** subscription with a budget alert.
- Compute is kept small and shut down when not in use.
- No secrets, keys or tenant IDs are committed to this repository.

---

## About me

**Abshir Ahmed Arale**, final year bachelor's student in IT with a specialisation in cybersecurity at Høyskolen Kristiania, Oslo. Interested in GRC, cloud security and IAM, with the goal of working in security consulting.

- LinkedIn: [linkedin.com/in/abshir-arale](https://www.linkedin.com/in/abshir-arale)
- GitHub: [github.com/Abshir-23](https://github.com/Abshir-23)
