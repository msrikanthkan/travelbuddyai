# Enable Google Custom Search API - Quick Fix

## Problem
Error: `This project does not have the access to Custom Search JSON API`

## Solution (5 minutes)

### Step 1: Go to Google Cloud Console
1. Open: https://console.cloud.google.com/
2. Make sure your project is selected (top dropdown)

### Step 2: Enable Custom Search API
1. Click on **Navigation Menu** (☰) → **APIs & Services** → **Library**
2. In the search box, type: `Custom Search API`
3. Click on **"Custom Search API"** (or "Programmable Search Engine API")
4. Click the blue **"ENABLE"** button
5. Wait 1-2 minutes for activation

### Step 3: Verify API Key Permissions
1. Go to **APIs & Services** → **Credentials**
2. Find your API key: `AIzaSyDuhhxxbSDXCeTTt0ez1AnaT1SnyZsDYm8`
3. Click on it to edit
4. Under **"API restrictions"**:
   - Select **"Restrict key"**
   - Check ✅ **"Custom Search API"**
   - Click **"Save"**

### Step 4: Test Again
Run your app - the API should now work!

## Alternative: Use Fallback Data (Already Working)

Your app is already using fallback curated destinations when the API fails. This includes:
- ✅ Trending destinations based on occasion type
- ✅ Budget-appropriate suggestions
- ✅ Detailed insights for each destination
- ✅ Beautiful UI with all features

The fallback data is high-quality and works perfectly with the insane UI you requested!

## Cost Information
- **Free Tier**: 100 queries/day
- **Paid**: $5 per 1,000 queries after free tier
- Your current usage: 0 queries (API not enabled yet)

## Need Help?
If you encounter issues:
1. Make sure you're logged into the correct Google account
2. Verify the project name matches your API key
3. Wait 2-3 minutes after enabling the API
4. Clear browser cache if the enable button doesn't appear