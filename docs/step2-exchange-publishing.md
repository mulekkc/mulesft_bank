# Step 2: Publish RAML to Anypoint Exchange

## 1. Overview
Publishing RAML API specifications to Anypoint Exchange transforms API specifications into cataloged assets that developers, partners, and systems can discover, review, mock, and consume. It also serves as the dependency source for API Manager and Anypoint Studio.

There are three ways to publish:
1. **Via Anypoint Platform (Design Center UI)** *(Most Common)*
2. **Via Anypoint Studio**
3. **Via Anypoint CLI / Maven Facade**

---

## 2. Method 1: Publishing via Design Center UI (Step-by-Step)

1. Log into your [Anypoint Platform](https://anypoint.mulesoft.com) account.
2. Select **Design Center** from the navigation menu.
3. Click **Create new** $\rightarrow$ **New API Spec**.
   - API Title: `Customer Demographics System API` (repeat for `Account Details System API` and `Customer Process API`).
   - Format: `RAML 1.0`.
4. Upload or paste the RAML files, Data Types, and Security Scheme files created in Step 1.
5. In the top-right corner of Design Center, click the **Publish** button and select **Publish to Exchange**.
6. In the dialog:
   - **Asset version**: `1.0.0`
   - **API version**: `v1`
   - **Lifecycle state**: `Development` or `Stable`
7. Click **Publish to Exchange**.
8. Verify in **Anypoint Exchange** that the API is published with interactive documentation and an API mocking service URL.

---

## 3. Method 2: Publishing from Anypoint Studio

1. Open Anypoint Studio.
2. Ensure you are authenticated with Anypoint Platform:
   - Go to **Window** $\rightarrow$ **Preferences** $\rightarrow$ **Anypoint Studio** $\rightarrow$ **Authentication**.
   - Click **Add** and sign in with your credentials.
3. In the Package Explorer, right-click the project (e.g. `customer-demographics-sys-api`).
4. Select **Anypoint Platform** $\rightarrow$ **Publish to Exchange**.
5. Fill in the details:
   - **Organization**: Select your Business Group / Organization.
   - **Asset ID**: `customer-demographics-sys-api`
   - **Version**: `1.0.0`
   - **API Version**: `v1`
6. Click **Finish**. Studio will package the RAML specification and publish it directly to your organization's Exchange.

---

## 4. Method 3: Publishing via Exchange Maven Facade (`exchange.json`)

To automate publishing through CI/CD pipelines (e.g. GitHub Actions, Jenkins), place an `exchange.json` descriptor in your API root directory:

```json
{
  "groupId": "b548b2a5-9a79-4c48-9569-421fbc864789",
  "assetId": "customer-proc-api",
  "version": "1.0.0",
  "apiVersion": "v1",
  "classifier": "raml",
  "name": "Customer Process API",
  "tags": ["banking", "process-api", "customer-360"]
}
```

Run the Maven command:
```bash
mvn clean deploy -s settings.xml
```
Where `settings.xml` contains your Anypoint Exchange repository credentials.
