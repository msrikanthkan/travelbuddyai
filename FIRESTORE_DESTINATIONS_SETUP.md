# Firestore Destinations Setup Guide

## Overview
This guide helps you set up dynamic destination data using Firebase Firestore with real data from Google Places API.

## Prerequisites
1. Firebase project already set up (✓ You have this)
2. Google Places API key
3. Cloud Firestore enabled in Firebase Console

## Step 1: Enable Cloud Firestore

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `travelbuddyai`
3. Click on "Firestore Database" in the left menu
4. Click "Create database"
5. Choose "Start in production mode" (we'll set rules later)
6. Select a location (choose closest to your users, e.g., `asia-south1` for India)

## Step 2: Set Firestore Security Rules

In Firebase Console → Firestore Database → Rules, add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read access to trending destinations for all users
    match /trending_destinations/{destination} {
      allow read: if true;
      allow write: if request.auth != null; // Only authenticated users can write
    }
    
    // Admin-only write access (optional)
    match /trending_destinations/{destination} {
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

## Step 3: Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable these APIs:
   - Places API
   - Places API (New)
   - Geocoding API
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy the API key
6. **Restrict the API key**:
   - Application restrictions: Android apps / iOS apps
   - API restrictions: Select only Places API

## Step 4: Add API Key to Your App

### For Android:
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_PLACES_API_KEY"/>
</application>
```

### For iOS:
Edit `ios/Runner/AppDelegate.swift`:
```swift
import GooglePlaces

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSPlacesClient.provideAPIKey("YOUR_GOOGLE_PLACES_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### In the Service File:
Edit `lib/services/firestore_destinations_service.dart`:
```dart
static const String _googlePlacesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

## Step 5: Firestore Collection Structure

Create collection: `trending_destinations`

### Document Structure:
```json
{
  "name": "Jaipur",
  "country": "India",
  "description": "Pink City - Rajasthani culture and heritage",
  "occasionTypes": ["cultural", "casual", "wedding"],
  "budgetCategory": "mid-range",
  "durationCategory": "medium",
  "rating": 4.7,
  "trendScore": 90,
  "highlights": ["Amber Fort", "City Palace", "Hawa Mahal"],
  "insights": {
    "popularityRank": 1,
    "avgVisitors": "5 million+ tourists/year",
    "peakSeason": "October-March",
    "avgCost": "₹10,000-25,000",
    "bestTime": "November-February",
    "crowdLevel": "High",
    "weatherRating": 4.5,
    "trendingReason": "Rich Rajasthani heritage & architecture",
    "recentTrend": "+20% cultural tourism in 2024",
    "topAttractions": ["Amber Fort", "City Palace", "Hawa Mahal"],
    "uniqueFeature": "UNESCO World Heritage Sites"
  },
  "realRating": 4.6,
  "totalRatings": 125000,
  "photos": ["url1", "url2", "url3"],
  "website": "https://...",
  "lastUpdated": Timestamp,
  "lastRealDataUpdate": Timestamp
}
```

## Step 6: Seed Initial Data

### Option A: Manual Entry (Firebase Console)
1. Go to Firestore Database
2. Click "Start collection"
3. Collection ID: `trending_destinations`
4. Add documents manually using the structure above

### Option B: Programmatic Seeding (Recommended)
Run this code once in your app (create a debug button or admin panel):

```dart
import 'package:travelbuddyai/services/firestore_destinations_service.dart';

// In your app initialization or admin panel
final firestoreService = FirestoreDestinationsService();
await firestoreService.seedInitialDestinations();
```

## Step 7: Update Budget Planner to Use Firestore

Edit `lib/screens/budget_planner_form.dart`:

Replace the import:
```dart
// OLD
import '../services/trending_destinations_service.dart';

// NEW
import '../services/firestore_destinations_service.dart';
```

Update the fetch method:
```dart
// OLD
final trendingService = TrendingDestinationsService();

// NEW
final trendingService = FirestoreDestinationsService();
```

## Step 8: Populate with Real Data

### Automated Real Data Updates:
```dart
final firestoreService = FirestoreDestinationsService();

// Update a destination with real Google Places data
await firestoreService.updateDestinationWithRealData('Jaipur');
await firestoreService.updateDestinationWithRealData('Goa');
// ... repeat for all destinations
```

### Schedule Regular Updates:
Use Firebase Cloud Functions to update data periodically:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.updateDestinationsDaily = functions.pubsub
  .schedule('0 0 * * *') // Run daily at midnight
  .onRun(async (context) => {
    // Fetch latest data from Google Places API
    // Update Firestore documents
    return null;
  });
```

## Step 9: Testing

1. Run your app
2. Select an occasion type
3. Enter budget and duration
4. Verify destinations are loaded from Firestore
5. Check that real ratings and photos appear

## Benefits of This Approach

✅ **Dynamic Data**: Update destinations without app updates
✅ **Real-Time**: Fetch live ratings, photos from Google Places
✅ **Scalable**: Add unlimited destinations
✅ **Flexible**: Easy to add new occasion types
✅ **Analytics**: Track which destinations are popular
✅ **A/B Testing**: Test different destination recommendations
✅ **Personalization**: Can add user preferences later

## Cost Considerations

### Firebase Firestore:
- Free tier: 50,000 reads/day
- Typical usage: ~100 reads per user session
- Should handle 500+ users/day on free tier

### Google Places API:
- $17 per 1000 requests (Place Details)
- $32 per 1000 requests (Place Photos)
- Free tier: $200 credit/month
- Cache results to minimize API calls

## Next Steps

1. ✅ Enable Firestore
2. ✅ Get Google Places API key
3. ✅ Set up security rules
4. ✅ Seed initial data
5. ✅ Test the integration
6. 🔄 Set up automated updates (optional)
7. 📊 Add analytics (optional)

## Troubleshooting

### "Permission denied" error:
- Check Firestore security rules
- Ensure read access is allowed

### "API key not valid":
- Verify API key in Google Cloud Console
- Check API restrictions
- Ensure Places API is enabled

### No destinations showing:
- Check Firestore collection name: `trending_destinations`
- Verify documents have correct structure
- Check console for errors

## Support

For issues, check:
- Firebase Console logs
- Flutter app console output
- Google Cloud Console API usage