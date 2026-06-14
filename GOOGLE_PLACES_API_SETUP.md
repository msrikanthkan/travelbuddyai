# Google Places API Setup Guide

## Step 1: Get a Valid Google Places API Key

### 1.1 Go to Google Cloud Console
1. Visit: https://console.cloud.google.com/
2. Select your project: `travelbuddyai-f0d5d` (or create a new one)

### 1.2 Enable Required APIs
1. Go to **APIs & Services** → **Library**
2. Search and enable these APIs:
   - **Places API** (New)
   - **Geocoding API**
   - **Maps JavaScript API** (if using maps)

### 1.3 Create API Key
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API Key**
3. Copy the API key (e.g., `AIzaSyABC123...`)

### 1.4 Restrict API Key (Important for Security)
1. Click on the API key you just created
2. Under **Application restrictions**:
   - Select **HTTP referrers (web sites)**
   - Add: `*.cloudfunctions.net/*`
   - Add: `*.run.app/*`
3. Under **API restrictions**:
   - Select **Restrict key**
   - Check: Places API, Geocoding API
4. Click **Save**

### 1.5 Enable Billing (Required for Places API)
1. Go to **Billing** in Google Cloud Console
2. Link a billing account (Places API requires billing enabled)
3. Note: Google provides $200 free credit per month

## Step 2: Set Environment Variable

### Option A: Using Google Cloud Console (Easiest)

1. Go to: https://console.cloud.google.com/functions/list
2. Find and click on: `searchHotels`
3. Click **EDIT** at the top
4. Expand **Runtime, build, connections and security settings**
5. Under **Runtime environment variables**, click **ADD VARIABLE**:
   - Name: `GOOGLE_PLACES_API_KEY`
   - Value: Your API key (paste it here)
6. Click **NEXT** → **DEPLOY**

### Option B: Using Firebase CLI

Deploy with environment variable:

```bash
firebase deploy --only functions:searchHotels --set-env-vars GOOGLE_PLACES_API_KEY=YOUR_API_KEY_HERE
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### Option C: Using gcloud CLI

```bash
gcloud functions deploy searchHotels \
  --region=asia-south1 \
  --set-env-vars GOOGLE_PLACES_API_KEY=YOUR_API_KEY_HERE
```

## Step 3: Deploy Function

The code is already updated to use environment variables:

```javascript
const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY;
```

Deploy the function:

```bash
cd functions
firebase deploy --only functions:searchHotels
```

## Step 4: Test the Function

### Test in Browser:
```
https://searchhotels-i57v6hnxaa-el.a.run.app?destination=Goa
```

### Expected Success Response:
```json
{
  "success": true,
  "destination": "Goa",
  "hotels": [
    {
      "name": "Taj Exotica Resort & Spa",
      "rating": 4.6,
      "address": "Calwaddo, Benaulim",
      "placeId": "ChIJ...",
      "priceLevel": 4
    }
  ],
  "count": 5
}
```

## Troubleshooting

### Error: "REQUEST_DENIED"
- **Cause**: API key restrictions or billing not enabled
- **Fix**: 
  1. Check API key restrictions allow Cloud Functions
  2. Ensure billing is enabled
  3. Verify Places API is enabled

### Error: "API key not configured"
- **Cause**: Environment variable not set
- **Fix**:
  1. Set environment variable via Google Cloud Console (Option A above)
  2. Or redeploy with `--set-env-vars` flag
  3. Verify in Cloud Console that the variable is set

### Error: "ZERO_RESULTS"
- **Cause**: Location not found or no hotels nearby
- **Fix**: Try a more popular destination (e.g., "Goa", "Mumbai")

## Cost Estimation

Google Places API pricing (as of 2024):
- **Nearby Search**: $32 per 1,000 requests
- **Geocoding**: $5 per 1,000 requests
- **Free tier**: $200 credit per month (~6,000 hotel searches)

For a small app, you'll likely stay within the free tier.

## Alternative: Keep Using Curated Database

If you prefer to avoid API costs and complexity:
1. The app already works with curated real hotel data
2. No API setup needed
3. Instant results, no rate limits
4. Simply revert the hotel_service.dart to prioritize curated data

---

**Need Help?**
- Google Cloud Console: https://console.cloud.google.com/
- Firebase Console: https://console.firebase.google.com/
- Places API Docs: https://developers.google.com/maps/documentation/places/web-service