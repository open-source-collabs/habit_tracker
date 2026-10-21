# Track Free — Privacy Policy Web Deployment

This directory contains the standalone, production-ready Privacy Policy website for **Track Free** (`co.trackfree.solforge`), optimized for instant deployment to **Vercel**.

---

## 🚀 How to Deploy to Vercel (3 Quick Options)

### Option 1: Vercel CLI (Fastest — 30 seconds)

1. Open your terminal in this directory:
   ```bash
   cd privacy_policy_web
   ```
2. Run the Vercel deploy command (install Vercel globally or use npx):
   ```bash
   npx vercel
   ```
3. Follow the 3 prompts:
   - *Set up and deploy?* → `y`
   - *Which scope?* → select your Vercel account
   - *Link to existing project?* → `n`
   - *Project name?* → `track-free-privacy` (or whatever you prefer)
   - *In which directory is your code located?* → `./`
4. For production:
   ```bash
   npx vercel --prod
   ```
5. You'll instantly receive your live URL: `https://track-free-privacy.vercel.app`

---

### Option 2: Drag & Drop via Vercel Web Dashboard (No CLI needed)

1. Go to [https://vercel.com/new](https://vercel.com/new).
2. If using the Vercel web import, drag and drop this `privacy_policy_web` folder into the dashboard.
3. Click **Deploy**.
4. Done!

---

### Option 3: Deploy via GitHub / Git Repository

If you push this repository to GitHub:
1. Log in to [Vercel](https://vercel.com) and click **"Add New Project"**.
2. Select your `habit_tracker` repository.
3. In the configuration settings:
   - **Root Directory**: Click *Edit* and select `privacy_policy_web`.
   - **Framework Preset**: *Other* (static HTML).
4. Click **Deploy**.
5. Every time you push updates to Git, Vercel will automatically redeploy!

---

## ⚙️ Customization

Before deploying, open `index.html` and verify the contact email:
- Search for `support@trackfree.app` and replace it with your desired support address if different.

---

## 📱 Store Listing & App Config

Once your Vercel URL is live (e.g. `https://track-free-privacy.vercel.app`):
1. **Google Play Console**:
   - Go to *App Content → Privacy Policy* and paste your Vercel URL.
2. **Apple App Store Connect**:
   - Go to *App Information → Privacy Policy URL* and paste your Vercel URL.
3. **In the Flutter app build**:
   ```bash
   flutter build appbundle \
     --dart-define=PRIVACY_POLICY_URL=https://track-free-privacy.vercel.app \
     --dart-define=SUPPORT_EMAIL=support@trackfree.app
   ```

