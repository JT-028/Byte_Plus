# Security Guidelines

This document outlines security best practices and sensitive files that must be kept private in the BytePlus project.

## 🔒 Critical: Never Commit These Files

### Firebase Configuration
- `/lib/firebase_options.dart` - Contains Firebase API keys and project IDs
- `/android/app/google-services.json` - Android Firebase configuration
- `/ios/Runner/GoogleService-Info.plist` - iOS Firebase configuration
- `/web/firebase-config.js` - Web Firebase configuration

### Service Account Keys
- `serviceAccountKey.json` - Firebase Admin SDK credentials
- Any file matching `*-firebase-adminsdk-*.json`
- `serviceAccount*.json` - Any service account credentials

### Environment Variables
- `.env` - Environment variables for any environment
- `.env.local` - Local development environment variables
- `.env.production` - Production secrets
- `functions/.env` - Cloud Functions environment variables

### API Keys & Credentials
- `**/api_keys.dart` - Hardcoded API keys
- `**/secrets.dart` - Application secrets
- `**/credentials.json` - Authentication credentials
- `cloudinary_config.dart` - Cloudinary API credentials

### Local Configuration
- `local.properties` - Android local SDK paths (may contain sensitive info)
- `keystore.properties` - Android signing keys
- `key.properties` - Signing configuration

## ✅ Files Safe to Commit

- `README.md` - Project documentation
- `pubspec.yaml` - Dependency configuration (without secret keys)
- `firestore.rules` - Database security rules (no secrets)
- `firestore.indexes.json` - Database indexes
- Source code files (`.dart`) that don't contain secrets

## 🛡️ Security Best Practices

### 1. Use Environment Variables
Instead of hardcoding secrets, use environment variables:

```dart
// ❌ BAD - Never do this
const apiKey = 'sk_live_real_api_key_here';

// ✅ GOOD - Use environment variables
const apiKey = String.fromEnvironment('API_KEY');
```

### 2. Create Template Files
Create template files without secrets for reference:

```bash
# Create template
cp .env .env.template
# Remove all actual values from .env.template
# Commit only .env.template
```

Example `.env.template`:
```
FIREBASE_API_KEY=your_api_key_here
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
```

### 3. Configure Firebase App Check
Enable Firebase App Check to prevent unauthorized API usage:
1. Go to Firebase Console → App Check
2. Enable App Check for your apps
3. Configure SafetyNet (Android) and DeviceCheck (iOS)

### 4. Restrict Firebase API Keys
In Google Cloud Console:
1. Navigate to APIs & Services → Credentials
2. Select your Firebase API key
3. Add application restrictions (Android apps, iOS apps, websites)
4. Add API restrictions (only enable required APIs)

### 5. Use Firestore Security Rules
Always enforce security rules in Firestore:

```javascript
// Example: Users can only read their own data
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### 6. Rotate Compromised Keys Immediately
If any key is accidentally committed:
1. Revoke the compromised key immediately
2. Generate new credentials
3. Update all environments
4. Remove from git history:
   ```bash
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch path/to/sensitive/file' \
   --prune-empty --tag-name-filter cat -- --all
   ```

## 🔍 Checking for Exposed Secrets

### Before Committing
```bash
# Check what will be committed
git status
git diff --cached

# Ensure sensitive files are ignored
git check-ignore -v path/to/file
```

### Scan Repository
Use tools to scan for secrets:

```bash
# Install git-secrets
brew install git-secrets  # macOS
apt-get install git-secrets  # Ubuntu

# Scan repository
git-secrets --scan
git-secrets --scan-history
```

### GitHub Secret Scanning
GitHub automatically scans for known secret patterns. If secrets are detected:
1. You'll receive an alert
2. Revoke the secrets immediately
3. Remove from history
4. Update credentials

## 📋 Security Checklist

Before deploying or sharing code:

- [ ] All Firebase config files are in `.gitignore`
- [ ] No hardcoded API keys in source code
- [ ] Environment variables used for all secrets
- [ ] Firestore security rules are configured
- [ ] Firebase API keys have restrictions
- [ ] Service account keys are secured
- [ ] `.env.template` exists with placeholder values
- [ ] No credentials in commit history
- [ ] App Check is enabled (production)
- [ ] Security rules tested

## 🚨 If You Accidentally Commit a Secret

1. **Don't panic, but act fast**
2. **Revoke the secret immediately** in Firebase/Cloud Console
3. **Remove from git history**:
   ```bash
   # Install BFG Repo-Cleaner
   brew install bfg  # or download from https://rtyley.github.io/bfg-repo-cleaner/
   
   # Remove the sensitive file
   bfg --delete-files firebase_options.dart
   
   # Clean up
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```
4. **Force push** (if remote):
   ```bash
   git push --force --all
   ```
5. **Notify team members** to re-clone the repository
6. **Generate new credentials**
7. **Update all environments**

## 📞 Reporting Security Issues

If you discover a security vulnerability:
- **DO NOT** open a public issue
- **DO NOT** share details publicly
- Email: security@byteplus.com
- Expect response within 24 hours

## 🔐 Production Security

### Before Production Deployment:
1. Use Firebase Blaze plan (for security features)
2. Enable App Check
3. Configure rate limiting in Cloud Functions
4. Set up monitoring and alerts
5. Review all security rules
6. Use production Firebase project (separate from dev)
7. Enable 2FA for all admin accounts
8. Backup Firestore data regularly
9. Monitor Firebase usage for anomalies
10. Keep dependencies updated

---

**Remember**: Security is everyone's responsibility. When in doubt, ask!
