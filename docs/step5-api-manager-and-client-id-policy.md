# Step 5: Register API in API Manager & Apply Client ID Enforcement Policy

## 1. Overview
API Manager provides governance, security, rate limiting, and traffic monitoring for MuleSoft APIs. In this step, we:
1. Connect the Mule application to API Manager using **API Autodiscovery**.
2. Register the API instance in **API Manager**.
3. Apply the **Client ID Enforcement Policy**.
4. Request API access via **Exchange** to obtain client credentials.
5. Verify policy enforcement using cURL / Postman.

---

## 2. API Autodiscovery Configuration in Mule 4

In each project's `src/main/mule/global-config.xml`, the autodiscovery component links the Mule flow to the API instance in API Manager:

```xml
<api-gateway:autodiscovery 
    apiId="${api.id}" 
    ignoreBasePath="true" 
    doc:name="API Autodiscovery" 
    flowRef="customer-proc-api-main" />
```

- `apiId`: Points to `${api.id}` declared in `src/main/resources/config/config-dev.yaml`.
- `flowRef`: Must reference the main APIkit HTTP entry flow (`customer-proc-api-main`).
- At runtime, Mule connects to Anypoint API Manager using the environment credentials:
  - `-Danypoint.platform.client_id=<Sandbox_Client_Id>`
  - `-Danypoint.platform.client_secret=<Sandbox_Client_Secret>`

> **Where to find Environment Credentials**:
> Go to **Anypoint Platform** $\rightarrow$ **Access Management** $\rightarrow$ **Environments** $\rightarrow$ Click on **Sandbox** $\rightarrow$ Copy the **Client ID** and **Client Secret**.

---

## 3. Registering the API in API Manager (Step-by-Step)

1. In Anypoint Platform, open **API Manager**.
2. Click **Manage API** $\rightarrow$ **Create new API** (or Manage API from Exchange).
3. Fill in the fields:
   - **Asset type**: RAML / OAS
   - **Asset name**: Select the published asset from Exchange (e.g. `Customer Process API`).
   - **Asset version**: `1.0.0`
   - **API version**: `v1`
   - **Managing type**: Mule Gateway (Basic endpoint)
   - **Mule version**: Mule 4
   - **Implementation URI**: (Optional for CloudHub deployment, e.g. `http://bank-customer-proc-api-dev.us-e1.cloudhub.io/api/v1`)
4. Click **Save**.
5. On the API Administration page, locate the **API ID** (e.g. `19001236`).
6. Copy this ID and paste it into `config-dev.yaml`:
   ```yaml
   api:
     id: "19001236"
   ```
7. When the application runs and connects to Anypoint Platform, the API status in API Manager turns from **Unregistered** to **Active (Green)**.

---

## 4. Applying the Client ID Enforcement Policy

1. In **API Manager**, click on the registered API (e.g., `Customer Process API`).
2. In the left navigation menu, click **Policies**.
3. Click **Add policy**.
4. Under Security, select **Client ID Enforcement** and click **Next**.
5. Configuration:
   - **Policy version**: Select latest (e.g. `1.3.1` or `1.2.3`).
   - **Client ID expression**: `#[attributes.headers['client_id']]`
   - **Client Secret expression**: `#[attributes.headers['client_secret']]`
6. Click **Apply**.
7. The API Gateway automatically pulls down and activates the policy within seconds (no application restart required).

---

## 5. Requesting API Access in Exchange

To test the secured API, client credentials (`client_id` and `client_secret`) must be issued:

1. Open **Anypoint Exchange**.
2. Navigate to your published API asset (e.g., `Customer Process API`).
3. In the top right, click the three dots `...` or **Request Access**.
4. In the dialog:
   - Select the API instance registered in API Manager.
   - Click **Create a new application** (e.g., `Retail-Mobile-Banking-App`).
   - Description: `Banking mobile client application for testing`.
   - Click **Create**.
5. Select the application and choose the SLA tier (or default).
6. Click **Request Access**.
7. Exchange displays the **Client ID** and **Client Secret**. Save these credentials securely!

---

## 6. Testing & Verifying Policy Enforcement

### Test 1: Request WITHOUT Credentials (Expected: 401 Unauthorized)
```bash
curl -i -X GET http://localhost:8083/api/v1/customers/CUST-1001/profile
```
**Response**:
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "error": "Authentication failed",
  "message": "Client credentials are missing"
}
```

### Test 2: Request WITH Invalid Credentials (Expected: 401 / 403)
```bash
curl -i -X GET http://localhost:8083/api/v1/customers/CUST-1001/profile \
  -H "client_id: INVALID_ID" \
  -H "client_secret: INVALID_SECRET"
```
**Response**:
```http
HTTP/1.1 401 Unauthorized
Content-Type: application/json

{
  "error": "Authentication failed",
  "message": "Invalid client ID or client secret"
}
```

### Test 3: Request WITH Valid Credentials (Expected: 200 OK with Categorization)
```bash
curl -i -X GET http://localhost:8083/api/v1/customers/CUST-1001/profile \
  -H "client_id: 4a28f736e4f3465bb98ecbb547d84a32" \
  -H "client_secret: 98F39a04Cb794f87aBc46Ef15aDe74e0"
```
**Response**:
```json
{
  "customerId": "CUST-1001",
  "fullName": "John Doe",
  "demographics": {
    "customerId": "CUST-1001",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john.doe@example.com",
    "phone": "+1-555-234-5678",
    "dateOfBirth": "1988-06-15",
    "address": {
      "street": "123 Financial Way",
      "city": "New York",
      "state": "NY",
      "postalCode": "10001",
      "country": "USA"
    },
    "status": "ACTIVE"
  },
  "accounts": [
    {
      "accountId": "ACC-900123",
      "accountNumber": "100098234123",
      "accountType": "CHECKING",
      "balance": 35000.0,
      "currency": "USD",
      "status": "ACTIVE"
    },
    {
      "accountId": "ACC-900124",
      "accountNumber": "100098234124",
      "accountType": "INVESTMENT",
      "balance": 75000.5,
      "currency": "USD",
      "status": "ACTIVE"
    }
  ],
  "financialSummary": {
    "totalAccounts": 2,
    "totalBalance": 9185041.75,
    "currency": "INR",
    "currencyBreakdown": {
      "INR": 0.00,
      "USD": 110000.50
    },
    "fxRateApplied": "1 USD = 83.50 INR"
  },
  "classification": {
    "customerType": "A",
    "tierName": "Platinum / High Net Worth",
    "tierBenefits": [
      "Dedicated Relationship Manager",
      "Zero International Wire Fees",
      "Exclusive Investment Advisory",
      "Unlimited Airport Lounge Access"
    ],
    "evaluatedAt": "2026-11-01T07:15:00.000Z"
  }
}
```
