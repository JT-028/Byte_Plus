# Quick Setup Guide - Sensitive Files

This guide helps you set up Firebase configuration files for local development.

## 🚀 Quick Start

### Step 1: Copy Template Files

```bash
# Environment variables
cp .env.template .env

# Firebase options (if not using FlutterFire CLI)
cp firebase_options.dart.template lib/firebase_options.dart
```

### Step 2: Get Firebase Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to **Project Settings** (gear icon) → **General**

### Step 3: Download Platform-Specific Files

**Android:**
1. In Firebase Console → Project Settings → Your Apps
2. Select your Android app
3. Click "Download google-services.json"
4. Place it in `android/app/google-services.json`

**iOS:**
1. In Firebase Console → Project Settings → Your Apps
2. Select your iOS app
3. Click "Download GoogleService-Info.plist"
4. Place it in `ios/Runner/GoogleService-Info.plist`

### Step 4: Fill in Configuration

**Option A: Use FlutterFire CLI (Recommended)**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure automatically
flutterfire configure --project=your-firebase-project-id
```

This will automatically generate `lib/firebase_options.dart` with the correct values.

**Option B: Manual Configuration**

Edit `lib/firebase_options.dart` with values from Firebase Console:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIza...', // From Firebase Console
  appId: '1:123456789:android:abcd...', // From Firebase Console
  messagingSenderId: '123456789', // From Firebase Console
  projectId: 'your-project-id', // Your Firebase project ID
  storageBucket: 'your-project-id.appspot.com',
);
```

### Step 5: Verify Files Are Ignored

```bash
# Check if files are properly ignored
git status

# You should NOT see these files listed:
# - lib/firebase_options.dart
# - android/app/google-services.json
# - ios/Runner/GoogleService-Info.plist
# - .env

# If they appear, ensure .gitignore is properly configured
```

### Step 6: Environment Variables (Optional)

Edit `.env` file for additional configuration:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
```

## ⚠️ Important Reminders

### DO:
✅ Keep real credentials in local files only  
✅ Use template files for reference  
✅ Verify files are in .gitignore before committing  
✅ Use different Firebase projects for dev/staging/prod  
✅ Share template files with team members  

### DON'T:
❌ Commit real credentials to version control  
❌ Share credentials in chat or email  
❌ Use production credentials for development  
❌ Hardcode API keys in source code  
❌ Remove files from .gitignore  

## 🔍 Verification Checklist

Before making your first commit:

- [ ] `lib/firebase_options.dart` exists but is not staged for commit
- [ ] `android/app/google-services.json` exists but is not staged for commit
- [ ] `ios/Runner/GoogleService-Info.plist` exists but is not staged for commit
- [ ] `.env` exists but is not staged for commit
- [ ] Template files (.template) are safe to commit
- [ ] `git status` shows none of the above sensitive files
- [ ] App runs successfully with Firebase connected

## 🆘 Troubleshooting

**Problem: "Firebase not initialized" error**
- Solution: Ensure `firebase_options.dart` exists in `lib/` folder
- Verify the values are correct (check Firebase Console)

**Problem: "google-services.json not found"**
- Solution: Download from Firebase Console and place in `android/app/`
- Check file name is exactly `google-services.json` (no .txt extension)

**Problem: Files appear in git status**
- Solution: Ensure files are listed in `.gitignore`
- Run: `git rm --cached path/to/file` to untrack
- Commit the .gitignore changes

**Problem: iOS build fails**
- Solution: Ensure `GoogleService-Info.plist` is in `ios/Runner/`
- Open Xcode and verify the file is added to the target

## 📞 Need Help?

If you're stuck:
1. Check [SECURITY.md](SECURITY.md) for detailed guidelines
2. Review [README.md](README.md) Firebase Setup section
3. Contact the development team

---

**Remember**: Security starts with YOU! 🔒
