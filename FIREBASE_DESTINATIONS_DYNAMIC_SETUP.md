# 🔥 Firebase Dynamic Destinations Setup

## Overview
This guide explains how to set up Firebase Remote Config to store and dynamically update travel destinations based on user searches and occasion types.

## Architecture

### Data Flow:
```
User searches destination
    ↓
App checks Firebase Remote Config
    ↓
If found: Return destination data
    ↓
If not found: Use fallback + Log search
    ↓
Admin updates Firebase with new destinations
    ↓
App fetches updated data (12-hour interval)
```

## Step 1: Firebase Remote Config Setup

### 1.1 Create Remote Config Parameters

Go to Firebase Console → Remote Config → Add parameter

Create these parameters:

#### Parameter 1: `destinations_casual`
**Data type:** JSON
**Default value:**
```json
{
  "version": "1.0.0",
  "last_updated": "2024-06-09",
  "destinations": [
    {
      "name": "Goa",
      "country": "India",
      "description": "Beaches, nightlife, and Portuguese heritage",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Beaches", "Churches", "Nightlife"],
      "avgCost": "₹12,000-28,000",
      "bestTime": "November-February",
      "popularityScore": 90
    },
    {
      "name": "Manali",
      "country": "India",
      "description": "Himalayan hill station with scenic beauty",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Rohtang Pass", "Solang Valley", "Mall Road"],
      "avgCost": "₹15,000-32,000",
      "bestTime": "May-June (summer)",
      "popularityScore": 88
    },
    {
      "name": "Jaipur",
      "country": "India",
      "description": "Pink City - Forts, palaces, and culture",
      "bestFor": "casual",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Amber Fort", "City Palace", "Markets"],
      "avgCost": "₹10,000-22,000",
      "bestTime": "November-February",
      "popularityScore": 85
    },
    {
      "name": "Coorg",
      "country": "India",
      "description": "Scotland of India - Coffee plantations",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Coffee estates", "Abbey Falls", "Nature"],
      "avgCost": "₹12,000-25,000",
      "bestTime": "October-March",
      "popularityScore": 82
    },
    {
      "name": "Udaipur",
      "country": "India",
      "description": "City of Lakes - Romantic and scenic",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.8,
      "highlights": ["Lake Palace", "City Palace", "Boat rides"],
      "avgCost": "₹15,000-35,000",
      "bestTime": "October-March",
      "popularityScore": 87
    },
    {
      "name": "Rishikesh",
      "country": "India",
      "description": "Yoga capital and adventure sports hub",
      "bestFor": "casual",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.5,
      "highlights": ["River rafting", "Yoga", "Temples"],
      "avgCost": "₹8,000-18,000",
      "bestTime": "September-November",
      "popularityScore": 80
    },
    {
      "name": "Ooty",
      "country": "India",
      "description": "Queen of Hill Stations",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.4,
      "highlights": ["Tea gardens", "Botanical garden", "Toy train"],
      "avgCost": "₹10,000-22,000",
      "bestTime": "April-June",
      "popularityScore": 78
    },
    {
      "name": "Shimla",
      "country": "India",
      "description": "Colonial hill station with scenic views",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.5,
      "highlights": ["Mall Road", "Jakhu Temple", "Ridge"],
      "avgCost": "₹12,000-25,000",
      "bestTime": "May-June",
      "popularityScore": 83
    },
    {
      "name": "Munnar",
      "country": "India",
      "description": "Tea plantations and misty mountains",
      "bestFor": "casual",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Tea estates", "Eravikulam Park", "Mattupetty Dam"],
      "avgCost": "₹11,000-24,000",
      "bestTime": "September-March",
      "popularityScore": 81
    },
    {
      "name": "Andaman",
      "country": "India",
      "description": "Pristine beaches and water sports",
      "bestFor": "casual",
      "budgetCategory": "luxury",
      "durationCategory": "long",
      "rating": 4.8,
      "highlights": ["Radhanagar Beach", "Scuba diving", "Havelock Island"],
      "avgCost": "₹35,000-60,000",
      "bestTime": "November-April",
      "popularityScore": 89
    }
  ]
}
```

#### Parameter 2: `destinations_wedding`
**Data type:** JSON
**Default value:**
```json
{
  "version": "1.0.0",
  "last_updated": "2024-06-09",
  "destinations": [
    {
      "name": "Udaipur",
      "country": "India",
      "description": "City of Lakes - Perfect for royal destination weddings",
      "bestFor": "wedding",
      "budgetCategory": "luxury",
      "durationCategory": "medium",
      "rating": 4.8,
      "highlights": ["Lake Palace", "City Palace", "Royal venues"],
      "avgCost": "₹15-50 lakhs",
      "bestTime": "November-February",
      "popularityScore": 95
    },
    {
      "name": "Jaipur",
      "country": "India",
      "description": "Pink City - Heritage palaces and forts for grand weddings",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Amber Fort", "City Palace", "Heritage hotels"],
      "avgCost": "₹8-25 lakhs",
      "bestTime": "November-February",
      "popularityScore": 88
    },
    {
      "name": "Goa",
      "country": "India",
      "description": "Beach weddings with Portuguese charm",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Beach venues", "Churches", "Resorts"],
      "avgCost": "₹5-20 lakhs",
      "bestTime": "December-January",
      "popularityScore": 85
    },
    {
      "name": "Jim Corbett",
      "country": "India",
      "description": "Wildlife resort weddings in nature",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "short",
      "rating": 4.5,
      "highlights": ["Resorts", "Nature", "Wildlife"],
      "avgCost": "₹6-18 lakhs",
      "bestTime": "November-February",
      "popularityScore": 75
    },
    {
      "name": "Kerala Backwaters",
      "country": "India",
      "description": "Houseboat weddings in serene backwaters",
      "bestFor": "wedding",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Houseboats", "Backwaters", "Traditional venues"],
      "avgCost": "₹7-22 lakhs",
      "bestTime": "November-February",
      "popularityScore": 82
    }
  ]
}
```

#### Parameter 3: `destinations_devotional`
**Data type:** JSON
**Default value:**
```json
{
  "version": "1.0.0",
  "last_updated": "2024-06-09",
  "destinations": [
    {
      "name": "Tirupati",
      "country": "India",
      "description": "Lord Venkateswara Temple - Most visited pilgrimage site",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.9,
      "highlights": ["Tirumala Temple", "Sri Padmavathi Temple"],
      "avgCost": "₹3,000-8,000",
      "bestTime": "September-February",
      "popularityScore": 98
    },
    {
      "name": "Varanasi",
      "country": "India",
      "description": "Spiritual capital on the Ganges",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.8,
      "highlights": ["Kashi Vishwanath", "Ganga Aarti", "Ghats"],
      "avgCost": "₹4,000-10,000",
      "bestTime": "October-March",
      "popularityScore": 96
    },
    {
      "name": "Shirdi",
      "country": "India",
      "description": "Sai Baba Temple - Popular pilgrimage",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["Sai Baba Temple", "Dwarkamai", "Chavadi"],
      "avgCost": "₹3,500-9,000",
      "bestTime": "October-March",
      "popularityScore": 92
    },
    {
      "name": "Amritsar",
      "country": "India",
      "description": "Golden Temple - Sikh pilgrimage center",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.9,
      "highlights": ["Golden Temple", "Jallianwala Bagh", "Wagah Border"],
      "avgCost": "₹5,000-12,000",
      "bestTime": "November-March",
      "popularityScore": 94
    },
    {
      "name": "Haridwar",
      "country": "India",
      "description": "Gateway to the Gods on the Ganges",
      "bestFor": "devotional",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.6,
      "highlights": ["Har Ki Pauri", "Ganga Aarti", "Temples"],
      "avgCost": "₹4,000-10,000",
      "bestTime": "September-November",
      "popularityScore": 90
    }
  ]
}
```

#### Parameter 4: `destinations_adventure`
**Data type:** JSON
**Default value:**
```json
{
  "version": "1.0.0",
  "last_updated": "2024-06-09",
  "destinations": [
    {
      "name": "Leh-Ladakh",
      "country": "India",
      "description": "High-altitude adventure paradise",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "long",
      "rating": 4.9,
      "highlights": ["Pangong Lake", "Khardung La", "Monasteries"],
      "avgCost": "₹25,000-45,000",
      "bestTime": "June-September",
      "popularityScore": 95
    },
    {
      "name": "Rishikesh",
      "country": "India",
      "description": "Adventure sports capital",
      "bestFor": "adventure",
      "budgetCategory": "budget",
      "durationCategory": "short",
      "rating": 4.7,
      "highlights": ["River rafting", "Bungee jumping", "Camping"],
      "avgCost": "₹8,000-18,000",
      "bestTime": "September-November",
      "popularityScore": 88
    },
    {
      "name": "Spiti Valley",
      "country": "India",
      "description": "Remote Himalayan adventure",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "long",
      "rating": 4.8,
      "highlights": ["Key Monastery", "Chandratal Lake", "Trekking"],
      "avgCost": "₹20,000-40,000",
      "bestTime": "June-September",
      "popularityScore": 90
    },
    {
      "name": "Goa",
      "country": "India",
      "description": "Water sports and beach adventures",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.6,
      "highlights": ["Parasailing", "Scuba diving", "Jet skiing"],
      "avgCost": "₹15,000-30,000",
      "bestTime": "November-February",
      "popularityScore": 85
    },
    {
      "name": "Manali",
      "country": "India",
      "description": "Mountain adventure hub",
      "bestFor": "adventure",
      "budgetCategory": "mid-range",
      "durationCategory": "medium",
      "rating": 4.7,
      "highlights": ["Skiing", "Paragliding", "Trekking"],
      "avgCost": "₹18,000-35,000",
      "bestTime": "December-February (skiing)",
      "popularityScore": 87
    }
  ]
}
```

#### Parameter 5: `user_searched_destinations`
**Data type:** JSON
**Default value:**
```json
{
  "version": "1.0.0",
  "searches": []
}
```

### 1.2 Publish Changes
Click "Publish changes" in Firebase Console

## Step 2: Update Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^4.13.6  # For logging user searches
```

Run:
```bash
flutter pub get
```

## Step 3: Implementation Complete

The code has been updated in:
- `lib/services/firebase_destinations_service.dart` (NEW)
- `lib/services/trending_destinations_service.dart` (UPDATED)

## Step 4: Testing

1. **Test Firebase fetch:**
   ```bash
   flutter run
   ```

2. **Search for a destination** not in Firebase

3. **Check Firestore** for logged search:
   - Go to Firebase Console → Firestore
   - Collection: `user_searches`
   - Should see new document with search data

4. **Add destination to Firebase Remote Config**

5. **Wait 12 hours or force refresh** (clear app data)

6. **Search again** - should now show from Firebase

## Step 5: Monitoring & Updates

### View User Searches:
```
Firebase Console → Firestore → user_searches
```

### Add New Destinations:
1. Analyze popular searches in Firestore
2. Add to appropriate Remote Config parameter
3. Publish changes
4. Users get updates within 12 hours

### Update Existing Destinations:
1. Edit Remote Config parameter
2. Update version number
3. Publish changes

## Benefits

✅ **Dynamic Updates** - Add destinations without app release
✅ **User-Driven** - Learn from actual searches
✅ **Scalable** - Easy to add hundreds of destinations
✅ **Offline Support** - Cached locally
✅ **Analytics** - Track popular searches
✅ **Cost-Effective** - Firebase free tier sufficient

## Maintenance

### Weekly:
- Review Firestore user searches
- Identify trending destinations
- Add top 5 new destinations to Remote Config

### Monthly:
- Update popularity scores
- Refresh cost estimates
- Update seasonal information

---

**Setup Time:** 30 minutes
**Maintenance:** 1 hour/week
**Cost:** Free (Firebase Spark plan)