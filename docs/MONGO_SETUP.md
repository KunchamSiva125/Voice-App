# MongoDB Schema, Indexes & Setup Instructions

## 1. Database & Collections

Database Name: `tiffin_ledger_db`

### 1.1 Collection: `users`
Stores authenticated hotel staff (Owner, Admin, Family Members).

```javascript
{
  _id: ObjectId("..."),
  name: "Apparao (Owner)",
  username: "owner@tiffin.local",
  passwordHash: "$2a$12$...", // BCrypt / Argon2id
  role: "OWNER", // Enum: OWNER, ADMIN, FAMILY_MEMBER
  active: true,
  createdAt: ISODate("2026-10-01T00:00:00Z"),
  updatedAt: ISODate("2026-10-01T00:00:00Z"),
  lastLoginAt: ISODate("2026-10-20T08:00:00Z")
}
```

**Indexes:**
- `db.users.createIndex({ "username": 1 }, { unique: true })`
- `db.users.createIndex({ "role": 1, "active": 1 })`

---

### 1.2 Collection: `customers`
Stores customer identity, aliases in Telugu and English, and contact notes.

```javascript
{
  _id: "cust_123",
  name: "Ramesh",
  normalizedName: "ramesh",
  aliases: ["రామేష్", "రమేష్", "Auto Ramesh"],
  phoneNumber: "9848022334", // Optional
  notes: "Auto driver at bus stand",
  status: "ACTIVE", // Enum: ACTIVE, ARCHIVED
  createdAt: ISODate("2026-10-01T00:00:00Z"),
  updatedAt: ISODate("2026-10-20T08:00:00Z"),
  createdBy: "user_owner_1",
  updatedBy: "user_owner_1"
}
```

**Indexes:**
- `db.customers.createIndex({ "normalizedName": 1 })`
- `db.customers.createIndex({ "aliases": 1 })`
- `db.customers.createIndex({ "phoneNumber": 1 }, { sparse: true })`
- `db.customers.createIndex({ "status": 1, "name": 1 })`
- `db.customers.createIndex({ "$**": "text" })` // Full-text search for Telugu and English names

---

### 1.3 Collection: `ledgerTransactions`
Append-only source of truth for all financial movements.

```javascript
{
  _id: "tx_456",
  customerId: "cust_123",
  type: "CREDIT", // Enum: CREDIT, PAYMENT, DISCOUNT, OPENING_BALANCE, REVERSAL, ADJUSTMENT
  amountPaise: NumberLong(10000), // Positive integer (₹100.00)
  balanceEffectPaise: NumberLong(10000), // Signed (+10000 for credit, -10000 for payment)
  status: "POSTED", // Enum: POSTED, REVERSED
  effectiveAt: ISODate("2026-10-20T08:30:00Z"), // Business date/time in Asia/Kolkata
  createdAt: ISODate("2026-10-20T08:30:01Z"), // Server timestamp
  createdBy: "user_family_1",
  idempotencyKey: "e4eaaaf2-d142-11e1-b3e4-080027620cdd",
  description: "2 Plates Idli + 1 Tea",
  correctionReason: null,
  reversesTransactionId: null,
  reversalTransactionId: null,
  hasReversal: false,
  metadata: {
    voiceUtterance: "రమేష్ కి 100 రూపాయలు అప్పు రాయి",
    source: "ANDROID_VOICE"
  }
}
```

**Indexes:**
- `db.ledgerTransactions.createIndex({ "customerId": 1, "effectiveAt": -1 })`
- `db.ledgerTransactions.createIndex({ "idempotencyKey": 1 }, { unique: true, sparse: true })`
- `db.ledgerTransactions.createIndex({ "type": 1, "effectiveAt": 1 })`
- `db.ledgerTransactions.createIndex({ "reversesTransactionId": 1 }, { sparse: true })`

---

### 1.4 Collection: `auditEvents`
Tamper-resistant operational audit trail.

```javascript
{
  _id: ObjectId("..."),
  actorUserId: "user_owner_1",
  action: "TRANSACTION_REVERSED", // Enum: USER_LOGIN, CUSTOMER_CREATED, CUSTOMER_ARCHIVED, TRANSACTION_CREATED, TRANSACTION_REVERSED, OPENING_BALANCE_IMPORTED, EXPORT_DOWNLOADED
  entityType: "TRANSACTION",
  entityId: "tx_456",
  occurredAt: ISODate("2026-10-20T09:00:00Z"),
  reason: "Cashier entered twice by mistake",
  beforeSnapshot: { "amountPaise": 10000, "status": "POSTED" },
  afterSnapshot: { "status": "REVERSED", "reversalId": "tx_789" },
  requestId: "req_xyz987",
  clientIp: "192.168.1.15"
}
```

**Indexes:**
- `db.auditEvents.createIndex({ "occurredAt": -1 })`
- `db.auditEvents.createIndex({ "entityType": 1, "entityId": 1 })`
- `db.auditEvents.createIndex({ "actorUserId": 1, "occurredAt": -1 })`

---

## 2. Setup Scripts

Run MongoDB shell (`mongosh`) or Mongo Compass to initialize collections and indexes:

```javascript
use tiffin_ledger_db;

// Collections
db.createCollection("users");
db.createCollection("customers");
db.createCollection("ledgerTransactions");
db.createCollection("auditEvents");

// Unique index on username
db.users.createIndex({ "username": 1 }, { unique: true });

// Customer search indexes
db.customers.createIndex({ "normalizedName": 1 });
db.customers.createIndex({ "aliases": 1 });
db.customers.createIndex({ "phoneNumber": 1 });

// Ledger transaction indexes
db.ledgerTransactions.createIndex({ "customerId": 1, "effectiveAt": -1 });
db.ledgerTransactions.createIndex({ "idempotencyKey": 1 }, { unique: true, sparse: true });
db.ledgerTransactions.createIndex({ "effectiveAt": 1 });

// Audit event indexes
db.auditEvents.createIndex({ "occurredAt": -1 });
db.auditEvents.createIndex({ "entityType": 1, "entityId": 1 });
```
