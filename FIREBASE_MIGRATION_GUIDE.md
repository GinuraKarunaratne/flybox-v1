# Firebase Migration Guide - FlyBox

## Migration Completed! ✅

Your FlyBox app has been successfully configured to use the new Firebase project: **flyboxbuild**

---

## What Was Done

### 1. ✅ Android Package Name Updated
- Changed from: `com.example.flutter_application_1`
- Changed to: `com.example.flutter.flyboxbuild`
- Updated in: `android/app/build.gradle.kts` and `MainActivity.kt`

### 2. ✅ Firebase Configuration Files Updated
- `google-services.json` - Updated with new project credentials
- `firebase_options.dart` - Generated for Android platform
- `firebase.json` - Updated project references

### 3. ✅ Security Rules Created
- `firestore.rules` - Comprehensive security rules for all collections
- `firestore.indexes.json` - Performance indexes for queries

---

## Next Steps - REQUIRED IN FIREBASE CONSOLE

### Step 1: Apply Firestore Security Rules

1. Go to: https://console.firebase.google.com/project/flyboxbuild/firestore/rules
2. Click "Edit rules"
3. Copy and paste the contents of `firestore.rules` file
4. Click "Publish"

### Step 2: Create Firestore Indexes

1. Go to: https://console.firebase.google.com/project/flyboxbuild/firestore/indexes
2. Click "Add index manually" or use Firebase CLI to deploy `firestore.indexes.json`

**Manual indexes needed:**
- `journeys` collection:
  - Fields: `status` (Ascending), `createdAt` (Descending)
  - Fields: `userId` (Ascending), `createdAt` (Descending)
  - Fields: `fromLowercase` (Ascending), `toLowercase` (Ascending), `date` (Ascending)
  - Fields: `isAvailable` (Ascending), `status` (Ascending), `createdAt` (Descending)

- `shipments` collection:
  - Fields: `userId` (Ascending), `createdAt` (Descending)
  - Fields: `userId` (Ascending), `status` (Ascending), `createdAt` (Descending)

- `notifications` collection:
  - Fields: `userId` (Ascending), `createdAt` (Descending)
  - Fields: `userId` (Ascending), `isRead` (Ascending), `createdAt` (Descending)

### Step 3: Verify Firestore Database is Created

1. Go to: https://console.firebase.google.com/project/flyboxbuild/firestore
2. Ensure database is created in your preferred region
3. If not, create it in "Test mode" for now (we've added proper security rules)

---

## Storage Workaround (Free Plan)

Since you're on the **Spark (free) plan without Firebase Storage**, here are your options:

### Option A: Upgrade to Blaze Plan (Recommended)
- Upgrade at: https://console.firebase.google.com/project/flyboxbuild/usage
- Pay-as-you-go: First 5GB storage & 50K downloads per month are FREE
- Only pay for usage beyond free tier

### Option B: Use Alternative Storage (Current Workaround)
Your app currently uses `firebase_storage` package. To work without it:

1. **For ticket images**: Store as base64 strings in Firestore (not recommended for production)
2. **Use Cloudinary or ImgBB**: Free image hosting services
3. **Use device local storage**: Store images locally with file paths in Firestore

### Option C: Remove Storage Features Temporarily
Comment out storage-related code until you upgrade:
- In `pubspec.yaml`: Comment out `firebase_storage: ^12.3.2`
- In traveler setup: Disable ticket image upload temporarily

**Current Status:** Storage-related code is still in place but won't work until you:
- Enable Storage in Firebase Console (requires Blaze plan), OR
- Implement one of the workarounds above

---

## Database Collections Structure

Your new Firestore database should have these collections:

### 1. **users** Collection
```
{
  uid: string
  fullName: string
  email: string
  phone: string
  userType: "Sender" | "Traveler"
  isEmailVerified: boolean
  isPhoneVerified: boolean
  createdAt: timestamp
  lastUpdated: timestamp
  isActive: boolean
  profileCompleted: boolean
}
```

### 2. **journeys** Collection (Traveler Offerings)
```
{
  userId: string
  userEmail: string
  userName: string
  userPhone: string
  from: string
  to: string
  date: string
  time: string
  ticketPrice: number
  ticketImageUrl: string (optional)
  ticketImageUploaded: boolean
  packageType: string
  hateToCarry: string
  availableWeight: number
  remainingWeight: number
  dimensions: {
    length: number
    width: number
    height: number
  }
  status: "active" | "inactive" | "completed"
  isAvailable: boolean
  bookings: array
  totalBookings: number
  createdAt: timestamp
  lastUpdated: timestamp
  fromLowercase: string
  toLowercase: string
  routeKey: string
  journeyType: "traveler_offering"
  offerType: "luggage_space"
}
```

### 3. **shipments** Collection (Sender Requests)
```
{
  userId: string
  destination: { from, to, date }
  packageDetails: { type, weight, dimensions }
  receiverInfo: { name, phone, address }
  selectedTraveler: { travelerId, travelerName }
  payment: { amount, method, status }
  status: "draft" | "paid" | "in_transit" | "delivered"
  createdAt: timestamp
  updatedAt: timestamp
}
```

### 4. **notifications** Collection
```
{
  userId: string
  title: string
  message: string
  type: "general" | "journey_created" | "booking_received"
  isRead: boolean
  createdAt: timestamp
  priority: "normal" | "high"
}
```

### 5. **destinations** Collection (Optional)
```
{
  name: string
  country: string
  code: string
}
```

---

## Testing Your Setup

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk --debug
```

### 2. Test Firebase Connection
Run the app and check logs for:
- `✅ Firebase initialized successfully`
- No permission errors in Firestore operations

### 3. Test Authentication
- Register a new user
- Login with existing credentials
- Check Firebase Console → Authentication for new users

### 4. Test Firestore
- Create a traveler journey
- Check Firebase Console → Firestore for new documents

---

## Common Issues & Solutions

### Issue: "Permission denied" errors
**Solution:** Apply Firestore security rules from `firestore.rules` file

### Issue: "Index required" errors
**Solution:** Create the indexes from `firestore.indexes.json` or click the auto-generated link in error

### Issue: Package name mismatch
**Solution:** Verify `android/app/build.gradle.kts` has `com.example.flutter.flyboxbuild`

### Issue: Firebase not initializing
**Solution:**
1. Check `google-services.json` is in `android/app/`
2. Verify package names match in all files
3. Run `flutter clean` and rebuild

---

## Old vs New Configuration

| Property | Old (flybox-377d6) | New (flyboxbuild) |
|----------|-------------------|-------------------|
| Project ID | flybox-377d6 | flyboxbuild |
| Project Number | 850281785375 | 1006335746106 |
| Package Name | com.example.flutter_application_1 | com.example.flutter.flyboxbuild |
| API Key | AIzaSyD7v9EMZuuILCLyVcAAwNkDvFcHpaStiz8 | AIzaSyDtssJyldXn5-TGJ9zDHcQ5U12TcXayEV4 |
| Storage Bucket | flybox-377d6.firebasestorage.app | flyboxbuild.firebasestorage.app |

---

## Support & Resources

- Firebase Console: https://console.firebase.google.com/project/flyboxbuild
- FlutterFire Documentation: https://firebase.flutter.dev/
- Firestore Pricing: https://firebase.google.com/pricing

---

**Migration completed on:** 2025-11-21
**Migrated by:** Claude Code Assistant
