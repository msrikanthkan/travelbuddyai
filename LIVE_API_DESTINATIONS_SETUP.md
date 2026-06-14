# Live API Destinations Setup Guide

## Overview
This service fetches trending destinations in **real-time** from external APIs based on user's budget and occasion selection.

## How It Works

When a user selects:
- **Occasion**: Wedding, Devotional, Adventure, etc.
- **Budget**: ₹10,000
- **Duration**: 3 days

The system calls live APIs to get the **latest trending destinations** matching these criteria.

## API Options (Choose One or Multiple)

### Option 1: Amadeus Travel API (Recommended) ⭐

**Best for**: Real travel data, activities, destinations

#### Setup:
1. Go to [Amadeus for Developers](https://developers.amadeus.com/)
2. Create a free account
3. Create a new app
4. Get your API Key and API Secret
5. Add to `lib/services/live_destinations_api_service.dart`:
```dart
static const String _amadeusTravelApiKey = 'YOUR_KEY_HERE';
static const String _amadeusTravelApiSecret = 'YOUR_SECRET_HERE';
```

#### Features:
- ✅ Real travel destinations
- ✅ Activity recommendations
- ✅ Price information
- ✅ 2,000 free API calls/month
- ✅ Official travel industry data

#### API Endpoints Used:
- `/v1/shopping/activities` - Get activities by location
- `/v1/reference-data/locations` - Search destinations
- `/v1/shopping/flight-destinations` - Popular destinations

---

### Option 2: Google Custom Search API

**Best for**: Trending searches, popular destinations

#### Setup:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable "Custom Search API"
3. Create API credentials
4. Create a Custom Search Engine at [Programmable Search Engine](https://programmablesearchengine.google.com/)
5. Configure to search travel websites (MakeMyTrip, TripAdvisor, etc.)
6. Get Search Engine ID
7. Add to service:
```dart
static const String _googleCustomSearchKey = 'YOUR_KEY';
static const String _googleSearchEngineId = 'YOUR_ENGINE_ID';
```

#### Features:
- ✅ Real-time trending searches
- ✅ 100 free searches/day
- ✅ Finds what people are actually searching for
- ✅ Can target specific travel sites

---

### Option 3: TripAdvisor API (Alternative)

**Best for**: Reviews, ratings, popular places

#### Setup:
1. Go to [TripAdvisor Content API](https://www.tripadvisor.com/developers)
2. Apply for API access
3. Get API key
4. Integrate location search and reviews

---

### Option 4: Skyscanner API (For Flights/Hotels)

**Best for**: Flight destinations, hotel prices

#### Setup:
1. Go to [RapidAPI - Skyscanner](https://rapidapi.com/skyscanner/api/skyscanner-flight-search)
2. Subscribe to free tier
3. Get API key
4. Use for destination suggestions based on flight prices

---

## Implementation Steps

### Step 1: Choose Your API

For best results, use **Amadeus Travel API** (it's free and designed for travel):

```bash
# No installation needed, just HTTP requests
```

### Step 2: Update Budget Planner Form

Edit `lib/screens/budget_planner_form.dart`:

```dart
// Replace the import
import '../services/live_destinations_api_service.dart';

// In _fetchTrendingDestinations method:
final trendingService = LiveDestinationsApiService();
final destinations = await trendingService.getTrendingDestinations(
  occasionType: _occasionType,
  budget: budget,
  duration: duration,
);
```

### Step 3: Test the Integration

```dart
// Test with different inputs
final service = LiveDestinationsApiService();

// Wedding with high budget
final weddingDests = await service.getTrendingDestinations(
  occasionType: 'wedding',
  budget: 100000,
  duration: 5,
);

// Budget devotional trip
final devotionalDests = await service.getTrendingDestinations(
  occasionType: 'devotional',
  budget: 5000,
  duration: 2,
);
```

## API Response Flow

```
User Input:
├─ Occasion: "adventure"
├─ Budget: ₹25,000
└─ Duration: 5 days

↓ API Call

Amadeus API:
├─ Searches activities in India
├─ Filters by budget range
├─ Returns popular destinations
└─ Includes real data

↓ Processing

App Shows:
├─ Manali (Adventure activities)
├─ Rishikesh (River rafting)
├─ Leh-Ladakh (Bike trips)
├─ Goa (Water sports)
└─ Andaman (Diving)
```

## Cost Comparison

| API | Free Tier | Cost After | Best For |
|-----|-----------|------------|----------|
| **Amadeus** | 2,000 calls/month | $0.01/call | Travel data |
| **Google Search** | 100 calls/day | $5/1000 calls | Trending |
| **TripAdvisor** | Limited | Varies | Reviews |
| **Skyscanner** | 100 calls/month | $0.01/call | Flights |

## Recommended Setup

### For Production:
1. **Primary**: Amadeus Travel API (real travel data)
2. **Secondary**: Google Custom Search (trending backup)
3. **Fallback**: Hardcoded list (if APIs fail)

### Implementation:
```dart
Future<List<Map<String, dynamic>>> getTrendingDestinations(...) async {
  // Try Amadeus first
  try {
    final destinations = await _fetchFromAmadeusAPI(...);
    if (destinations.isNotEmpty) return destinations;
  } catch (e) { }
  
  // Try Google Search as backup
  try {
    final destinations = await _fetchFromGoogleSearch(...);
    if (destinations.isNotEmpty) return destinations;
  } catch (e) { }
  
  // Use hardcoded fallback
  return _getFallbackDestinations(...);
}
```

## Example API Calls

### Amadeus - Get Activities:
```http
GET https://test.api.amadeus.com/v1/shopping/activities
  ?latitude=28.6139
  &longitude=77.2090
  &radius=500
Authorization: Bearer {token}
```

### Google Custom Search:
```http
GET https://www.googleapis.com/customsearch/v1
  ?key={API_KEY}
  &cx={SEARCH_ENGINE_ID}
  &q=trending+adventure+destinations+India+budget+2024
```

## Benefits of Live API Approach

✅ **Always Current**: Gets latest trending destinations
✅ **No Maintenance**: No need to update destination lists
✅ **Real Data**: Actual travel industry information
✅ **Dynamic**: Adapts to real-time trends
✅ **Scalable**: Handles any occasion/budget combination
✅ **Accurate**: Based on actual bookings and searches

## Limitations & Solutions

### Rate Limits:
**Problem**: APIs have call limits
**Solution**: 
- Cache results for 24 hours
- Use multiple APIs as fallbacks
- Implement request throttling

### API Costs:
**Problem**: Paid after free tier
**Solution**:
- Start with free tiers
- Cache popular queries
- Use cheaper APIs for backup

### Response Time:
**Problem**: API calls take time
**Solution**:
- Show loading indicator
- Implement timeout (10-15 seconds)
- Have instant fallback ready

## Caching Strategy

To reduce API calls and costs:

```dart
// Cache in memory
final _cache = <String, CachedData>{};

Future<List<Map<String, dynamic>>> getTrendingDestinations(...) async {
  final cacheKey = '$occasionType-$budget-$duration';
  
  // Check cache (valid for 24 hours)
  if (_cache.containsKey(cacheKey)) {
    final cached = _cache[cacheKey]!;
    if (DateTime.now().difference(cached.timestamp).inHours < 24) {
      return cached.data;
    }
  }
  
  // Fetch from API
  final data = await _fetchFromAPI(...);
  
  // Store in cache
  _cache[cacheKey] = CachedData(data, DateTime.now());
  
  return data;
}
```

## Testing

### Test Different Scenarios:
```dart
// High budget wedding
await service.getTrendingDestinations(
  occasionType: 'wedding',
  budget: 500000,
  duration: 7,
);
// Expected: Udaipur, Bali, Dubai, etc.

// Budget devotional
await service.getTrendingDestinations(
  occasionType: 'devotional',
  budget: 5000,
  duration: 2,
);
// Expected: Tirupati, Shirdi, Varanasi, etc.

// Adventure trip
await service.getTrendingDestinations(
  occasionType: 'adventure',
  budget: 30000,
  duration: 5,
);
// Expected: Manali, Rishikesh, Leh, etc.
```

## Next Steps

1. ✅ Choose API (Recommend: Amadeus)
2. ✅ Get API credentials
3. ✅ Add keys to service file
4. ✅ Update budget planner to use new service
5. ✅ Test with different inputs
6. ✅ Implement caching
7. ✅ Add error handling
8. ✅ Monitor API usage

## Support Resources

- [Amadeus API Docs](https://developers.amadeus.com/self-service)
- [Google Custom Search Docs](https://developers.google.com/custom-search)
- [TripAdvisor API](https://www.tripadvisor.com/developers)

This approach gives you **real, live, trending destinations** based on actual travel data! 🚀