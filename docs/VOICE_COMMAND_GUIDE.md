# Telugu Voice Command Guide & Deterministic Parser Specification
**(తెలుగు వాయిస్ కమాండ్ గైడ్ & గ్రామర్ వివరణ)**

## 1. Overview & Voice Interaction Safety Rules

The voice recognition module uses a **two-tier architecture**:
1. **Speech-to-Text (STT) Layer**: Android Native `SpeechRecognizer` (or cloud fallback) captures speech after explicit user tap and transcribes audio to text (either Telugu script or Latin Tanglish script).
2. **Deterministic Telugu Command Parser**: A rule-based, deterministic NLP engine with strict tokenization, phonetic matching, and number normalization. **No black-box LLM executes database mutations directly.**

### Voice Interaction Safety Guarantees:
- **Explicit Recording Action**: Recording starts ONLY when the microphone button is pressed.
- **Visual Pulse**: Active recording displays pulsing wave animation and green recording indicator.
- **Zero Audio Retention**: Raw voice audio is never stored on disk or server; only transcribed text is processed.
- **Confirmation on Ambiguity**: Financially consequential operations (corrections, discounts, excess payments, multiple customer matches) always prompt with a confirmation dialog.
- **Audible + Visual Confirmation**: Confirmed transactions are displayed on screen and spoken back via Telugu Text-to-Speech (TTS).

---

## 2. Telugu Vocabulary & Grammar Matrix

### 2.1 Intent Keywords & Action Phrases

| Intent | Telugu Script Keywords | Latin / Tanglish Keywords | English / Loanwords |
|---|---|---|---|
| `ADD_CREDIT` | అప్పు రాయి, అప్పు వెయ్యి, ఖాతాలో రాయి, అప్పుగా రాయి | appu raayi, appu veyyi, khata lo raayi, appu rayi | credit rayi, credit veyyi |
| `RECORD_PAYMENT` | ఇచ్చాడు, ఇచ్చారు, కట్టాడు, కట్టారు, చెల్లించాడు | ichadu, iccharu, kattadu, kattaru, chellinchadu | pay chesadu, payment ichadu |
| `QUERY_BALANCE` | అప్పు ఎంత ఉంది, ఎంత బాకీ ఉంది, ఎంత ఇవ్వాలి, బ్యాలెన్స్ ఎంత | appu entha undi, baki entha undi, entha ivvali, balance entha | balance entha, balance cheppu |
| `APPLY_DISCOUNT` | డిస్కౌంట్ ఇవ్వు, రాయితీ ఇవ్వు, తగ్గించు, వదిలేయి | discount ivvu, rayiti ivvu, tagginchu, vadileyi | discount ivvali, concession |
| `VIEW_HISTORY` | ఖాతా చూపించు, హిస్టరీ చూపించు, లెక్క చూపించు | khata chupinchu, account chupinchu, lekka chupinchu | history chupinchu, statement |
| `DAILY_REPORT` | ఈ రోజు కలెక్షన్ ఎంత, ఈ రోజు మొత్తం ఎంత, ఈ రోజు లెక్క ఎంత | ee roju collection entha, ee roju mottham entha | today report, today total |

---

### 2.2 Number System & Currency Parsing

The parser converts both Telugu words, digits, and Indian English numerals into exact integer paise:

| Number / Word | Telugu Script | Meaning in Paise |
|---|---|---|
| `10` / padhi | పది | 1,000 paise (₹10.00) |
| `20` / iravai | ఇరవై | 2,000 paise (₹20.00) |
| `30` / muppai | ముప్పై | 3,000 paise (₹30.00) |
| `40` / nalabhai | నలభై | 4,000 paise (₹40.00) |
| `50` / yabhai | యాభై | 5,000 paise (₹50.00) |
| `60` / aravai | అరవై | 6,000 paise (₹60.00) |
| `70` / debbai | డెబ్బై | 7,000 paise (₹70.00) |
| `80` / enabhai | ఎనభై | 8,000 paise (₹80.00) |
| `90` / tombhai | తొంభై | 9,000 paise (₹90.00) |
| `100` / vanda / nooru | వంద / నూరు / hundred | 10,000 paise (₹100.00) |
| `150` / vanda yabhai | వంద యాభై | 15,000 paise (₹150.00) |
| `200` / rendu vandalu | రెండు వందలు | 20,000 paise (₹200.00) |
| `500` / aidu vandalu | ఐదు వందలు | 50,000 paise (₹500.00) |
| `1000` / veyyi | వెయ్యి / thousand | 100,000 paise (₹1,000.00) |

Currency words like `రూపాయలు`, `రూపాయల`, `rupayalu`, `rupees`, `rs` are stripped as unit markers.

---

## 3. Representative Voice Utterances & Parsed DTOs

### Example 1: Add Credit
- **User Speaks**: `"రమేష్ కి 100 రూపాయలు అప్పు రాయి"` or `"Ramesh ki 100 rupayalu appu raayi"`
- **Parsed DTO**:
```json
{
  "intent": "ADD_CREDIT",
  "customerName": "Ramesh",
  "amountPaise": 10000,
  "confidence": 0.95,
  "requiresConfirmation": false,
  "rawTranscript": "రమేష్ కి 100 రూపాయలు అప్పు రాయి"
}
```

### Example 2: Record Payment
- **User Speaks**: `"రమేష్ వంద రూపాయలు ఇచ్చాడు"` or `"Ramesh vanda rupayalu ichadu"`
- **Parsed DTO**:
```json
{
  "intent": "RECORD_PAYMENT",
  "customerName": "Ramesh",
  "amountPaise": 10000,
  "confidence": 0.95,
  "requiresConfirmation": false,
  "rawTranscript": "రమేష్ వంద రూపాయలు ఇచ్చాడు"
}
```

### Example 3: Balance Query
- **User Speaks**: `"రమేష్ అప్పు ఎంత ఉంది?"` or `"Ramesh appu entha undi?"`
- **Parsed DTO**:
```json
{
  "intent": "QUERY_BALANCE",
  "customerName": "Ramesh",
  "amountPaise": null,
  "confidence": 0.96,
  "requiresConfirmation": false,
  "rawTranscript": "రమేష్ అప్పు ఎంత ఉంది?"
}
```
- **Spoken TTS Output**:
  `"రమేష్ గారికి మొత్తం 350 రూపాయలు బాకీ ఉంది."` (Ramesh gariki mottham 350 rupayalu baki undi.)

### Example 4: Apply Discount
- **User Speaks**: `"రమేష్ అప్పులో 50 రూపాయలు డిస్కౌంట్ ఇవ్వు"` or `"Ramesh appulo 50 rupayalu discount ivvu"`
- **Parsed DTO**:
```json
{
  "intent": "APPLY_DISCOUNT",
  "customerName": "Ramesh",
  "amountPaise": 5000,
  "confidence": 0.92,
  "requiresConfirmation": true,
  "confirmationReason": "రమేష్ ఖాతాలో ₹50.00 డిస్కౌంట్ ఇవ్వడానికి ఖరారు చేయండి.",
  "rawTranscript": "రమేష్ అప్పులో 50 రూపాయలు డిస్కౌంట్ ఇవ్వు"
}
```

---

## 4. Disambiguation & Clarification Logic

When speech recognition or customer matching is not 100% distinct:

1. **Multiple Customer Matches**:
   - Spoken name: `"Ramesh"`
   - Database finds: `Ramesh (Auto Driver, 9848011111)` and `Ramesh (Teacher, 9988776655)`.
   - Action: The app halts submission and presents a **Customer Disambiguation Sheet**:
     - "దయచేసి సరైన కస్టమర్‌ను ఎంచుకోండి" (Please select the correct customer).
2. **Ambiguous Amount or Intent**:
   - Utterance: `"రమేష్ ఖాతాలో 100 కట్ చెయ్యి"` (cut 100).
   - "Cut" could mean payment, discount, or mistake correction.
   - Action: The app asks:
     - `"రమేష్ కి 100 రూపాయలు చెల్లింపుగా (Payment) రికార్డ్ చేయాలా లేక డిస్కౌంట్ ఇవ్వాలా?"`
3. **Payment Exceeding Outstanding Debt**:
   - Current balance: ₹200.00 (20,000 paise).
   - Customer pays: ₹300.00 (30,000 paise).
   - Action: Server warns that payment exceeds balance by ₹100.00. The app displays a prompt:
     - `"చెల్లింపు బాకీ కంటే ₹100.00 ఎక్కువగా ఉంది. అడ్వాన్స్‌గా జమ చేయాలా?"` (Record as Advance / Credit surplus).
