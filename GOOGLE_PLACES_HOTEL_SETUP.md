# Google Places API Setup for Real Hotel Data

The TravelBuddyAI app now fetches **real hotel data** from Google Places API. Follow these steps to enable this feature.

## Current Status

- ✅ Hotel service implemented (`lib/services/hotel_service.dart`)
- ✅ Itinerary generator updated to use real hotel data
- ✅ Fallback to generated data if API key not configured
- ⚠️ **Google Places API key needs to be configured**

## Setup Instructions

### Step 1: Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Places API**
   - **Geocoding API**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

### Step 2: Restrict Your API Key (Recommended)

1. Click on your API key in the credentials page
2. Under **API restrictions**, select "Restrict key"
3. Enable only:
   - Places API
   - Geocoding API
4. Under **Application restrictions**, add your app's package name

### Step 3: Configure API Key in App

Open `lib/services/hotel_service.dart` and replace the placeholder:

```dart
// Line 9
static const String _googlePlacesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### Step 4: Test the Integration

1. Run `flutter pub get`
2. Build and run the app
3. Create a trip and view the detailed itinerary
4. You should see:
   - "Loading real hotel data..." message
   - Real hotel names from Google Places
   - Actual ratings and addresses
   - Clickable "Book Now" buttons

## How It Works

### With API Key Configured:
1. App searches for hotels near the destination using Google Places API
2. Fetches real hotel names, ratings, addresses, and place IDs
3. Generates booking URLs based on hotel details
4. Displays real hotels in the itinerary

### Without API Key (Fallback):
1. App generates placeholder hotel data based on budget
2. Uses generic names like "Munnar Comfort Hotel"
3. Still provides booking URLs to search pages
4. Shows warning in console: "⚠️ Google Places API key not configured"

## API Pricing

Google Places API has a **free tier**:
- **$200 free credit per month**
- Places API: $17 per 1,000 requests
- Geocoding API: $5 per 1,000 requests

For typical usage (10-20 trips per day), you'll stay within the free tier.

## Features

### Real Hotel Data Includes:
- ✅ Actual hotel names from Google Places
- ✅ Real ratings (1-5 stars)
- ✅ Actual addresses
- ✅ Google Maps links with place IDs
- ✅ Budget-appropriate hotel suggestions
- ✅ Clickable booking buttons

### Booking Integration:
- **Budget Hotels (<₹2000)**: Links to OYO Rooms
- **Mid-range Hotels (₹2000-5000)**: Links to MakeMyTrip
- **Luxury Hotels (>₹5000)**: Links to Booking.com
- **With Place ID**: Direct Google Maps link

## Troubleshooting

### "Loading real hotel data..." never completes
- Check if API key is configured correctly
- Verify APIs are enabled in Google Cloud Console
- Check console for error messages

### Shows fallback data instead of real hotels
- API key might be invalid or restricted
- Check API quotas in Google Cloud Console
- Verify network connectivity

### "Could not open booking website"
- Check if url_launcher package is installed
- Verify app has internet permission
- Try different booking platform

## Alternative: Use Fallback Data

If you don't want to use Google Places API:
- The app will automatically use fallback data
- Hotels will have generic names but functional booking links
- No API key or setup required
- Still provides good user experience

## Security Best Practices

1. **Never commit API keys to version control**
2. Use environment variables for production
3. Restrict API key to specific APIs
4. Monitor usage in Google Cloud Console
5. Set up billing alerts

## Support

For issues or questions:
- Check console logs for detailed error messages
- Verify API key permissions in Google Cloud
- Ensure all required APIs are enabled
- Test with a simple destination first (e.g., "Mumbai")

---

**Note**: The app works perfectly fine without the API key using fallback data. Real hotel data is an enhancement that provides more accurate information to users.