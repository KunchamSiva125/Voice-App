# Repository Structure: Telugu Voice Tiffin Hotel Debt Management

```
d:\Voice App\
├── backend\                                  # Spring Boot 3.3.x REST API
│   ├── pom.xml                               # Maven Project Descriptor with Java 21 release target
│   └── src\
│       ├── main\
│       │   ├── java\com\tiffin\ledger\
│       │   │   ├── TiffinLedgerApplication.java
│       │   │   ├── config\                   # Security, OpenAPI, Web MVC & CORS configs
│       │   │   │   ├── OpenApiConfig.java
│       │   │   │   └── SecurityConfig.java
│       │   │   ├── controller\               # REST Controllers
│       │   │   │   ├── AdminExportController.java
│       │   │   │   ├── AdminUserController.java
│       │   │   │   ├── AuthController.java
│       │   │   │   ├── CustomerController.java
│       │   │   │   ├── HealthController.java
│       │   │   │   ├── ReportController.java
│       │   │   │   ├── TransactionController.java
│       │   │   │   └── VoiceCommandController.java
│       │   │   ├── domain\                   # MongoDB Document Entities & Enums
│       │   │   │   ├── AuditEvent.java
│       │   │   │   ├── Customer.java
│       │   │   │   ├── CustomerStatus.java
│       │   │   │   ├── LedgerTransaction.java
│       │   │   │   ├── Role.java
│       │   │   │   ├── TransactionStatus.java
│       │   │   │   ├── TransactionType.java
│       │   │   │   └── User.java
│       │   │   ├── dto\                      # Typed Data Transfer Objects
│       │   │   │   ├── auth\...
│       │   │   │   ├── customer\...
│       │   │   │   ├── report\...
│       │   │   │   ├── transaction\...
│       │   │   │   └── voice\...
│       │   │   ├── exception\                # Centralized Exception Handler & Models
│       │   │   │   ├── ExcessPaymentException.java
│       │   │   │   ├── GlobalExceptionHandler.java
│       │   │   │   └── ResourceNotFoundException.java
│       │   │   ├── repository\               # Spring Data MongoDB Repositories
│       │   │   │   ├── AuditEventRepository.java
│       │   │   │   ├── CustomerRepository.java
│       │   │   │   ├── LedgerTransactionRepository.java
│       │   │   │   └── UserRepository.java
│       │   │   ├── security\                 # JWT Token Provider & UserPrincipal
│       │   │   │   ├── CustomUserDetailsService.java
│       │   │   │   ├── JwtAuthenticationFilter.java
│       │   │   │   ├── JwtTokenProvider.java
│       │   │   │   └── UserPrincipal.java
│       │   │   ├── service\                  # Business Service & Ledger Rules
│       │   │   │   ├── AuditService.java
│       │   │   │   ├── AuthService.java
│       │   │   │   ├── CustomerService.java
│       │   │   │   ├── ExportService.java
│       │   │   │   ├── LedgerService.java
│       │   │   │   ├── ReportService.java
│       │   │   │   ├── UserService.java
│       │   │   │   └── VoiceCommandParserService.java
│       │   │   └── util\                     # Utility Helpers
│       │   │       ├── CurrencyUtil.java
│       │   │       ├── DateUtil.java
│       │   │       └── TeluguVoiceUtil.java
│       │   └── resources\
│       │       └── application.yml
│       └── test\                             # JUnit 5 & Mockito Unit/Integration Tests
│           └── java\com\tiffin\ledger\
│               ├── security\SecurityRolePermissionTest.java
│               ├── service\LedgerServiceTest.java
│               ├── service\ReportServiceTest.java
│               ├── service\VoiceCommandParserServiceTest.java
│               └── util\CurrencyUtilTest.java
│
├── admin-portal\                             # React 18 + Vite + TypeScript Admin Web Portal
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── index.html
│   └── src\
│       ├── api\
│       │   └── client.ts                     # Axios client with JWT interceptor & types
│       ├── components\
│       │   ├── ProtectedRoute.tsx
│       │   └── Sidebar.tsx
│       ├── pages\
│       │   ├── AuditLogs.tsx
│       │   ├── Corrections.tsx
│       │   ├── CustomerDetail.tsx
│       │   ├── Customers.tsx
│       │   ├── Dashboard.tsx
│       │   ├── Exports.tsx
│       │   ├── Login.tsx
│       │   ├── OpeningBalanceMigration.tsx
│       │   ├── Reports.tsx
│       │   ├── Transactions.tsx
│       │   └── UserManagement.tsx
│       ├── styles\
│       │   └── index.css                     # Modern Glassmorphic CSS design system
│       ├── App.tsx
│       ├── main.tsx
│       └── vite-env.d.ts
│
├── mobile-app\                               # Flutter Android Mobile Application
│   ├── pubspec.yaml
│   ├── android\app\src\main\AndroidManifest.xml
│   ├── lib\
│   │   ├── config\api_config.dart
│   │   ├── models\
│   │   │   ├── customer_model.dart
│   │   │   ├── daily_report_model.dart
│   │   │   ├── transaction_model.dart
│   │   │   ├── user_model.dart
│   │   │   └── voice_command_model.dart
│   │   ├── providers\
│   │   │   ├── auth_provider.dart
│   │   │   ├── customer_provider.dart
│   │   │   ├── ledger_provider.dart
│   │   │   └── voice_command_provider.dart
│   │   ├── screens\
│   │   │   ├── customer_detail_screen.dart
│   │   │   ├── customer_list_screen.dart
│   │   │   ├── disambiguation_sheet.dart
│   │   │   ├── home_voice_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── manual_entry_screen.dart
│   │   ├── services\
│   │   │   ├── api_service.dart
│   │   │   ├── speech_recognition_service.dart
│   │   │   ├── storage_service.dart
│   │   │   ├── telugu_voice_parser.dart
│   │   │   └── text_to_speech_service.dart
│   │   ├── widgets\
│   │   │   ├── quick_stat_card.dart
│   │   │   └── voice_wave_visualizer.dart
│   │   └── main.dart
│   └── test\
│       └── telugu_parser_test.dart
│
├── data\
│   └── sample-dataset.json                   # Realistic seed data with Telugu names & debts
├── docs\
│   ├── ARCHITECTURE.md                       # Component diagrams & data flows
│   ├── API_SPEC.md                           # Complete OpenAPI REST specification
│   ├── MONGO_SETUP.md                        # Database collections, schemas & indexes
│   ├── VOICE_COMMAND_GUIDE.md                # Telugu grammar & vocabulary rules
│   ├── LOCAL_DEV.md                          # Step-by-step local running instructions
│   ├── DEPLOYMENT.md                         # Free-tier hosting setup & quotas
│   ├── APK_BUILD.md                          # Flutter APK compilation guide
│   ├── BACKUP_RECOVERY.md                    # Disaster recovery & mongodump guide
│   ├── TELUGU_VOICE_TESTING_CHECKLIST.md     # Voice utterance QA checklist
│   └── KNOWN_LIMITATIONS.md                  # Release limitations & future v2 roadmap
├── .env.example                              # Production environment template
└── README.md                                 # Project overview & quick start
```
