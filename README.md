# MuleSoft API-Led Banking Architecture & Development Task

This repository contains the complete end-to-end MuleSoft implementation for a digital banking platform adhering to MuleSoft's **API-Led Connectivity** architecture.

---
<img width="783" height="888" alt="Screenshot 2026-11-01 094422" src="https://github.com/user-attachments/assets/8311421d-7844-40cd-a194-7767f2b1e6de" />

## 📂 Project Structure

```
c:\Users\durga\Downloads\mulesft_bank/
├── customer-demographics-sys-api/       # System API 1: Demographics CRUD (Port 8081)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/main/
│       ├── resources/
│       │   ├── api/                     # RAML 1.0 specifications & Data Types
│       │   ├── config/config-dev.yaml
│       │   └── log4j2.xml
│       └── mule/                        # APIkit router & subflows
├── account-details-sys-api/             # System API 2: Accounts Management with MySQL (Port 8082)
│   ├── pom.xml                          # Includes Mule DB Connector & MySQL Driver
│   ├── mule-artifact.json
│   └── src/main/
│       ├── resources/
│       │   ├── api/                     # RAML 1.0 specifications & Data Types
│       │   ├── sql/accounts-schema.sql  # MySQL DDL table schema & seed data
│       │   ├── config/config-dev.yaml   # DB connection properties
│       │   └── log4j2.xml
│       └── mule/                        # APIkit router & MySQL DB subflows
├── customer-proc-api/                   # Process API: Scatter-Gather Aggregation (Port 8083)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/main/
│       ├── resources/
│       │   ├── api/                     # RAML 1.0 specifications & Data Types
│       │   ├── dwl/                     # Categorization DataWeave script (A, B, C, D)
│       │   ├── config/config-dev.yaml
│       │   └── log4j2.xml
│       └── mule/                        # Scatter-Gather parallel orchestration
└── docs/                                # Step-by-Step Implementation Guides
    ├── step1-raml-design.md
    ├── step2-exchange-publishing.md
    ├── step3-studio-scaffolding-and-logic.md
    ├── step4-runtime-manager-deployment.md
    ├── step5-api-manager-and-client-id-policy.md
    ├── mysql-setup-guide.md
    └── MuleSoft_Banking_API_Collection.postman_collection.json
```

---

## 🚀 5-Step Lifecycle Guides

| Step | Topic | Guide Link |
|:---|:---|:---|
| **Step 1** | **RAML Design & Security** | [docs/step1-raml-design.md](docs/step1-raml-design.md) |
| **Step 2** | **Publish to Exchange** | [docs/step2-exchange-publishing.md](docs/step2-exchange-publishing.md) |
| **Step 3** | **Scaffolding & Logic** | [docs/step3-studio-scaffolding-and-logic.md](docs/step3-studio-scaffolding-and-logic.md) |
| **Step 4** | **Runtime Manager Deploy** | [docs/step4-runtime-manager-deployment.md](docs/step4-runtime-manager-deployment.md) |
| **Step 5** | **API Manager & Policy** | [docs/step5-api-manager-and-client-id-policy.md](docs/step5-api-manager-and-client-id-policy.md) |
| **DB Setup** | **MySQL Integration** | [docs/mysql-setup-guide.md](docs/mysql-setup-guide.md) |

---

## 🏷️ Customer Categorization Matrix (Process Layer)

The Customer Process API normalizes foreign balances to INR (USD @ rate 83.50), evaluates the total aggregated balance across all accounts, and assigns one of 4 customer tiers:

| Tier Type | Tier Name | Criteria | Exclusive Benefits |
|:---:|:---|:---|:---|
| **Type A** | **Platinum / High Net Worth** | Total Balance $\ge \text{₹}50,00,000$ (50 Lakhs) | Dedicated Relationship Manager, Zero Wire Fees, Airport Lounge Access, Advisory |
| **Type B** | **Gold / Affluent** | $\text{₹}10,00,000 \le \text{Total Balance} < \text{₹}50,00,000$ (10 - 50 Lakhs) | Priority Customer Support, Discounted Forex, Fee Waivers |
| **Type C** | **Silver / Mass Market** | $\text{₹}2,00,000 \le \text{Total Balance} < \text{₹}10,00,000$ (2 - 10 Lakhs) | Free Mobile Alerts, Standard Online Banking, Zero Min Balance Fee |
| **Type D** | **Bronze / Basic** | $\text{Total Balance} < \text{₹}2,00,000$ (< 2 Lakhs) | Basic Savings, Digital Debit Card, Self-Service Mobile Banking |

---

## 🧪 Testing with Postman
Import the included Postman collection:
`docs/MuleSoft_Banking_API_Collection.postman_collection.json`
Pre-configured with all endpoints, headers, and test payloads.
