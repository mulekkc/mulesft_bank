# Step 3: Scaffold Flows in Anypoint Studio & Implement Business Logic

## 1. Overview
In this step, we take the published RAML specifications and generate the Mule 4 skeleton flows using the APIkit module in Anypoint Studio, then implement the business logic and DataWeave transformations.

---

## 2. Scaffolding in Anypoint Studio

### Importing or Scaffolding from Scratch
When importing the provided projects into Anypoint Studio:
1. Open **Anypoint Studio**.
2. Go to **File** $\rightarrow$ **Import...** $\rightarrow$ **Anypoint Studio** $\rightarrow$ **Packaged mule application (.jar / .zip)** OR **Existing Mule Project into Workspace**.
3. Browse to `c:\Users\durga\Downloads\mulesft_bank\customer-demographics-sys-api` (and respectively the other two projects).
4. Click **Finish**.

### How APIkit Scaffolding Works
If scaffolding from an Exchange RAML directly:
- **File** $\rightarrow$ **New** $\rightarrow$ **Mule Project**.
- Check **Download RAML from Exchange** or **Browse files**.
- Check the box **Scaffold flows from these API specifications**.
- Studio automatically generates:
  - An HTTP Listener configured on `/api/v1/*`.
  - An `<apikit:router>` processor linked to the RAML file.
  - An APIkit console flow on `/console/*`.
  - Individual flow definitions matching every method + resource pair (e.g. `get:\customers\(customerId):customer-demographics-apiConfig`).
  - Standard error handlers for `APIKIT:BAD_REQUEST`, `APIKIT:NOT_FOUND`, `APIKIT:METHOD_NOT_ALLOWED`, `APIKIT:NOT_ACCEPTABLE`, `APIKIT:UNSUPPORTED_MEDIA_TYPE`, `APIKIT:NOT_IMPLEMENTED`.

---

## 3. Implementing Business Logic: System APIs

### Customer Demographics System API (`customer-demographics-sys-api`)
Located in `src/main/mule/implementation.xml`:
- **`create-customer-subflow`**:
  - Auto-generates unique Customer IDs (`CUST-1001` format) when not passed.
  - Stamps ISO-8601 creation timestamps `createdAt: now()`.
  - Sets HTTP status variable `vars.httpStatus = 201`.
- **`search-customers-subflow`**:
  - Filters by `email`, `name`, and `status`.
- **`get-customer-by-id-subflow`**:
  - Extracts URI parameter `#[attributes.uriParams.customerId]`.
  - Returns complete demographics record or handles not found.
- **`update-customer-subflow`**:
  - Applies modifications and updates `updatedAt: now()`.
- **`delete-customer-subflow`**:
  - Deletes record and returns success confirmation message.

### Account Details System API (`account-details-sys-api`)
Located in `src/main/mule/implementation.xml`:
- **`add-account-subflow`**:
  - Generates unique Account IDs (`ACC-900123` format).
  - Validates account type (`SAVINGS`, `CHECKING`, `INVESTMENT`, `CREDIT`).
  - Returns 201 Created.
- **`fetch-accounts-subflow`**:
  - Filters accounts by `customerId` query parameter.
- **`fetch-account-by-id-subflow`**:
  - Returns specific account details.
- **`update-account-subflow`**:
  - Modifies status, balance, or branch.

---

## 4. Implementing Business Logic: Process Layer Categorization

### Parallel Aggregation with Scatter-Gather
The Customer Process API (`customer-proc-api`) invokes both System APIs concurrently using Mule's `<scatter-gather>` component in `src/main/mule/implementation.xml`:

```xml
<scatter-gather doc:name="Parallel Scatter-Gather (Sys APIs)">
    <!-- Route 1: Call Demographics System API -->
    <route>
        <http:request method="GET"
                      config-ref="customer-demographics-sys-req-config"
                      path="/customers/{customerId}">
            <http:headers>#[{"client_id": p('sys.demographics.clientId'), "client_secret": p('sys.demographics.clientSecret')}]</http:headers>
            <http:uri-params>#[{"customerId": vars.customerId}]</http:uri-params>
        </http:request>
    </route>

    <!-- Route 2: Call Accounts System API -->
    <route>
        <http:request method="GET"
                      config-ref="account-details-sys-req-config"
                      path="/accounts">
            <http:headers>#[{"client_id": p('sys.accounts.clientId'), "client_secret": p('sys.accounts.clientSecret')}]</http:headers>
            <http:query-params>#[{"customerId": vars.customerId}]</http:query-params>
        </http:request>
    </route>
</scatter-gather>
```

### DataWeave 2.0 Customer Categorization Engine
After Scatter-Gather completes, payload `0` holds the Demographics result, and payload `1` holds the Accounts array.
The DataWeave script (`dwl/categorize-customer.dwl`) converts foreign currencies (e.g. USD to INR at rate 83.50), computes the total balance in INR, and classifies the customer into Types A, B, C, D:

```dataweave
%dw 2.0
output application/json

var demographicsPayload = payload["0"].payload default {}
var accountsPayload = payload["1"].payload default []

// Exchange Rate: 1 USD = 83.50 INR
var usdToInrRate = 83.50

// Convert each account balance into INR
fun toINR(acc) = 
    if (upper(acc.currency default "USD") == "USD") ((acc.balance default 0) * usdToInrRate)
    else (acc.balance default 0)

var totalBalanceInINR = sum(accountsPayload map ((acc) -> toINR(acc)))

// Categorization in INR:
// Type A: >= ₹50,00,000 (50 Lakhs -> Platinum / High Net Worth)
// Type B: >= ₹10,00,000 (10 Lakhs -> Gold / Affluent)
// Type C: >= ₹2,00,000  (2 Lakhs  -> Silver / Mass Market)
// Type D: <  ₹2,00,000  (Bronze / Basic)
fun determineCustomerType(bal: Number) = 
    if (bal >= 5000000) "A"
    else if (bal >= 1000000) "B"
    else if (bal >= 200000) "C"
    else "D"

var customerType = determineCustomerType(totalBalanceInINR)

fun getTierName(t: String) = t match {
    case "A" -> "Platinum / High Net Worth"
    case "B" -> "Gold / Affluent"
    case "C" -> "Silver / Mass Market"
    case "D" -> "Bronze / Basic"
    else     -> "Standard"
}

fun getTierBenefits(t: String) = t match {
    case "A" -> [
        "Dedicated Relationship Manager",
        "Zero International Wire Fees",
        "Exclusive Investment Advisory",
        "Unlimited Airport Lounge Access"
    ]
    case "B" -> [
        "Priority Customer Support",
        "Discounted Forex Rates",
        "Quarterly Financial Health Checkup",
        "Credit Card Annual Fee Waiver"
    ]
    case "C" -> [
        "Standard Online Banking",
        "Free Mobile Alerts",
        "Zero Monthly Maintenance Fee with Min Balance"
    ]
    case "D" -> [
        "Basic Savings Account",
        "Digital Debit Card",
        "Self-Service Mobile Banking"
    ]
    else -> ["Standard Banking Access"]
}
---
{
    customerId: vars.customerId,
    fullName: (demographicsPayload.firstName default "") ++ " " ++ (demographicsPayload.lastName default ""),
    demographics: demographicsPayload,
    accounts: accountsPayload,
    financialSummary: {
        totalAccounts: sizeOf(accountsPayload),
        totalBalance: totalBalanceInINR as Number {format: "#.00"},
        currency: "INR",
        currencyBreakdown: {
            INR: sum((accountsPayload filter (upper($.currency default "") == "INR")).balance default [0]) as Number {format: "#.00"},
            USD: sum((accountsPayload filter (upper($.currency default "") == "USD")).balance default [0]) as Number {format: "#.00"}
        },
        fxRateApplied: "1 USD = 83.50 INR"
    },
    classification: {
        customerType: customerType,
        tierName: getTierName(customerType),
        tierBenefits: getTierBenefits(customerType),
        evaluatedAt: now()
    }
}
```
