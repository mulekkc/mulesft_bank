# Complete MySQL Database Integration Guide for MuleSoft Banking APIs

## 1. Overview
The banking platform integrates two System APIs directly with MySQL to persist core banking records, execute parameterized queries, and maintain transactional integrity:

1. **`customer-demographics-sys-api`**: Governs the `customers` table (Customer Master, contact details, identity, addresses).
2. **`account-details-sys-api`**: Governs the `accounts` table (Ledgers, checking/savings/investments, balances, branch routing).

Both System APIs connect to the database schema: **`account_details`** (or `bank_db`).

---

## 2. Complete Database & Tables DDL Setup

Run the following SQL script directly in **MySQL Workbench**, **DBeaver**, or the **MySQL CLI**:

```sql
-- 1. Create and select Database
CREATE DATABASE IF NOT EXISTS account_details;
USE account_details;

-- 2. Create CUSTOMERS Table
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(50) NOT NULL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30) NOT NULL,
    date_of_birth DATE NOT NULL,
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Create ACCOUNTS Table
CREATE TABLE IF NOT EXISTS accounts (
    account_id VARCHAR(50) NOT NULL PRIMARY KEY,
    account_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id VARCHAR(50) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    branch_code VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_id (customer_id),
    INDEX idx_status (status),
    CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Seed Initial Test Data (John Doe - CUST-1001)
INSERT INTO customers (customer_id, first_name, last_name, email, phone, date_of_birth, street, city, state, postal_code, country, status)
VALUES ('CUST-1001', 'John', 'Doe', 'john.doe@example.com', '+1-555-234-5678', '1988-06-15', '123 Financial Way', 'New York', 'NY', '10001', 'USA', 'ACTIVE')
ON DUPLICATE KEY UPDATE first_name=VALUES(first_name);

INSERT INTO accounts (account_id, account_number, customer_id, account_type, balance, currency, status, branch_code)
VALUES 
('ACC-900123', '100098234123', 'CUST-1001', 'CHECKING', 35000.00, 'USD', 'ACTIVE', 'BR-NYC-01'),
('ACC-900124', '100098234124', 'CUST-1001', 'INVESTMENT', 75000.50, 'USD', 'ACTIVE', 'BR-NYC-01')
ON DUPLICATE KEY UPDATE balance=VALUES(balance);
```

---

## 3. Configuration Properties

### `customer-demographics-sys-api/src/main/resources/config/config-dev.yaml`
```yaml
http:
  port: "8081"
  host: "0.0.0.0"

api:
  id: "21255073"
  version: "v1"

app:
  name: "customer-demographics-sys-api"

db:
  host: "localhost"
  port: "3306"
  user: "root"
  password: "password123"
  database: "account_details"
```

### `account-details-sys-api/src/main/resources/config/config-dev.yaml`
```yaml
http:
  port: "8082"
  host: "0.0.0.0"

api:
  id: "21260832"
  version: "v1"

app:
  name: "account-details-sys-api"

db:
  host: "localhost"
  port: "3306"
  user: "root"
  password: "password123"
  database: "account_details"
```

---

## 4. Mule Database Configuration & Drivers

Both projects use the **Mule Database Connector** and the **MySQL Connector/J** driver.

### In `pom.xml` (Both Projects)
```xml
<dependencies>
    <dependency>
        <groupId>org.mule.connectors</groupId>
        <artifactId>mule-db-connector</artifactId>
        <version>1.14.2</version>
        <classifier>mule-plugin</classifier>
    </dependency>
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <version>8.3.0</version>
    </dependency>
</dependencies>

<!-- Registered as sharedLibrary so Mule runtime classloader can load JDBC driver -->
<plugin>
    <groupId>org.mule.tools.maven</groupId>
    <artifactId>mule-maven-plugin</artifactId>
    <version>${mule.maven.plugin.version}</version>
    <extensions>true</extensions>
    <configuration>
        <sharedLibraries>
            <sharedLibrary>
                <groupId>com.mysql</groupId>
                <artifactId>mysql-connector-j</artifactId>
            </sharedLibrary>
        </sharedLibraries>
    </configuration>
</plugin>
```

### In `global-config.xml` (Both Projects)
```xml
<db:config name="Database_Config" doc:name="Database Config">
    <db:my-sql-connection host="${db.host}"
                           port="${db.port}"
                           user="${db.user}"
                           password="${db.password}"
                           database="${db.database}" />
</db:config>
```

---

## 5. Parameterized SQL Operations

### Customer Demographics Operations
1. **Create Customer (`POST /customers`)**:
   ```sql
   INSERT INTO customers (customer_id, first_name, last_name, email, phone, date_of_birth, street, city, state, postal_code, country, status, created_at, updated_at)
   VALUES (:customerId, :firstName, :lastName, :email, :phone, :dateOfBirth, :street, :city, :state, :postalCode, :country, :status, NOW(), NOW());
   ```
2. **Search Customers (`GET /customers`)**:
   ```sql
   SELECT customer_id AS customerId, first_name AS firstName, last_name AS lastName, email, phone, date_of_birth AS dateOfBirth, street, city, state, postal_code AS postalCode, country, status, created_at AS createdAt, updated_at AS updatedAt
   FROM customers
   WHERE (:email IS NULL OR email = :email)
     AND (:name IS NULL OR first_name LIKE CONCAT('%', :name, '%') OR last_name LIKE CONCAT('%', :name, '%'))
     AND (:status IS NULL OR status = :status);
   ```
3. **Get Customer by ID (`GET /customers/{customerId}`)**:
   ```sql
   SELECT customer_id AS customerId, first_name AS firstName, last_name AS lastName, email, phone, date_of_birth AS dateOfBirth, street, city, state, postal_code AS postalCode, country, status, created_at AS createdAt, updated_at AS updatedAt
   FROM customers
   WHERE customer_id = :customerId;
   ```
4. **Update Customer (`PUT /customers/{customerId}`)**:
   ```sql
   UPDATE customers 
   SET first_name = COALESCE(:firstName, first_name),
       last_name = COALESCE(:lastName, last_name),
       email = COALESCE(:email, email),
       phone = COALESCE(:phone, phone),
       date_of_birth = COALESCE(:dateOfBirth, date_of_birth),
       street = COALESCE(:street, street),
       city = COALESCE(:city, city),
       state = COALESCE(:state, state),
       postal_code = COALESCE(:postalCode, postal_code),
       country = COALESCE(:country, country),
       status = COALESCE(:status, status),
       updated_at = NOW()
   WHERE customer_id = :customerId;
   ```
5. **Delete Customer (`DELETE /customers/{customerId}`)**:
   ```sql
   DELETE FROM customers WHERE customer_id = :customerId;
   ```

---

### Account Details Operations
1. **Add Account (`POST /accounts`)**:
   ```sql
   INSERT INTO accounts (account_id, account_number, customer_id, account_type, balance, currency, status, branch_code, created_at, updated_at)
   VALUES (:accountId, :accountNumber, :customerId, :accountType, :balance, :currency, :status, :branchCode, NOW(), NOW());
   ```
2. **Fetch Accounts (`GET /accounts`)**:
   ```sql
   SELECT account_id AS accountId, account_number AS accountNumber, customer_id AS customerId, account_type AS accountType, balance, currency, status, branch_code AS branchCode, created_at AS createdAt, updated_at AS updatedAt
   FROM accounts
   WHERE (:customerId IS NULL OR customer_id = :customerId)
     AND (:status IS NULL OR status = :status);
   ```
3. **Fetch Account by ID (`GET /accounts/{accountId}`)**:
   ```sql
   SELECT account_id AS accountId, account_number AS accountNumber, customer_id AS customerId, account_type AS accountType, balance, currency, status, branch_code AS branchCode, created_at AS createdAt, updated_at AS updatedAt
   FROM accounts
   WHERE account_id = :accountId;
   ```
4. **Update Account (`PUT /accounts/{accountId}`)**:
   ```sql
   UPDATE accounts
   SET balance = COALESCE(:balance, balance),
       status = COALESCE(:status, status),
       branch_code = COALESCE(:branchCode, branch_code),
       updated_at = NOW()
   WHERE account_id = :accountId;
   ```

---

## 6. End-to-End Verification Commands

### 1. Create a Customer in `customer-demographics-sys-api`
```bash
curl -X POST "http://localhost:8081/api/v1/customers" \
  -H "client_id: 18bffd596de4460696c7fd785340b791" \
  -H "client_secret: 385d81d11E984aa2bed3BA20537f18aa" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Jane",
    "lastName": "Smith",
    "email": "jane.smith@example.com",
    "phone": "+1-555-987-6543",
    "dateOfBirth": "1992-11-20",
    "address": {
      "street": "456 Wall Street",
      "city": "Boston",
      "state": "MA",
      "postalCode": "02108",
      "country": "USA"
    },
    "status": "ACTIVE"
  }'
```

### 2. Fetch Customer by ID
```bash
curl -X GET "http://localhost:8081/api/v1/customers/CUST-1002" \
  -H "client_id: 18bffd596de4460696c7fd785340b791" \
  -H "client_secret: 385d81d11E984aa2bed3BA20537f18aa"
```

### 3. Add an Account for Customer `CUST-1002`
```bash
curl -X POST "http://localhost:8082/api/v1/accounts" \
  -H "client_id: a5c9bf36642f45ab876bb67b06a79604" \
  -H "client_secret: B2562A12Df864Bcb9cB06935DF751b6E" \
  -H "Content-Type: application/json" \
  -d '{
    "accountNumber": "100098234888",
    "customerId": "CUST-1002",
    "accountType": "CHECKING",
    "balance": 85000.00,
    "currency": "USD",
    "branchCode": "BR-NYC-02"
  }'
```

### 4. Fetch Accounts for `CUST-1002`
```bash
curl -X GET "http://localhost:8082/api/v1/accounts?customerId=CUST-1002" \
  -H "client_id: a5c9bf36642f45ab876bb67b06a79604" \
  -H "client_secret: B2562A12Df864Bcb9cB06935DF751b6E"
```
