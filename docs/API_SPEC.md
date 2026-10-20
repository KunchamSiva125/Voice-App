# REST API Specification: Telugu Tiffin Hotel Debt Management System

All endpoints operate under `/api`.
All money values are exchanged in **integer paise** (`amountPaise`, `balancePaise`).
All authenticated endpoints require header: `Authorization: Bearer <JWT_TOKEN>`.
Write endpoints require an `Idempotency-Key: <UUID>` header to guard against duplicate submissions.

---

## 1. Authentication Endpoints

### 1.1 Login
- **URL**: `POST /api/auth/login`
- **Access**: Public
- **Request Body**:
```json
{
  "username": "owner@tiffin.local",
  "password": "Password123!"
}
```
- **Response (200 OK)**:
```json
{
  "accessToken": "eyJhbGciOi...",
  "tokenType": "Bearer",
  "expiresInMs": 86400000,
  "user": {
    "id": "6715421...",
    "name": "Apparao (Owner)",
    "username": "owner@tiffin.local",
    "role": "OWNER",
    "active": true
  }
}
```

### 1.2 Get Current User
- **URL**: `GET /api/auth/me`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Response (200 OK)**:
```json
{
  "id": "6715421...",
  "name": "Apparao (Owner)",
  "username": "owner@tiffin.local",
  "role": "OWNER"
}
```

---

## 2. Customer Management Endpoints

### 2.1 List / Search Customers
- **URL**: `GET /api/customers?search=Ramesh&status=ACTIVE&page=0&size=20`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Response (200 OK)**:
```json
{
  "content": [
    {
      "id": "cust_123",
      "name": "Ramesh",
      "normalizedName": "ramesh",
      "aliases": ["రామేష్", "Auto Ramesh"],
      "phoneNumber": "9848022334",
      "notes": "Morning Idli regular customer",
      "status": "ACTIVE",
      "outstandingBalancePaise": 35000,
      "createdAt": "2026-10-01T04:30:00Z",
      "updatedAt": "2026-10-20T08:00:00Z"
    }
  ],
  "totalElements": 1,
  "totalPages": 1
}
```

### 2.2 Create Customer
- **URL**: `POST /api/customers`
- **Access**: `OWNER`, `ADMIN`
- **Request Body**:
```json
{
  "name": "Suresh (Driver)",
  "aliases": ["సురేష్", "Driver Suresh"],
  "phoneNumber": "9876543210",
  "notes": "Daily 2 Dosa parcel",
  "initialOpeningBalancePaise": 15000
}
```
- **Response (201 Created)**: Returns Customer details.

### 2.3 Get Customer Detail & Calculated Balance
- **URL**: `GET /api/customers/{id}`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Response (200 OK)**:
```json
{
  "id": "cust_123",
  "name": "Ramesh",
  "phoneNumber": "9848022334",
  "status": "ACTIVE",
  "outstandingBalancePaise": 35000,
  "balanceInRupees": 350.00,
  "totalCreditPaise": 60000,
  "totalPaymentPaise": 25000,
  "totalDiscountPaise": 0,
  "latestTransactionAt": "2026-10-20T08:15:00Z"
}
```

### 2.4 Update Customer
- **URL**: `PATCH /api/customers/{id}`
- **Access**: `OWNER`, `ADMIN`
- **Note**: Does NOT allow balance modification. Balances are altered only via Ledger entries.

---

## 3. Financial Ledger Endpoints

### 3.1 Record Credit (Add Debt)
- **URL**: `POST /api/transactions/credit`
- **Headers**: `Idempotency-Key: <UUID>`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Request Body**:
```json
{
  "customerId": "cust_123",
  "amountPaise": 10000,
  "description": "2 Plates Idli + 1 Tea",
  "effectiveAt": "2026-10-20T08:30:00Z"
}
```
- **Response (201 Created)**:
```json
{
  "transactionId": "tx_456",
  "customerId": "cust_123",
  "customerName": "Ramesh",
  "type": "CREDIT",
  "amountPaise": 10000,
  "balanceEffectPaise": 10000,
  "previousBalancePaise": 25000,
  "updatedBalancePaise": 35000,
  "createdAt": "2026-10-20T08:30:01Z",
  "teluguSpeechMessage": "రమేష్ గారికి 100 రూపాయల అప్పు నమోదైంది. ప్రస్తుత మొత్తం బాకీ 350 రూపాయలు."
}
```

### 3.2 Record Payment (Reduce Debt)
- **URL**: `POST /api/transactions/payment`
- **Headers**: `Idempotency-Key: <UUID>`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Request Body**:
```json
{
  "customerId": "cust_123",
  "amountPaise": 10000,
  "description": "Cash paid at counter",
  "allowExcessAsAdvance": false
}
```
- **Response (201 Created)**: Returns updated balance. If payment exceeds balance and `allowExcessAsAdvance` is false, returns `400 Bad Request` with structured warning so user can confirm.

### 3.3 Apply Discount / Debt Waiver
- **URL**: `POST /api/transactions/discount`
- **Headers**: `Idempotency-Key: <UUID>`
- **Access**: `OWNER`, `ADMIN` (FAMILY_MEMBER is forbidden)
- **Request Body**:
```json
{
  "customerId": "cust_123",
  "amountPaise": 5000,
  "reason": "Owner festival waiver"
}
```

### 3.4 Reverse a Transaction
- **URL**: `POST /api/transactions/{id}/reverse`
- **Access**: `OWNER`, `ADMIN`
- **Request Body**:
```json
{
  "reason": "Accidental duplicate entry entered by cashier"
}
```
- **Response (200 OK)**:
```json
{
  "reversalTransactionId": "tx_789",
  "originalTransactionId": "tx_456",
  "balanceEffectPaise": -10000,
  "updatedBalancePaise": 25000
}
```

### 3.5 Import Opening Balance (Migration from Paper Notebook)
- **URL**: `POST /api/transactions/opening-balance`
- **Access**: `OWNER`
- **Request Body**:
```json
{
  "customerId": "cust_123",
  "amountPaise": 25000,
  "notebookPageNumber": "Page 14",
  "notes": "Transferred from old red notebook"
}
```

---

## 4. Telugu Voice Command Endpoints

### 4.1 Parse Spoken Voice Transcript
- **URL**: `POST /api/voice/parse`
- **Access**: `OWNER`, `ADMIN`, `FAMILY_MEMBER`
- **Request Body**:
```json
{
  "rawTranscript": "రమేష్ కి 100 రూపాయలు అప్పు రాయి"
}
```
- **Response (200 OK)**:
```json
{
  "intent": "ADD_CREDIT",
  "customerName": "Ramesh",
  "amountPaise": 10000,
  "confidence": 0.96,
  "matchedCustomers": [
    {
      "id": "cust_123",
      "name": "Ramesh",
      "phoneNumber": "9848022334",
      "outstandingBalancePaise": 25000
    }
  ],
  "requiresDisambiguation": false,
  "requiresConfirmation": false
}
```

---

## 5. Reporting Endpoints (Asia/Kolkata Timezone)

### 5.1 Daily Summary Report
- **URL**: `GET /api/reports/daily?date=2026-10-20`
- **Access**: `OWNER`, `ADMIN`
- **Response (200 OK)**:
```json
{
  "businessDate": "2026-10-20",
  "totalCreditsRecordedPaise": 450000,
  "totalPaymentsCollectedPaise": 380000,
  "totalDiscountsPaise": 5000,
  "netChangePaise": 65000,
  "activeCustomersCount": 142,
  "totalOutstandingDebtPaise": 1250000
}
```

### 5.2 Outstanding Debt Aging & Top Debtors
- **URL**: `GET /api/reports/outstanding?top=10`
- **Access**: `OWNER`, `ADMIN`

### 5.3 CSV Export
- **URL**: `GET /api/admin/exports/transactions.csv?startDate=2026-10-01&endDate=2026-10-20`
- **Access**: `OWNER`
- **Content-Type**: `text/csv`
