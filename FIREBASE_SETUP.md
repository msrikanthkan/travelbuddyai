# Firebase Setup Guide for Train Schedule Feature

## 📋 Overview
This guide will help you set up Firebase Remote Config to manage train schedule data that can be updated fortnightly without requiring app updates.

---

## 🚀 Step 1: Firebase Console Setup

### 1.1 Create Remote Config Parameter

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **TravelBuddyAI**
3. Navigate to: **Build** → **Remote Config**
4. Click **Add parameter**

### 1.2 Configure Parameter

**Parameter name:** `train_schedules_json`

**Default value:** Copy and paste the JSON below:

```json
{
  "version": "2024.06.1",
  "last_updated": "2024-06-05",
  "trains": [
    {
      "train_number": "18464",
      "train_name": "Visakha Express",
      "origin": "VSKP",
      "origin_name": "Visakhapatnam",
      "destination": "TPTY",
      "destination_name": "Tirupati",
      "departure_time": "20:30",
      "arrival_time": "06:45",
      "duration_hours": 10.25,
      "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "classes_available": ["SL", "3A", "2A", "1A"]
    },
    {
      "train_number": "12804",
      "train_name": "Simhapuri Express",
      "origin": "VSKP",
      "origin_name": "Visakhapatnam",
      "destination": "TPTY",
      "destination_name": "Tirupati",
      "departure_time": "17:15",
      "arrival_time": "02:30",
      "duration_hours": 9.25,
      "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "classes_available": ["SL", "3A", "2A"]
    },
    {
      "train_number": "12759",
      "train_name": "Charminar Express",
      "origin": "HYB",
      "origin_name": "Hyderabad",
      "destination": "VSKP",
      "destination_name": "Visakhapatnam",
      "departure_time": "18:55",
      "arrival_time": "06:30",
      "duration_hours": 11.58,
      "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "classes_available": ["SL", "3A", "2A", "1A"]
    },
    {
      "train_number": "12760",
      "train_name": "Charminar Express",
      "origin": "VSKP",
      "origin_name": "Visakhapatnam",
      "destination": "HYB",
      "destination_name": "Hyderabad",
      "departure_time": "17:30",
      "arrival_time": "05:15",
      "duration_hours": 11.75,
      "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "classes_available": ["SL", "3A", "2A", "1A"]
    },
    {
      "train_number": "12728",
      "train_name": "Godavari Express",
      "origin": "HYB",
      "origin_name": "Hyderabad",
      "destination": "VSKP",
      "destination_name": "Visakhapatnam",
      "departure_time": "16:50",
      "arrival_time": "05:00",
      "duration_hours": 12.17,
      "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      "classes_available": ["SL", "3A", "2A"]
    }
  ]
}
```

### 1.3 Add Additional Parameters (Optional)

**Parameter name:** `data_version`  
**Default value:** `2024.06.1`

**Parameter name:** `last_updated`  
**Default value:** `2024-06-05`

### 1.4 Publish Changes

Click **Publish changes** button in Firebase Console.

---

## 📊 Step 2: Adding More Train Data

### 2.1 Download Data from data.gov.in

1. Visit: https://data.gov.in
2. Search for: "Indian Railways train schedule"
3. Download CSV/JSON format
4. Focus on popular routes first

### 2.2 Convert to Required Format

Each train entry should follow this structure:

```json
{
  "train_number": "12345",
  "train_name": "Train Name",
  "origin": "STATION_CODE",
  "origin_name": "Full Station Name",
  "destination": "STATION_CODE",
  "destination_name": "Full Station Name",
  "departure_time": "HH:MM",
  "arrival_time": "HH:MM",
  "duration_hours": 10.5,
  "runs_on": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
  "classes_available": ["SL", "3A", "2A", "1A"]
}
```

**Field Explanations:**
- `train_number`: Official train number (e.g., "12345")
- `train_name`: Train name (e.g., "Rajdhani Express")
- `origin`: Station code (e.g., "NDLS" for New Delhi)
- `origin_name`: Full station name (e.g., "New Delhi")
- `destination`: Destination station code
- `destination_name`: Full destination name
- `departure_time`: 24-hour format (e.g., "18:30")
- `arrival_time`: 24-hour format (e.g., "06:45")
- `duration_hours`: Decimal hours (e.g., 10.5 = 10 hours 30 minutes)
- `runs_on`: Array of days ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
- `classes_available`: Array of class codes:
  - "SL" = Sleeper
  - "3A" = AC 3-Tier
  - "2A" = AC 2-Tier
  - "1A" = AC 1st Class

---

## 🔄 Step 3: Fortnightly Update Process

### Every 2 Weeks:

1. **Download Latest Data**
   - Visit data.gov.in
   - Download updated train schedules
   - Check for new trains or schedule changes

2. **Update JSON**
   - Add new trains to the JSON
   - Update changed schedules
   - Increment version number (e.g., 2024.06.1 → 2024.06.2)
   - Update `last_updated` date

3. **Publish to Firebase**
   - Go to Firebase Console → Remote Config
   - Edit `train_schedules_json` parameter
   - Paste updated JSON
   - Click **Publish changes**

4. **Verify**
   - Changes take effect immediately
   - All app users get updated data within 12 hours
   - No app update required!

---

## 🧪 Step 4: Testing

### Test in App:

1. Run the app: `flutter run`
2. Navigate to Budget Planner
3. Select:
   - Origin: Visakhapatnam
   - Destination: Tirupati
   - Travel Type: Train
   - Coach Type: AC 3-Tier
   - Select a travel date
4. Click "Find Available Trains"
5. Should see 2 trains: Visakha Express and Simhapuri Express

### Test Different Routes:

- **Hyderabad ↔ Visakhapatnam**: Should show Charminar Express and Godavari Express
- **Other routes**: Will show "No trains found" until you add more data

---

## 📝 Step 5: Expanding Train Database

### Recommended Approach:

**Phase 1: Top 20 Routes** (Week 1-2)
- Focus on major city pairs
- ~100-200 trains
- File size: ~50-100KB

**Phase 2: Top 50 Routes** (Week 3-4)
- Add tier-2 cities
- ~300-500 trains
- File size: ~150-250KB

**Phase 3: Comprehensive** (Ongoing)
- Add remaining routes
- ~1000+ trains
- File size: ~500KB-1MB

### Popular Routes to Prioritize:

1. Delhi - Mumbai
2. Delhi - Kolkata
3. Mumbai - Bangalore
4. Chennai - Bangalore
5. Hyderabad - Bangalore
6. Delhi - Jaipur
7. Mumbai - Pune
8. Delhi - Chandigarh
9. Kolkata - Patna
10. Chennai - Coimbatore

---

## 🔧 Troubleshooting

### Issue: "No trains found"

**Possible causes:**
1. Route not in database yet
2. No trains run on selected day
3. Selected class not available on any train
4. Station name mismatch

**Solution:**
- Add more train data for that route
- Check if train runs on that day of week
- Try different coach class
- Use common station names (e.g., "Visakhapatnam" not "Vizag")

### Issue: Firebase not initializing

**Check:**
1. `google-services.json` (Android) in `android/app/`
2. `GoogleService-Info.plist` (iOS) in `ios/Runner/`
3. Firebase project is active
4. Internet connection available

### Issue: Data not updating

**Solution:**
1. Force refresh: Pull down to refresh in app
2. Clear app cache
3. Check Firebase Console for published changes
4. Wait 12 hours for automatic sync

---

## 📊 Data Management Tips

### Keep JSON Organized:

```json
{
  "version": "2024.06.1",
  "last_updated": "2024-06-05",
  "metadata": {
    "total_trains": 5,
    "routes_covered": 2,
    "last_data_source": "data.gov.in"
  },
  "trains": [...]
}
```

### Version Numbering:

- Format: `YYYY.MM.PATCH`
- Example: `2024.06.1` = June 2024, 1st update
- Increment PATCH for minor updates
- Increment MM for monthly major updates

### Backup Strategy:

1. Keep local copy of JSON
2. Version control with Git
3. Document changes in commit messages
4. Keep previous versions for rollback

---

## 🎯 Success Metrics

After setup, you should have:

- ✅ Firebase Remote Config configured
- ✅ Train data JSON uploaded
- ✅ App fetching and displaying trains
- ✅ Fortnightly update process documented
- ✅ No app updates needed for data changes

---

## 📞 Support

If you encounter issues:

1. Check Firebase Console logs
2. Review app logs: `flutter logs`
3. Verify JSON format with online validator
4. Test with sample data first

---

## 🚀 Next Steps

1. Complete Firebase setup
2. Test with sample data
3. Download comprehensive data from data.gov.in
4. Set calendar reminder for fortnightly updates
5. Monitor user feedback for missing routes
6. Gradually expand train database

**Estimated Time:**
- Initial setup: 30 minutes
- First data upload: 1 hour
- Fortnightly updates: 15-30 minutes each

Good luck! 🎉