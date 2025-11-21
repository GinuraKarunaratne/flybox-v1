# 🚀 Quick Setup - FlyBox Firebase Migration

## ✅ COMPLETED
- Android package name updated
- Firebase configuration files updated
- Security rules created
- Indexes defined
- Migration guide created

---

## 🔥 FIREBASE CONSOLE - DO THESE 3 STEPS NOW

### 1️⃣ Apply Firestore Security Rules (CRITICAL)

**Go to:** https://console.firebase.google.com/project/flyboxbuild/firestore/rules

**Copy the entire contents of `firestore.rules` file and paste it there, then click Publish**

---

### 2️⃣ Create Firestore Database (If not done)

**Go to:** https://console.firebase.google.com/project/flyboxbuild/firestore

**Click "Create database"** → Choose "Test mode" → Select region (asia-south1 for Sri Lanka)

---

### 3️⃣ Create Essential Firestore Indexes

**Go to:** https://console.firebase.google.com/project/flyboxbuild/firestore/indexes

**Click "Add index manually"** and create these TWO critical indexes:

**Index 1 - For Journeys List:**
- Collection ID: `journeys`
- Fields to index:
  - `status` → Ascending
  - `createdAt` → Descending
- Query scope: Collection

**Index 2 - For User's Journeys:**
- Collection ID: `journeys`
- Fields to index:
  - `userId` → Ascending
  - `createdAt` → Descending
- Query scope: Collection

---

## 📱 TEST YOUR APP

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run on device/emulator
flutter run

# Or build APK
flutter build apk --debug
```

**Expected logs:**
- ✅ Firebase initialized successfully
- No permission errors

---

## ⚠️ KNOWN LIMITATIONS

### Storage Not Available (Free Plan)
Your app uses `firebase_storage` for ticket image uploads, but Storage requires the **Blaze (pay-as-you-go) plan**.

**Options:**
1. **Upgrade to Blaze plan** (first 5GB free monthly) - https://console.firebase.google.com/project/flyboxbuild/usage
2. **Disable ticket uploads** temporarily (comment out storage code)
3. **Use alternative storage** (Cloudinary, ImgBB, etc.)

---

## 🆘 TROUBLESHOOTING

**Permission denied errors?**
→ Apply security rules from `firestore.rules`

**"Index required" errors?**
→ Click the link in the error OR create indexes manually

**App won't build?**
→ Run: `flutter clean && flutter pub get`

**Firebase not initializing?**
→ Check `google-services.json` is in `android/app/`

---

## 📚 FULL DOCUMENTATION

See `FIREBASE_MIGRATION_GUIDE.md` for complete details on:
- All collections structure
- All indexes needed
- Storage workarounds
- Old vs New configuration comparison

---

**Need help?** Check the logs for specific error messages!
