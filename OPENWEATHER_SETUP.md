# OpenWeatherMap API Setup (2 Minutes)

## Get Your FREE API Key

### Step 1: Sign Up (1 minute)
1. Go to: https://home.openweathermap.org/users/sign_up
2. Fill in:
   - Email
   - Username
   - Password
3. Click "Create Account"
4. Verify your email

### Step 2: Get API Key (30 seconds)
1. After login, go to: https://home.openweathermap.org/api_keys
2. You'll see a default API key already created
3. Copy the API key (looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### Step 3: Add to Your App (30 seconds)
Open `lib/services/openweather_service.dart` and replace:

```dart
static const String _apiKey = 'YOUR_OPENWEATHER_API_KEY';
```

With your actual key:

```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

### Step 4: Test! ✅
Run your app - weather insights will now show real-time data!

## Free Tier Details

**What you get FREE:**
- ✅ 1,000 API calls per day
- ✅ Current weather data
- ✅ 5-day forecast
- ✅ Temperature, humidity, wind
- ✅ Weather conditions & icons
- ✅ No credit card required

**Perfect for:**
- Development
- Testing
- Small to medium apps
- Personal projects

## API Activation Time

⏱️ **Important**: New API keys take 10-15 minutes to activate!

If you get "Invalid API key" error:
- Wait 10-15 minutes after signup
- The key needs time to propagate through their system
- Check your email for activation confirmation

## What Your App Will Show

**With OpenWeatherMap API:**
- ✅ Real-time temperature
- ✅ Current weather conditions
- ✅ Accurate high/low temps
- ✅ Live weather icons
- ✅ Humidity & wind data

**Fallback (if API unavailable):**
- ✅ Curated weather estimates
- ✅ Seasonal averages
- ✅ Historical data
- ✅ App still works perfectly

## Cost Information

| Tier | Calls/Day | Cost |
|------|-----------|------|
| Free | 1,000 | $0 |
| Startup | 100,000 | $40/month |
| Developer | 1,000,000 | $180/month |

**For your app**: Free tier is more than enough!

## Troubleshooting

### Error: "Invalid API key"
- Wait 10-15 minutes after signup
- Check if you copied the full key
- Verify no extra spaces

### Error: "City not found"
- API uses English city names
- Try: "Mumbai" not "मुंबई"
- Try: "Bengaluru" or "Bangalore"

### No weather data showing
- Check console logs
- App will use curated data as fallback
- Everything still works!

## Alternative: Keep Using Curated Data

**Don't want to sign up?**
- App works perfectly with curated data
- No API needed
- No rate limits
- Instant responses
- Just skip this setup!

## Support

- Documentation: https://openweathermap.org/api
- FAQ: https://openweathermap.org/faq
- Support: https://openweathermap.org/support