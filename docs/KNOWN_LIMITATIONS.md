# Known Limitations & Future Enhancements Roadmap

## 1. Release 1.0 Known Limitations

### 1.1 Online-First Architecture (No Offline Writes)
- **Design Rationale**: To prevent dangerous balance divergences, lost ledger updates, and split-brain conflicts when multiple family members operate separate cash counters simultaneously, **Version 1.0 requires active internet connectivity for all ledger mutations**.
- **User Disclosure**: The mobile app clearly displays an **Online / Offline connection badge** at the top of the screen and informs the user if a command cannot be saved due to an internet drop.

### 1.2 Device Speech-to-Text Dependency
- **Current Behavior**: The mobile app utilizes Android's native `SpeechRecognizer` service (backed by Google Play Speech Services). On devices where Google services are disabled or lack Telugu language packs, recognition falls back to the manual entry screen or requires an active internet connection for cloud transcription.
- **Dialect Variations**: Heavy regional slang or non-standard Telugu dialects with background kitchen blender/fryer noise may yield transcription errors. The app protects against this by showing the recognized text on screen before execution.

### 1.3 Text-to-Speech Telugu Voice Availability
- **Current Behavior**: If the user's Android phone does not have the Google Text-to-Speech Telugu (`te-IN`) high-definition voice installed, Android falls back to the default system speech synthesizer, which may pronounce Telugu text with an English accent.

### 1.4 Single-Hotel Ledger Scope
- **Current Behavior**: Version 1.0 is architected for a single independent tiffin hotel with multiple family members sharing the same ledger. Multi-branch chains or franchise multi-tenancy are not included in this release.

---

## 2. Future Enhancements Roadmap (Version 2.0+)

1. **Local SQLite Cache & Conflict-Free Offline Queue**:
   - Store read-only customer rosters locally.
   - Queue offline credit requests with unique client UUIDs.
   - Synchronize with vector clocks or optimistic locking when internet resumes, alerting the cashier to review any concurrent conflict.

2. **WhatsApp Receipt & Debt Reminder Automation**:
   - One-tap WhatsApp Web / API button to send a formatted Telugu statement directly to the customer:
     *"నమస్కారం రమేష్ గారు, శ్రీ లక్ష్మి టిఫిన్ సెంటర్ లో మీ ప్రస్తుత బాకీ ₹350.00."*

3. **UPI Dynamic QR Code Generator**:
   - When recording payments, display a dynamic UPI QR code on the phone screen with the exact balance encoded (`upi://pay?pa=owner@upi&am=350.00&tn=TiffinKhata`).

4. **Multi-Hotel Tenant Partitioning**:
   - Extend MongoDB schema with `hotelId` compound indexes, allowing a single deployed backend to serve multiple independent tiffin hotels with complete data isolation.

5. **PDF Customer Ledger Statements**:
   - Server-side generation of branded monthly PDF passbooks with date stamps for corporate parcel accounts.
