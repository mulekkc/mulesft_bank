# Step 1: Create RAML with Client ID Enforcement Security Scheme

## 1. Overview
In API-led connectivity, APIs are designed API-first. RAML (RESTful API Modeling Language) 1.0 specifications are drafted to model resources, data contracts, status codes, and security policies before implementing any code.

In this banking project, we have defined three APIs:
1. **Customer Demographics System API (`customer-demographics-sys-api`)**
2. **Account Details System API (`account-details-sys-api`)**
3. **Customer Process API (`customer-proc-api`)**

---

## 2. Reusable Security Scheme: Client ID Enforcement
Every API includes a reusable security scheme `securitySchemes/clientIdValidation.raml` requiring two mandatory headers:
- `client_id`: Identifies the client application registered in Anypoint Exchange.
- `client_secret`: Confidential secret verifying application identity.

```raml
#%RAML 1.0 SecurityScheme
type: x-client-id-enforcement
description: Enforce client_id and client_secret authentication headers
describedBy:
  headers:
    client_id:
      type: string
      required: true
      description: Application Client ID
      example: "4a28f736e4f3465bb98ecbb547d84a32"
    client_secret:
      type: string
      required: true
      description: Application Client Secret
      example: "98F39a04Cb794f87aBc46Ef15aDe74e0"
  responses:
    401:
      description: Unauthorized - Missing or invalid credentials
      body:
        application/json:
          example:
            code: "UNAUTHORIZED"
            message: "Client credentials are missing or invalid"
    403:
      description: Forbidden - Client not authorized for this API
      body:
        application/json:
          example:
            code: "FORBIDDEN"
            message: "Client does not have access to this resource"
```

Applied at the root of the RAML:
```raml
securitySchemes:
  client-id-enforcement: !include securitySchemes/clientIdValidation.raml

securedBy: [client-id-enforcement]
```

---

## 3. Customer Demographics System API Design
- **Path**: `/customers`
  - `POST`: Create customer demographics record. Accepts `Customer` payload, returns `201 Created` with generated `customerId`.
  - `GET`: Search customers. Optional query parameters: `email`, `name`, `status`. Returns `Customer[]`.
- **Path**: `/customers/{customerId}`
  - `GET`: Retrieve customer demographics by ID. Returns `Customer` (200 OK) or Error (404 Not Found).
  - `PUT`: Update customer demographics. Accepts modified fields, returns `200 OK`.
  - `DELETE`: Delete customer record. Returns `200 OK` confirmation.

### Data Type (`Customer.raml`)
```raml
#%RAML 1.0 DataType
type: object
properties:
  customerId?: string
  firstName: string
  lastName: string
  email: { type: string, pattern: "^.+@.+\\..+$" }
  phone: string
  dateOfBirth: date-only
  address:
    type: object
    properties:
      street: string
      city: string
      state: string
      postalCode: string
      country: string
  status?: { type: string, enum: [ACTIVE, INACTIVE, SUSPENDED], default: ACTIVE }
```

---

## 4. Account Details System API Design
- **Path**: `/accounts`
  - `POST`: Add new account details. Returns `201 Created` with generated `accountId`.
  - `GET`: Fetch account details. Optional query parameter `customerId` to fetch all accounts owned by a customer.
- **Path**: `/accounts/{accountId}`
  - `GET`: Fetch account details by account ID. Returns `Account` (200 OK).
  - `PUT`: Update account details (status, balance, branch). Returns `200 OK`.

### Data Type (`Account.raml`)
```raml
#%RAML 1.0 DataType
type: object
properties:
  accountId?: string
  accountNumber: string
  customerId: string
  accountType: { type: string, enum: [SAVINGS, CHECKING, INVESTMENT, CREDIT] }
  balance: { type: number, minimum: 0 }
  currency: { type: string, minLength: 3, maxLength: 3 }
  status?: { type: string, enum: [ACTIVE, DORMANT, BLOCKED, CLOSED], default: ACTIVE }
  branchCode: string
```

---

## 5. Customer Process API Design
- **Path**: `/customers/{customerId}/profile`
  - `GET`: Orchestrates calls to both Demographics and Account System APIs, converts foreign currencies to INR (USD @ 83.50), sums total balances in INR, and categorizes the customer into:
    - **Type A**: Total Balance $\ge \text{₹}50,00,000$ (50 Lakhs $\rightarrow$ Platinum / High Net Worth)
    - **Type B**: Total Balance $\ge \text{₹}10,00,000$ (10 Lakhs $\rightarrow$ Gold / Affluent)
    - **Type C**: Total Balance $\ge \text{₹}2,00,000$ (2 Lakhs $\rightarrow$ Silver / Mass Market)
    - **Type D**: Total Balance $< \text{₹}2,00,000$ (Bronze / Basic)
- **Path**: `/customers/onboard`
  - `POST`: Atomically onboard customer demographics and create initial account in the core banking system.
