# 🤖 Automated Fortnightly Train Data Update System

## 📋 Overview

This system automatically fetches train data from data.gov.in every 2 weeks and updates Firebase Remote Config, eliminating manual updates.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTOMATED SYSTEM                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │   Firebase   │      │    Cloud     │      │ data.gov  │ │
│  │   Scheduler  │─────▶│   Function   │─────▶│    API    │ │
│  │ (Fortnightly)│      │              │      │           │ │
│  └──────────────┘      └──────┬───────┘      └───────────┘ │
│                               │                              │
│                               ▼                              │
│                    ┌──────────────────┐                     │
│                    │  Firebase Remote │                     │
│                    │     Config       │                     │
│                    └──────────────────┘                     │
│                               │                              │
│                               ▼                              │
│                    ┌──────────────────┐                     │
│                    │   Flutter App    │                     │
│                    │  (Auto-refresh)  │                     │
│                    └──────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Setup Instructions

### **Step 1: Install Firebase CLI**

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd c:/Users/003KO9744/Documents/Developmemt/apps/travelbuddyai/travelbuddyai
firebase init
```

**Select:**
- ✅ Functions
- ✅ Remote Config
- Choose your Firebase project
- Select JavaScript
- Install dependencies: Yes

---

### **Step 2: Install Cloud Function Dependencies**

```bash
cd functions
npm install
```

This installs:
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- `axios` - HTTP client for API calls
- `node-cron` - Scheduling utilities

---

### **Step 3: Get data.gov.in API Key**

1. **Visit:** https://data.gov.in/
2. **Register/Login** to your account
3. **Navigate to:** Profile → API Key
4. **Copy your API key**

**Find Train Data APIs:**
- Search for "Indian Railways" or "Train Schedule"
- Popular datasets:
  - Train Schedule
  - Station Codes
  - Train Routes
- Note the API endpoint URLs

---

### **Step 4: Configure Environment Variables**

```bash
cd functions

# Copy example file
cp .env.example .env

# Edit .env file
notepad .env
```

**Add your values:**
```env
DATA_GOV_IN_API_KEY=your_actual_api_key_from_data_gov_in
ADMIN_TOKEN=generate_a_secure_random_string_here
```

**Set in Firebase:**
```bash
firebase functions:config:set datagov.apikey="YOUR_API_KEY"
firebase functions:config:set admin.token="YOUR_ADMIN_TOKEN"
```

---

### **Step 5: Update API Endpoints in Code**

Edit `functions/index.js` (line 82-85):

```javascript
const endpoints = [
  // Replace with actual data.gov.in API endpoints
  'https://api.data.gov.in/resource/YOUR_RESOURCE_ID_1',
  'https://api.data.gov.in/resource/YOUR_RESOURCE_ID_2',
];
```

**How to find Resource IDs:**
1. Go to data.gov.in
2. Search for train datasets
3. Click on dataset
4. Look for "API Access" section
5. Copy the resource ID from the URL

---

### **Step 6: Deploy Cloud Functions**

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:updateTrainDataFortnightly
```

**Expected output:**
```
✔ functions[updateTrainDataFortnightly(asia-south1)] Successful create operation.
✔ functions[updateTrainDataManual(asia-south1)] Successful create operation.
Function URL (updateTrainDataManual): https://asia-south1-YOUR_PROJECT.cloudfunctions.net/updateTrainDataManual
```

---

## ⏰ Schedule Configuration

### **Current Schedule:**
- **Frequency:** Every 2 weeks (fortnightly)
- **Days:** 1st and 15th of every month
- **Time:** 2:00 AM IST
- **Timezone:** Asia/Kolkata

### **Cron Expression:**
```javascript
.schedule('0 2 1,15 * *')
```

**Breakdown:**
- `0` - Minute (0 = top of the hour)
- `2` - Hour (2 AM)
- `1,15` - Day of month (1st and 15th)
- `*` - Every month
- `*` - Every day of week

### **Change Schedule:**

Edit `functions/index.js` (line 18):

```javascript
// Daily at 2 AM
.schedule('0 2 * * *')

// Weekly on Monday at 2 AM
.schedule('0 2 * * 1')

// Every 10 days at 2 AM
.schedule('0 2 */10 * *')

// First day of every month at 2 AM
.schedule('0 2 1 * *')
```

---

## 🧪 Testing

### **Test Locally (Emulator):**

```bash
cd functions
npm run serve
```

Then trigger manually:
```bash
curl http://localhost:5001/YOUR_PROJECT/asia-south1/updateTrainDataManual \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### **Test in Production:**

```bash
# Get function URL from Firebase Console
curl https://asia-south1-YOUR_PROJECT.cloudfunctions.net/updateTrainDataManual \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

### **View Logs:**

```bash
# Real-time logs
firebase functions:log --only updateTrainDataFortnightly

# Or in Firebase Console
# Functions → Logs tab
```

---

## 📊 Monitoring

### **Check Update History:**

The system logs every update to Firestore:

**Collection:** `train_data_updates`

**Fields:**
- `timestamp` - When update ran
- `trainCount` - Number of trains updated
- `status` - success/error
- `notes` - Additional info

**Query in Firebase Console:**
```
Firestore → train_data_updates → Sort by timestamp (desc)
```

### **Check Errors:**

**Collection:** `system_alerts`

**Fields:**
- `timestamp` - When error occurred
- `type` - Error type
- `error` - Error message
- `stack` - Stack trace

---

## 🔧 Maintenance

### **Update Function Code:**

1. Edit `functions/index.js`
2. Deploy:
   ```bash
   firebase deploy --only functions
   ```

### **Update Schedule:**

1. Edit cron expression in `functions/index.js`
2. Deploy:
   ```bash
   firebase deploy --only functions:updateTrainDataFortnightly
   ```

### **Force Manual Update:**

```bash
curl -X POST https://asia-south1-YOUR_PROJECT.cloudfunctions.net/updateTrainDataManual \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## 💰 Cost Estimation

### **Firebase Cloud Functions Pricing:**

**Free Tier (Spark Plan):**
- 2 million invocations/month
- 400,000 GB-seconds
- 200,000 CPU-seconds

**Your Usage (Fortnightly):**
- 2 invocations/month (1st and 15th)
- ~10 seconds per run
- **Cost: FREE** ✅

**Blaze Plan (Pay-as-you-go):**
- After free tier: $0.40 per million invocations
- Your cost: ~$0.00 per month

### **Data.gov.in API:**
- **FREE** for registered users
- Rate limits apply (check their docs)

---

## 🔐 Security

### **API Key Protection:**

✅ **DO:**
- Store in environment variables
- Use Firebase Functions Config
- Never commit to Git

❌ **DON'T:**
- Hardcode in source code
- Share publicly
- Commit to repository

### **Admin Token:**

Generate secure token:
```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

## 🐛 Troubleshooting

### **Function Not Triggering:**

1. Check Firebase Console → Functions → Logs
2. Verify schedule is correct
3. Check timezone setting
4. Ensure function is deployed

### **API Errors:**

1. Verify API key is valid
2. Check data.gov.in API status
3. Review rate limits
4. Check endpoint URLs

### **No Data Updated:**

1. Check Firestore logs (`train_data_updates`)
2. Review function logs
3. Verify Remote Config permissions
4. Test manual trigger

### **Permission Errors:**

```bash
# Grant Remote Config admin role
firebase functions:config:set remoteconfig.admin="true"
```

---

## 📱 App Integration

### **How App Gets Updates:**

1. **App starts** → Fetches from Remote Config
2. **Every 12 hours** → Auto-refresh in background
3. **Cloud Function updates** → Available within 12 hours

**No app update needed!** 🎉

---

## 🔄 Update Flow

```
Day 1 (1st of month):
├─ 2:00 AM IST: Cloud Function triggers
├─ 2:01 AM: Fetches data from data.gov.in
├─ 2:02 AM: Transforms data
├─ 2:03 AM: Updates Remote Config
├─ 2:04 AM: Logs to Firestore
└─ Done!

User opens app at 8:00 AM:
├─ App fetches from Remote Config
├─ Gets latest data (updated at 2 AM)
└─ Shows new trains ✅

Day 15 (15th of month):
└─ Process repeats automatically
```

---

## 📞 Support

### **Firebase Support:**
- Documentation: https://firebase.google.com/docs/functions
- Community: https://firebase.google.com/community

### **data.gov.in Support:**
- Help: https://data.gov.in/help
- Forum: https://community.data.gov.in

---

## ✅ Checklist

Before going live:

- [ ] Firebase CLI installed
- [ ] Firebase project initialized
- [ ] data.gov.in API key obtained
- [ ] Environment variables configured
- [ ] API endpoints updated in code
- [ ] Cloud Functions deployed
- [ ] Manual trigger tested
- [ ] Logs verified
- [ ] Schedule confirmed
- [ ] Monitoring set up

---

## 🎯 Next Steps

1. **Deploy the functions** (see Step 6)
2. **Test manual trigger** (see Testing section)
3. **Wait for first scheduled run** (1st or 15th at 2 AM)
4. **Monitor logs** (see Monitoring section)
5. **Verify app receives updates** (open app after update)

---

## 📝 Notes

- **First run:** May take longer as it sets up everything
- **Subsequent runs:** Faster (2-3 minutes)
- **Fallback:** Uses default data if API fails
- **Audit trail:** All updates logged to Firestore
- **Zero downtime:** Updates happen in background

---

**🎉 Congratulations!** Your train data now updates automatically every 2 weeks!