# Firebase Cloud Function Setup for Real Hotel Data

This guide explains how to deploy the Firebase Cloud Function that fetches real hotel data from Google Places API.

## Why Use Firebase Cloud Function?

The Google Places API cannot be called directly from Flutter web due to CORS restrictions. The Firebase Cloud Function acts as a proxy:

```
Flutter App → Firebase Function → Google Places API → Real Hotels
```

## Setup Steps

### Step 1: Deploy the Firebase Function

1. **Navigate to functions directory:**
   ```bash
   cd functions
   ```

2. **Install dependencies (if not already done):**
   ```bash
   npm install
   ```

3. **Deploy the function:**
   ```bash
   firebase deploy --only functions:searchHotels
   ```

4. **Note the deployed URL:**
   After deployment, you'll see output like:
   ```
   ✔  functions[searchHotels(asia-south1)]: Successful create operation.
   Function URL: https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/searchHotels
   ```

### Step 2: Update Flutter App with Function URL

1. **Open `lib/services/hotel_service.dart`**

2. **Replace the placeholder URL (line 9):**
   ```dart
   // BEFORE:
   static const String _firebaseFunctionUrl = 'https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/searchHotels';
   
   // AFTER (use your actual URL from deployment):
   static const String _firebaseFunctionUrl = 'https://asia-south1-travelbuddyai-xxxxx.cloudfunctions.net/searchHotels';
   ```

### Step 3: Test the Integration

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Create a trip and view detailed itinerary**

3. **Check console logs:**
   - Should see: `✅ Using curated real hotel data for [destination]` (for popular destinations)
   - Or: `✅ Found X hotels from Firebase Function` (for other destinations)

4. **Verify real hotel names appear** (not "Goa Grand Resort")

5. **Click "Book Now"** - should open booking website

## How It Works

### Priority Order:

1. **Curated Database** (Instant, No API calls)
   - For: Goa, Mumbai, Delhi, Jaipur, Bangalore, Kerala, Manali, Udaipur
   - Shows: Real hotels like Taj Exotica, Novotel, The Oberoi
   - Source: `lib/services/real_hotels_data.dart`

2. **Firebase Cloud Function** (Dynamic, Real-time)
   - For: All other destinations
   - Calls: Google Places API via Firebase Function
   - Returns: Real hotels from Google Places

3. **Fallback Data** (Last Resort)
   - When: Both above methods fail
   - Shows: Generic hotel names
   - Still provides: Working booking URLs

## Function Details

### Endpoint:
```
GET https://asia-south1-YOUR_PROJECT_ID.cloudfunctions.net/searchHotels
```

### Parameters:
- `destination` (required): City or location name
- `maxBudget` (optional): Maximum budget for filtering

### Response:
```json
{
  "success": true,
  "destination": "Goa",
  "hotels": [
    {
      "name": "Taj Exotica Resort & Spa",
      "rating": 4.6,
      "address": "Calwaddo, Benaulim, Goa",
      "placeId": "ChIJ...",
      "types": ["lodging", "point_of_interest"],
      "priceLevel": 4
    }
  ],
  "count": 5
}
```

## Monitoring

### View Function Logs:
```bash
firebase functions:log --only searchHotels
```

### Check Function Status:
```bash
firebase functions:list
```

### View in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Functions
4. Click on `searchHotels` to see metrics and logs

## Troubleshooting

### Function Not Found (404)
- Verify function is deployed: `firebase functions:list`
- Check URL matches deployment output
- Ensure region is correct (asia-south1)

### CORS Errors
- Function already includes CORS headers
- If issues persist, check browser console for details

### No Hotels Returned
- Check function logs: `firebase functions:log`
- Verify Google Places API is enabled in Google Cloud Console
- Check API key has proper permissions

### Timeout Errors
- Function has 15-second timeout
- If slow, consider increasing in `functions/index.js`:
  ```javascript
  exports.searchHotels = functions
    .region('asia-south1')
    .runWith({ timeoutSeconds: 30 }) // Increase timeout
    .https
    .onRequest(...)
  ```

## Cost Considerations

### Firebase Functions:
- **Free tier**: 2 million invocations/month
- **Typical usage**: 10-20 calls/day = ~600/month (well within free tier)

### Google Places API:
- **Free tier**: $200 credit/month
- **Places API**: $17 per 1,000 requests
- **Geocoding API**: $5 per 1,000 requests
- **Typical usage**: ~1,200 requests/month = ~$26 (covered by free credit)

## Security Best Practices

1. **API Key Security:**
   - API key is stored in Firebase Function (server-side)
   - Not exposed in Flutter app code
   - Can be moved to environment variables

2. **Rate Limiting:**
   - Consider adding rate limiting to prevent abuse
   - Use Firebase App Check for additional security

3. **Monitoring:**
   - Set up billing alerts in Google Cloud Console
   - Monitor function invocations in Firebase Console

## Alternative: Curated Data Only

If you prefer not to use the Firebase Function:

1. **Keep curated database** for popular destinations
2. **Expand `real_hotels_data.dart`** with more destinations
3. **Use fallback data** for unlisted destinations

The app works perfectly with just curated data - the Firebase Function is an enhancement for better coverage.

## Support

For issues:
- Check function logs for detailed errors
- Verify Google Places API is enabled
- Ensure billing is set up in Google Cloud Console
- Test function directly via URL in browser

---

**Note**: The curated database provides instant results for popular destinations. The Firebase Function extends coverage to all destinations dynamically.