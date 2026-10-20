# Local Development Instructions

This guide provides instructions to run the **Telugu Voice-Based Tiffin Hotel Debt Management System** locally on Windows, macOS, or Linux.

---

## 1. Prerequisites

- **Java JDK 21+** (Java 21 LTS or Java 27)
- **Apache Maven 3.9+**
- **Node.js 20+** & **npm 10+**
- **MongoDB** (Cloud MongoDB Atlas free M0 cluster OR local `mongod`)
- **Flutter SDK 3.x+** (for Android app development)

---

## 2. Backend Setup & Run

1. Navigate to the backend directory:
   ```bash
   cd "d:/Voice App/backend"
   ```

2. Configure environment variables (or set in `application.yml`):
   ```bash
   # MongoDB Atlas Connection string or local instance
   export MONGODB_URI="mongodb+srv://<username>:<password>@cluster0.mongodb.net/tiffin_ledger_db?retryWrites=true&w=majority"
   export JWT_SECRET="your_secure_256_bit_secret_key_minimum_32_characters"
   ```

3. Run the automated test suite:
   ```bash
   mvn test
   ```
   *Expected result: 22 tests passing with BUILD SUCCESS.*

4. Start the Spring Boot REST API:
   ```bash
   mvn spring-boot:run
   ```
   *The server starts on port `8080` (or `PORT` variable).*

5. Verify Swagger UI:
   Open browser at: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)

6. Default Bootstrap Owner Credentials:
   - **Username**: `owner@tiffin.local`
   - **Password**: `Password123!`

---

## 3. React Admin Portal Setup & Run

1. Navigate to the admin portal directory:
   ```bash
   cd "d:/Voice App/admin-portal"
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the Vite development server:
   ```bash
   npm run dev
   ```
   *The portal starts on `http://localhost:5173` with automatic API proxying to `http://localhost:8080`.*

4. Build for production:
   ```bash
   npm run build
   ```

---

## 4. Mobile App Setup & Run (Flutter)

1. Navigate to the mobile application directory:
   ```bash
   cd "d:/Voice App/mobile-app"
   ```

2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

3. Configure Backend Host in `lib/config/api_config.dart`:
   - Android Emulator: `http://10.0.2.2:8080/api`
   - Physical Android Device over Wi-Fi: `http://<YOUR_LAN_IP>:8080/api` (e.g., `http://192.168.1.15:8080/api`)

4. Run on connected Android device or emulator:
   ```bash
   flutter run
   ```
