# Step 4: Deploy Code to Runtime Manager (CloudHub)

## 1. Overview
MuleSoft applications can be deployed to Runtime Manager (CloudHub 1.0, CloudHub 2.0, or On-Premises Runtime Fabric). This document provides both **Maven CLI** automated deployment and **Anypoint Studio GUI** deployment instructions.

---

## 2. Deployment via Mule Maven Plugin

Each API's `pom.xml` contains a configured `<cloudHubDeployment>` block under `mule-maven-plugin`:

```xml
<plugin>
    <groupId>org.mule.tools.maven</groupId>
    <artifactId>mule-maven-plugin</artifactId>
    <version>3.8.2</version>
    <extensions>true</extensions>
    <configuration>
        <cloudHubDeployment>
            <uri>https://anypoint.mulesoft.com</uri>
            <muleVersion>4.4.0</muleVersion>
            <username>${anypoint.username}</username>
            <password>${anypoint.password}</password>
            <applicationName>bank-customer-proc-api-dev</applicationName>
            <environment>Sandbox</environment>
            <region>us-east-1</region>
            <workers>1</workers>
            <workerType>MICRO</workerType>
            <properties>
                <env>dev</env>
                <!-- Anypoint Platform Environment Credentials for API Manager Gatekeeper -->
                <anypoint.platform.client_id>${anypoint.platform.client_id}</anypoint.platform.client_id>
                <anypoint.platform.client_secret>${anypoint.platform.client_secret}</anypoint.platform.client_secret>
                <anypoint.platform.gatekeeper>disabled</anypoint.platform.gatekeeper>
            </properties>
        </cloudHubDeployment>
    </configuration>
</plugin>
```

### Maven Deployment Commands
Run from the root of each project directory (or in a multi-module build):

```powershell
# Deploy Customer Demographics System API
cd c:\Users\durga\Downloads\mulesft_bank\customer-demographics-sys-api
mvn clean deploy -DmuleDeploy `
  -Danypoint.username="your_anypoint_username" `
  -Danypoint.password="your_anypoint_password" `
  -Danypoint.platform.client_id="your_env_client_id" `
  -Danypoint.platform.client_secret="your_env_client_secret"

# Deploy Account Details System API
cd c:\Users\durga\Downloads\mulesft_bank\account-details-sys-api
mvn clean deploy -DmuleDeploy `
  -Danypoint.username="your_anypoint_username" `
  -Danypoint.password="your_anypoint_password" `
  -Danypoint.platform.client_id="your_env_client_id" `
  -Danypoint.platform.client_secret="your_env_client_secret"

# Deploy Customer Process API
cd c:\Users\durga\Downloads\mulesft_bank\customer-proc-api
mvn clean deploy -DmuleDeploy `
  -Danypoint.username="your_anypoint_username" `
  -Danypoint.password="your_anypoint_password" `
  -Danypoint.platform.client_id="your_env_client_id" `
  -Danypoint.platform.client_secret="your_env_client_secret"
```

> **Note on Connected Apps**: For production CI/CD, replace `<username>` and `<password>` with `<connectedAppClientId>`, `<connectedAppClientSecret>`, and `<connectedAppGrantType>client_credentials`.

---

## 3. Deployment via Anypoint Studio GUI

1. In Anypoint Studio, right-click on the project (e.g. `customer-proc-api`).
2. Select **Anypoint Platform** $\rightarrow$ **Deploy to CloudHub**.
3. In the Deployment dialog:
   - **Application Name**: Enter a globally unique name (e.g., `bank-customer-proc-api-dev-<your-initials>`).
   - **Deployment Target**: CloudHub (or CloudHub 2.0 Shared Space).
   - **Mule Version**: `4.4.0` or higher.
   - **Worker Size**: `0.1 vCores` (Micro).
   - **Workers**: `1`.
4. Click on the **Properties** tab:
   - Add `env` = `dev`
   - Add `anypoint.platform.client_id` = `<your_sandbox_environment_client_id>`
   - Add `anypoint.platform.client_secret` = `<your_sandbox_environment_client_secret>`
   - Add `anypoint.platform.gatekeeper` = `disabled` (or `lenient`)
5. Click **Deploy Application**.
6. Monitor the deployment progress in Runtime Manager until the status badge turns **Green (Started)**.
