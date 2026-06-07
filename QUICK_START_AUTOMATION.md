# 🚀 Quick Start: Automated Train Data Updates

## ⚡ 5-Minute Setup

### **Prerequisites:**
- Node.js installed
- Firebase project created
- data.gov.in account

---

## 📝 Step-by-Step

### **1. Install Firebase CLI**
```bash
npm install -g firebase-tools
firebase login
```

### **2. Initialize Firebase**
```bash
cd c:/Users/003KO9744/Documents/Developmemt/apps/travelbuddyai/travelbuddyai
firebase init functions
```
- Select: JavaScript
- Install dependencies: Yes

### **3. Install Dependencies**
```bash
cd functions
npm install
```

### **4. Get API Key**
1. Go to https://data.gov.in/
2. Register/Login
3. Get API key from Profile

### **5. Configure Environment**
```bash
# In functions folder
cp .env.example .env
notepad .env
```

Add:
```
DATA_GOV_IN_API_KEY=your_key_here
ADMIN_TOKEN=your_secure_token_here
```

Set in Firebase:
```bash
firebase functions:config:set datagov.apikey="YOUR_KEY"
firebase functions:config:set admin.token="YOUR_TOKEN"
```

### **6. Update API Endpoints**

Edit `functions/index.js` line 82:
```javascript
const endpoints = [
  'https://api.data.gov.in/resource/YOUR_RESOURCE_ID',
];
```

Find resource IDs at data.gov.in → Search "train schedule" → Copy API URL

### **7. Deploy**
```bash
firebase deploy --only functions
```

### **8. Test**
```bash
# Get function URL from output
curl https://YOUR_FUNCTION_URL/updateTrainDataManual \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## ✅ Done!

Your system now:
- ✅ Runs automatically on 1st and 15th of every month at 2 AM IST
- ✅ Fetches latest train data from data.gov.in
- ✅ Updates Firebase Remote Config
- ✅ All users get updates within 12 hours
- ✅ No manual intervention needed!

---

## 📊 Monitor

**View logs:**
```bash
firebase functions:log
```

**Check updates:**
- Firebase Console → Firestore → `train_data_updates`

**Check errors:**
- Firebase Console → Firestore → `system_alerts`

---

## 🔧 Customize Schedule

Edit `functions/index.js` line 18:

```javascript
// Current: 1st and 15th at 2 AM
.schedule('0 2 1,15 * *')

// Weekly on Monday
.schedule('0 2 * * 1')

// Daily
.schedule('0 2 * * *')
```

Then redeploy:
```bash
firebase deploy --only functions
```

---

## 💡 Tips

1. **Test locally first:**
   ```bash
   cd functions
   npm run serve
   ```

2. **Force update anytime:**
   ```bash
   curl YOUR_MANUAL_FUNCTION_URL -H "Authorization: Bearer TOKEN"
   ```

3. **Check costs:**
   - Firebase Console → Usage
   - Should be FREE (2 runs/month)

---

## 🆘 Troubleshooting

**Function not running?**
- Check Firebase Console → Functions → Logs
- Verify schedule timezone (Asia/Kolkata)

**API errors?**
- Verify API key is valid
- Check data.gov.in API status

**No data?**
- Check Firestore logs
- Test manual trigger
- Review function logs

---

## 📚 Full Documentation

See `AUTOMATED_UPDATE_SETUP.md` for complete details.

---

**🎉 You're all set! Train data updates automatically every 2 weeks!**