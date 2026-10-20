# Telugu Voice Command & Acceptance Testing Checklist

Use this checklist on an Android phone or emulator with Telugu voice input enabled.

---

## 1. Voice Grammar & Utterance Verification

| Test # | Spoken Utterance (Telugu / Tanglish) | Expected Intent | Expected Amount | Expected System Response | Status |
|---|---|---|---|---|---|
| **V-01** | `"రమేష్ కి 100 రూపాయలు అప్పు రాయి"` | `ADD_CREDIT` | ₹100.00 | Saves credit. Speaks: *"రమేష్ గారికి 100 రూపాయల అప్పు నమోదైంది. ప్రస్తుత మొత్తం బాకీ..."* | [x] PASS |
| **V-02** | `"Ramesh vanda rupayalu ichadu"` | `RECORD_PAYMENT` | ₹100.00 | Saves payment. Speaks: *"రమేష్ గారి నుండి 100 రూపాయల చెల్లింపు అందింది..."* | [x] PASS |
| **V-03** | `"రమేష్ అప్పు ఎంత ఉంది?"` | `QUERY_BALANCE` | N/A | No write created. Speaks: *"రమేష్ గారికి మొత్తం ... రూపాయలు బాకీ ఉంది."* | [x] PASS |
| **V-04** | `"రమేష్ ఖాతాలో 50 రూపాయలు డిస్కౌంట్ ఇవ్వు"` | `APPLY_DISCOUNT` | ₹50.00 | Prompts confirmation. Speaks: *"రమేష్ గారికి 50 రూపాయలు రాయితీ ఇవ్వబడింది."* | [x] PASS |
| **V-05** | `"ఈ రోజు మొత్తం కలెక్షన్ ఎంత?"` | `DAILY_REPORT` | N/A | Displays and speaks: *"ఈ రోజు వసూలైన మొత్తం ... రూపాయలు."* | [x] PASS |
| **V-06** | `"రమేష్ అకౌంట్ చూపించు"` | `VIEW_HISTORY` | N/A | Opens customer transaction history screen. | [x] PASS |

---

## 2. End-to-End Acceptance Scenarios Verification

### Scenario 1: Customer Owes ₹250. Add ₹100 Credit.
- **Initial State**: Customer `Ramesh (Auto)` has balance ₹250.00.
- **Action**: Speak or submit: `POST /api/transactions/credit` with `amountPaise: 10000`.
- **Expected Result**: Updated balance is **₹350.00**. Confirmed via TTS and green badge.
- **Test Result**: Verified by `LedgerServiceTest.testScenario1_AddCreditIncreasesBalance`.

### Scenario 2: Record a ₹100 Payment.
- **Initial State**: Customer owes ₹350.00.
- **Action**: Speak or submit: `POST /api/transactions/payment` with `amountPaise: 10000`.
- **Expected Result**: Outstanding balance reduces to **₹250.00**.
- **Test Result**: Verified by `LedgerServiceTest.testScenario2_RecordPaymentDecreasesBalance`.

### Scenario 3: Apply a ₹50 Discount.
- **Initial State**: Customer owes ₹250.00.
- **Action**: Owner submits discount of ₹50.00 with reason *"Regular customer discount"*.
- **Expected Result**: Outstanding balance reduces to **₹200.00**.
- **Test Result**: Verified by `LedgerServiceTest.testScenario3_ApplyDiscountDecreasesBalance`.

### Scenario 4: Duplicate Idempotency Key Submission.
- **Action**: Submit the same payment request twice with identical `Idempotency-Key: dup_key_123`.
- **Expected Result**: Backend recognizes idempotency key, returns original payment receipt with `isDuplicateReplay = true`, and **does NOT decrement debt a second time**.
- **Test Result**: Verified by `LedgerServiceTest.testScenario4_DuplicateIdempotencyKeyReturnsOriginal`.

### Scenario 5: Multiple Customers with Same Name (Disambiguation).
- **Initial State**: Database contains `Ramesh (Auto)` and `Ramesh (Teacher)`.
- **Action**: User speaks: *"రమేష్ కి 100 రూపాయలు అప్పు రాయి"*.
- **Expected Result**: App halts automatic recording, displays the **Disambiguation Bottom Sheet**, and requires user to pick the specific Ramesh before modifying ledger records.
- **Test Result**: Verified by `VoiceCommandParserServiceTest.testDisambiguationForMultipleMatchingCustomers`.

### Scenario 6: Transaction Reversal & Correction.
- **Action**: Cashier made mistake; authorized Admin submits reversal with reason *"Cashier selected wrong customer"*.
- **Expected Result**: Original transaction is preserved with `hasReversal = true`. A compensatory `REVERSAL` transaction is inserted with opposite signed `balanceEffectPaise`. Net balance is restored. Audit event is permanently logged.
- **Test Result**: Verified by `LedgerServiceTest.testScenario5_ReversalCancelsOriginalTransactionExactlyOnce`.

### Scenario 7: Network Outage During Voice Entry.
- **Action**: Turn off Wi-Fi/Mobile Data and tap microphone.
- **Expected Result**: App displays *"ఆఫ్‌లైన్ (No Internet)"* banner. App displays error that transaction was NOT saved and does NOT falsely claim success.
- **Test Result**: Verified by Flutter `HomeVoiceScreen` connectivity indicator and error banner.

### Scenario 8: Unauthorized Reversal by Family Member.
- **Action**: User logged in with `ROLE_FAMILY_MEMBER` attempts to call `POST /api/transactions/{id}/reverse`.
- **Expected Result**: Backend returns HTTP `403 Forbidden` (`{"error":"Forbidden","message":"You do not have the required permissions for this action"}`).
- **Test Result**: Verified by `SecurityConfig` and `SecurityRolePermissionTest`.
