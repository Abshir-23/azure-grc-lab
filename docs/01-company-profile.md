# 01 – Company profile

> **Fjellvik Helse AS is a fictional company created for this lab.** Any resemblance to a real organisation is unintended.

## About the company

| | |
|---|---|
| **Name** | Fjellvik Helse AS (fictional) |
| **Location** | Oslo, Norway |
| **Employees** | About 40 |
| **Business** | SaaS platform for booking and patient follow-up, sold to physiotherapy clinics |
| **Customers** | Around 120 clinics in Norway |
| **IT staff** | Two people, who also handle internal support |

## Organisation

| Department | People | Typical access needs |
|---|---|---|
| Management | 4 | Reports, finance, strategy documents |
| IT and Development | 10 | Azure subscription, source code, production systems |
| Customer Support | 12 | Customer portal, read access to booking data |
| Sales and Marketing | 8 | CRM, marketing tools |
| Finance and HR | 6 | Payroll, invoices, employee records |

The company also uses **two external consultants** (guest accounts) who help with development.

## Information the company handles

| Type | Examples | Why it matters |
|---|---|---|
| **Personal data about patients** | Name, contact details, appointment history | GDPR applies |
| **Health related data** | Notes on treatment and progress | Special category data under GDPR Article 9, so a higher level of protection is expected |
| **Customer data** | Clinic contracts, invoices | Confidential business data |
| **Employee data** | Payroll, contracts, sick leave | Personal data and confidential |
| **Source code** | The SaaS platform | Core business asset |

## Current situation

Fjellvik Helse AS moved from local servers to Microsoft Azure about six months ago. The migration was done quickly by the small IT team to meet a deadline, and the focus was on getting things to work rather than on security.

What management knows today:

- Everyone in the IT team got broad admin rights during the migration "to save time".
- MFA is not consistently enforced.
- The external consultants were given access, but nobody is sure what they can reach.
- There is no overview of which security controls are in place.
- There has been no risk assessment since the move to the cloud.

## The question from management

> *"Where do we stand, and what should we fix first?"*

Management wants a short, practical answer. They are not asking for a full ISO 27001 certification, but they want to know their biggest risks and get a prioritised plan that the small IT team can actually carry out.

## Scope of the assessment

**In scope**

- Microsoft Entra ID: users, groups, roles, guest accounts, MFA and sign-in settings
- The Azure subscription: resource configuration, policies and security recommendations
- Mapping of findings to CIS Azure Foundations Benchmark, ISO/IEC 27001:2022 and NSM Grunnprinsipper

**Out of scope**

- Microsoft 365 apps (Exchange, SharePoint, Teams)
- Endpoints and physical security
- Penetration testing of the SaaS application
- Legal advice on GDPR (findings are flagged, not legally assessed)

## Assumptions

- The company is treated as handling health related personal data, so confidentiality has the highest priority.
- The IT team has limited time, so recommendations are prioritised by risk reduction compared with effort.
- All data in the lab environment is fictional test data.
