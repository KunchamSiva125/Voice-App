# Mahima Tiffin Centre (మహిమ టిఫిన్ సెంటర్)
**(Voice-Based Tiffin Hotel Debt Management & Ledger System)**

Production-grade debt management application designed for Mahima Tiffin Centre, replacing the traditional physical notebook (బాకీల చిట్టా) with a simple voice application in Telugu and a modern web admin portal.

---

## 🚀 Key Features

- **🎙️ Telugu Voice Commands**:
  - Add customer credit: *"రమేష్ కి 100 రూపాయలు అప్పు రాయి"*
  - Record customer payment: *"రమేష్ వంద రూపాయలు ఇచ్చాడు"*
  - Check balance: *"రమేష్ అప్పు ఎంత ఉంది?"*
  - Apply discount/waiver: *"రమేష్ అప్పులో 50 రూపాయలు డిస్కౌంట్ ఇవ్వు"*
  - Daily report query: *"ఈ రోజు మొత్తం కలెక్షన్ ఎంత?"*
- **💰 Financial Ledger Integrity**:
  - Strict integer paise arithmetic (`amountPaise`, `balanceEffectPaise`). Never uses floating point.
  - Zero-sum double-entry reversal policy: Compensatory cancellation preserving complete audit history.
  - Idempotency key protection: Safe replaying of duplicate microphone taps and network retries.
  - Excess payment validation: Blocks accidental overpayment without explicit advance confirmation.
- **👥 Role-Based Access Control (RBAC)**:
  - `OWNER`: Master account, user management, notebook migration, audit trails, CSV exports.
  - `ADMIN`: Customer details, authorized transaction corrections and discounts.
  - `FAMILY_MEMBER`: Quick counter operations, search, balance queries, credit entries, payments.
- **📱 Complete Mobile Application (Flutter First)**:
  - Flutter 3.x & Dart with Material 3 design, 100% mobile-friendly for all screens.
  - Unified mobile experience containing both Voice & Quick Counter and full Admin capabilities:
    - 🎙️ Telugu Speech Recognition & Speakback (`te_IN` TTS)
    - 📊 Mobile Financial Dashboard with real-time KPI metrics & Top Debtors ranking
    - 👥 Customer Directory with Search, Aliases, Profile Editing, and Account Archival
    - 📖 General Ledger with custom date range and transaction type filtering
    - 🔄 Strict Double-Entry Corrections & Reversals with mandatory audit justifications
    - 📘 Physical Notebook Balance Migration Wizard ("పుస్తకం బాకీల నమోదు")
    - 📈 Historical Business Reports with Date Picker & spoken audio summary
    - 👤 User & Staff Management with Role-Based Access Control (`OWNER`, `ADMIN`, `FAMILY_MEMBER`)
    - 🛡️ Immutable System Audit Trail viewer
    - 💾 CSV Data Exports (Customers & Transactions) and Cloud Backup Utilities
  - Responsive navigation drawer and bottom sheets designed specifically for touch devices and smartphones.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile & Admin App** | Flutter 3.x, Dart, Material 3, Android SpeechRecognizer (`te_IN`), Android TTS, Provider, Responsive Web/Mobile |
| **Backend API** | Java 21, Spring Boot 3.3.x, Spring Security (Stateless JWT), Spring Data MongoDB, OpenAPI 3 / Swagger |
| **Database** | MongoDB Atlas (Cloud) / Local MongoDB, Integer Paise Invariants, Asia/Kolkata Time Zone |

---

## ⚡ Quick Start

### 1. Spring Boot Backend
```bash
cd backend
mvn test                   # Runs all 22 financial & voice parser tests
mvn spring-boot:run        # Starts API on http://localhost:8080
```
- **Swagger Documentation**: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- **Bootstrap Owner Login**: `owner@tiffin.local` / `Password123!`

### 2. Complete Flutter Mobile & Admin Application
```bash
cd mobile-app
flutter pub get
flutter run                # Runs on connected Android device or emulator
flutter run -d chrome      # Runs on browser with mobile-responsive view
```
- Or simply run [run-mobile.bat](file:///d:/Voice%20App/run-mobile.bat) / [run-portal.bat](file:///d:/Voice%20App/run-portal.bat)
- Build APK: `flutter build apk --release`

---

## 📚 Complete Project Documentation

- [Architecture & Invariants Specification](file:///d:/Voice%20App/docs/ARCHITECTURE.md)
- [REST API Specification](file:///d:/Voice%20App/docs/API_SPEC.md)
- [Telugu Voice Command & Grammar Guide](file:///d:/Voice%20App/docs/VOICE_COMMAND_GUIDE.md)
- [MongoDB Schema & Index Setup](file:///d:/Voice%20App/docs/MONGO_SETUP.md)
- [Local Development Guide](file:///d:/Voice%20App/docs/LOCAL_DEV.md)
- [Free-Tier Deployment Guide](file:///d:/Voice%20App/docs/DEPLOYMENT.md)
- [Android APK Build Instructions](file:///d:/Voice%20App/docs/APK_BUILD.md)
- [Backup & Disaster Recovery Procedures](file:///d:/Voice%20App/docs/BACKUP_RECOVERY.md)
- [Manual Voice Testing Checklist & Scenarios](file:///d:/Voice%20App/docs/TELUGU_VOICE_TESTING_CHECKLIST.md)
- [Known Limitations & Future Roadmap](file:///d:/Voice%20App/docs/KNOWN_LIMITATIONS.md)
- [Sample Dataset JSON](file:///d:/Voice%20App/data/sample-dataset.json)

---

## 🔒 Security & Privacy

- Passwords hashed using BCrypt (cost factor 12).
- Zero audio retention: Audio speech is converted to text on-device; raw voice is never retained on disk or transmitted.
- All secrets and connection strings configured via `.env` (see [.env.example](file:///d:/Voice%20App/.env.example)).
