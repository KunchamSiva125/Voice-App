# Free-Tier Cloud Deployment Guide & Operational Quotas

## 1. Hosting Services & Free-Tier Quotas Assessment

| Component | Target Service | Current Tier Specifications | Quotas, Costs & Potential Limitations |
|---|---|---|---|
| **Database** | MongoDB Atlas | **M0 Free Cluster** | **Storage**: 512 MB storage limit. Shared CPU/RAM. Supports replica set operations. **Limitation**: Inactivity pause if unaccessed for 60 days. No point-in-time restore (requires manual mongodump). |
| **Backend API** | Render / Koyeb / Railway | **Free / Hobby Tier** | **Render Free Tier**: 512 MB RAM, 0.1 vCPU. Spins down after 15 minutes of idle time. **Cold start penalty**: 45-60 seconds on first morning request. **Render Free Limit**: 750 free instance hours/month. |
| **Admin Portal** | Vercel / Cloudflare Pages | **Hobby / Free Tier** | **Bandwidth**: 100 GB/month. Unlimited static requests, automatic HTTPS/SSL certificates, global CDN edge delivery. |
| **Speech STT** | Android Native SpeechRecognizer | **Device Built-in** | **Cost**: Free (uses on-device speech engine or Google Play Services). **Limitation**: Requires Google app on phone; accuracy depends on user's Telugu accent. |

> [!WARNING]
> **Zero Cost Disclaimer**: Free-tier cloud limits are subject to provider policy changes. Never store confidential hotel tax IDs or banking credentials in public repositories. Always back up your MongoDB database weekly using `mongodump`.

---

## 2. Step 1: Deploy MongoDB Atlas (Free M0 Cluster)

1. Sign up at [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas).
2. Create a **Shared M0 Free Cluster**:
   - Cloud Provider: **AWS** or **Google Cloud**.
   - Region: Select **Mumbai (ap-south-1)** for lowest latency to India.
3. Security Setup:
   - **Database Access**: Create a dedicated database user (e.g. `tiffin_app_user`) with read/write privileges on `tiffin_ledger_db`.
   - **Network Access**: Add IP `0.0.0.0/0` (Allow from anywhere) or whitelist your cloud server IP.
4. Obtain the Connection String:
   ```
   mongodb+srv://tiffin_app_user:<PASSWORD>@cluster0.abcde.mongodb.net/tiffin_ledger_db?retryWrites=true&w=majority
   ```

---

## 3. Step 2: Deploy Spring Boot Backend (Render / Docker)

1. Create a `Dockerfile` in `backend/` or connect your GitHub repository directly to Render.
2. Create a new **Web Service** on Render:
   - **Environment**: Java or Docker
   - **Build Command**: `mvn clean package -DskipTests`
   - **Start Command**: `java -jar target/tiffin-ledger-backend-1.0.0.jar`
3. Configure Environment Variables in Render Dashboard:
   ```
   PORT=8080
   SPRING_PROFILES_ACTIVE=prod
   MONGODB_URI=mongodb+srv://tiffin_app_user:<PASSWORD>@cluster0.abcde.mongodb.net/tiffin_ledger_db?retryWrites=true&w=majority
   JWT_SECRET=c4897f225d30df9313bbd59a721c5b8b92d6e32d665b16e872d8816c14e08f2a
   INITIAL_OWNER_USERNAME=owner@tiffin.local
   INITIAL_OWNER_PASSWORD=ChangeMeSecurely123!
   CORS_ALLOWED_ORIGINS=https://your-admin-portal.vercel.app,http://localhost:5173
   ```
4. Click **Deploy**. Note down the assigned public HTTPS URL: `https://tiffin-backend.onrender.com`.

---

## 4. Step 3: Deploy Admin Web Portal (Vercel)

1. Push the code to GitHub.
2. Sign in to [Vercel](https://vercel.com) and click **Add New Project**.
3. Select your repository and set the **Root Directory** to `admin-portal`.
4. Configure Build Settings:
   - Framework Preset: **Vite**
   - Build Command: `npm run build`
   - Output Directory: `dist`
5. Add Environment Variable:
   ```
   VITE_API_URL=https://tiffin-backend.onrender.com/api
   ```
6. Click **Deploy**. Vercel will provision an SSL-secured custom URL (e.g., `https://tiffin-khata-admin.vercel.app`).

---

## 5. Step 4: Configure Mobile Application for Production

1. Update `mobile-app/lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'https://tiffin-backend.onrender.com/api';
   ```
2. Build the Android release APK (see [APK_BUILD.md](file:///d:/Voice%20App/docs/APK_BUILD.md)).
3. Sideload the APK onto the owner and family members' Android phones.
