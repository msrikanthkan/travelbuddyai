const {onRequest} = require('firebase-functions/v2/https');
// const {onSchedule} = require('firebase-functions/v2/scheduler'); // Commented out - will be used when scheduled function is re-enabled
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

/**
 * Scheduled Cloud Function that runs every 2 weeks (fortnightly)
 * Fetches train data from data.gov.in API and updates Firebase Remote Config
 *
 * Schedule: Every 2 weeks on Monday at 2:00 AM IST
 * Cron: 0 2 * * 1/2 (every 2 weeks on Monday at 2 AM)
 *
 * COMMENTED OUT: Permission issue with Cloud Build service account
 * TODO: Fix permissions and uncomment to enable scheduled updates
 */
// exports.updateTrainDataFortnightly = onSchedule({
//   schedule: '0 2 1,15 * *', // Runs on 1st and 15th of every month at 2 AM IST
//   timeZone: 'Asia/Kolkata',
//   region: 'asia-south1',
// }, async (_context) => {
//     console.log('Starting fortnightly train data update...');
//
//     try {
//       // Fetch train data from data.gov.in API
//       const trainData = await fetchTrainDataFromAPI();
//
//       // Transform data to our format
//       const formattedTrains = transformTrainData(trainData);
//
//       // Update Firebase Remote Config
//       await updateRemoteConfig(formattedTrains);
//
//       console.log(`Successfully updated train data. Total trains: ${formattedTrains.length}`);
//
//       // Log to Firestore for audit trail
//       await logUpdate(formattedTrains.length, 'success');
//
//       return null;
//     } catch (error) {
//       console.error('Error updating train data:', error);
//
//       // Log error to Firestore
//       await logUpdate(0, 'error', error.message);
//
//       // Send notification (optional - can integrate with FCM or email)
//       await sendErrorNotification(error);
//
//       throw error;
//     }
// });

/**
 * Manual trigger function for testing or immediate updates
 * Can be called via HTTP request
 */
exports.updateTrainDataManual = onRequest({
  region: 'asia-south1',
  cors: true,
}, async (req, res) => {
    // Verify authorization (add your own auth logic)
    const authToken = req.headers.authorization;
    if (!authToken || authToken !== `Bearer ${process.env.ADMIN_TOKEN}`) {
      res.status(401).send('Unauthorized');
      return;
    }
    
    try {
      console.log('Manual train data update triggered...');
      
      const trainData = await fetchTrainDataFromAPI();
      const formattedTrains = transformTrainData(trainData);
      await updateRemoteConfig(formattedTrains);
      await logUpdate(formattedTrains.length, 'success', 'Manual trigger');
      
      res.status(200).json({
        success: true,
        message: `Updated ${formattedTrains.length} trains`,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      console.error('Manual update error:', error);
      await logUpdate(0, 'error', error.message);
      
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
});

/**
 * Fetch train data from data.gov.in API
 * API Documentation: https://data.gov.in/
 */
async function fetchTrainDataFromAPI() {
  const API_KEY = process.env.DATA_GOV_IN_API_KEY;
  
  if (!API_KEY) {
    throw new Error('DATA_GOV_IN_API_KEY not configured');
  }
  
  // Example API endpoints (replace with actual data.gov.in endpoints)
  const endpoints = [
    // Indian Railways train schedule API
    'https://api.data.gov.in/resource/6176ee09-3d56-4a3b-8115-21841576b2f6',
    // Add more endpoints as needed
  ];
  
  const allTrains = [];
  
  for (const endpoint of endpoints) {
    try {
      const response = await axios.get(endpoint, {
        params: {
          'api-key': API_KEY,
          format: 'json',
          limit: 1000 // Adjust based on API limits
        },
        timeout: 30000 // 30 second timeout
      });
      
      if (response.data && response.data.records) {
        allTrains.push(...response.data.records);
      }
    } catch (error) {
      console.error(`Error fetching from ${endpoint}:`, error.message);
      // Continue with other endpoints
    }
  }
  
  if (allTrains.length === 0) {
    // Fallback to default data if API fails
    console.warn('No data from API, using fallback data');
    return getDefaultTrainData();
  }
  
  return allTrains;
}

/**
 * Transform data.gov.in format to our app's format
 */
function transformTrainData(apiData) {
  const trains = [];
  
  for (const record of apiData) {
    try {
      // Map API fields to our model
      // Adjust field names based on actual API response
      const train = {
        trainNumber: record.train_number || record.trainNo || '',
        trainName: record.train_name || record.trainName || '',
        origin: record.source_station || record.origin || '',
        destination: record.destination_station || record.destination || '',
        departureTime: record.departure_time || record.dept || '',
        arrivalTime: record.arrival_time || record.arrival || '',
        duration: record.duration || calculateDuration(record.departure_time, record.arrival_time),
        runsOn: parseRunsOn(record.runs_on || record.days || 'Daily'),
        classesAvailable: parseClasses(record.classes || record.class_available || 'SL,3A,2A,1A')
      };
      
      // Validate required fields
      if (train.trainNumber && train.trainName && train.origin && train.destination) {
        trains.push(train);
      }
    } catch (error) {
      console.error('Error transforming train record:', error, record);
    }
  }
  
  return trains;
}

/**
 * Update Firebase Remote Config with new train data
 */
async function updateRemoteConfig(trains) {
  const remoteConfig = admin.remoteConfig();
  
  // Get current template
  const template = await remoteConfig.getTemplate();
  
  // Update train_schedules_json parameter
  template.parameters['train_schedules_json'] = {
    defaultValue: {
      value: JSON.stringify(trains)
    },
    description: `Train schedules updated on ${new Date().toISOString()}. Total trains: ${trains.length}`
  };
  
  // Add metadata
  template.version = {
    versionNumber: (template.version?.versionNumber || 0) + 1,
    updateTime: new Date().toISOString(),
    updateUser: {
      email: 'automated-update@travelbuddyai.com'
    },
    description: `Automated fortnightly update - ${trains.length} trains`
  };
  
  // Publish the updated template
  await remoteConfig.publishTemplate(template);
  
  console.log('Remote Config updated successfully');
}

/**
 * Log update to Firestore for audit trail
 */
async function logUpdate(trainCount, status, notes = '') {
  const db = admin.firestore();
  
  await db.collection('train_data_updates').add({
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    trainCount: trainCount,
    status: status,
    notes: notes,
    version: new Date().toISOString()
  });
}

/**
 * Send error notification (implement based on your needs)
 * COMMENTED OUT: Only used by scheduled function
 */
// async function sendErrorNotification(error) {
//   // Option 1: Send email via SendGrid/Mailgun
//   // Option 2: Send FCM notification to admin app
//   // Option 3: Log to monitoring service (Sentry, etc.)
//
//   console.error('Error notification:', error.message);
//
//   // Example: Log to Firestore for admin dashboard
//   const db = admin.firestore();
//   await db.collection('system_alerts').add({
//     timestamp: admin.firestore.FieldValue.serverTimestamp(),
//     type: 'train_data_update_error',
//     error: error.message,
//     stack: error.stack
//   });
// }

/**
 * Helper: Calculate duration between two times
 */
function calculateDuration(departureTime, arrivalTime) {
  // Simple implementation - enhance based on actual time format
  try {
    const [depHour, depMin] = departureTime.split(':').map(Number);
    const [arrHour, arrMin] = arrivalTime.split(':').map(Number);
    
    let hours = arrHour - depHour;
    let minutes = arrMin - depMin;
    
    if (minutes < 0) {
      hours -= 1;
      minutes += 60;
    }
    
    if (hours < 0) {
      hours += 24; // Next day arrival
    }
    
    return `${hours}h ${minutes}m`;
  } catch (error) {
    return 'N/A';
  }
}

/**
 * Helper: Parse runs on days
 */
function parseRunsOn(runsOnStr) {
  if (runsOnStr.toLowerCase() === 'daily') {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }
  
  // Parse formats like "Mon,Wed,Fri" or "1,3,5"
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const result = [];
  
  const parts = runsOnStr.split(',').map(s => s.trim());
  
  for (const part of parts) {
    if (days.includes(part)) {
      result.push(part);
    } else {
      const dayNum = parseInt(part);
      if (dayNum >= 0 && dayNum <= 6) {
        result.push(days[dayNum]);
      }
    }
  }
  
  return result.length > 0 ? result : ['Daily'];
}

/**
 * Helper: Parse available classes
 */
function parseClasses(classesStr) {
  const classMap = {
    'SL': 'Sleeper',
    '3A': 'AC 3-Tier',
    '2A': 'AC 2-Tier',
    '1A': 'AC 1st Class',
    '2S': '2nd Sitting',
    'CC': 'Chair Car'
  };
  
  const classes = classesStr.split(',').map(s => s.trim());
  return classes.map(c => classMap[c] || c);
}

/**
 * Fallback default train data
 */
function getDefaultTrainData() {
  return [
    {
      trainNumber: '12728',
      trainName: 'Godavari Express',
      origin: 'Visakhapatnam',
      destination: 'Tirupati',
      departureTime: '06:30',
      arrivalTime: '18:45',
      duration: '12h 15m',
      runsOn: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      classesAvailable: ['Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'AC 1st Class']
    },
    {
      trainNumber: '17643',
      trainName: 'Circar Express',
      origin: 'Visakhapatnam',
      destination: 'Tirupati',
      departureTime: '14:20',
      arrivalTime: '03:15',
      duration: '12h 55m',
      runsOn: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      classesAvailable: ['Sleeper', 'AC 3-Tier', 'AC 2-Tier']
    },
    {
      trainNumber: '18047',
      trainName: 'Amaravathi Express',
      origin: 'Hyderabad',
      destination: 'Visakhapatnam',
      departureTime: '17:50',
      arrivalTime: '06:30',
      duration: '12h 40m',
      runsOn: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      classesAvailable: ['Sleeper', 'AC 3-Tier', 'AC 2-Tier', 'AC 1st Class']
    },
    {
      trainNumber: '12805',
      trainName: 'Janmabhoomi Express',
      origin: 'Visakhapatnam',
      destination: 'Hyderabad',
      departureTime: '20:15',
      arrivalTime: '08:45',
      duration: '12h 30m',
      runsOn: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      classesAvailable: ['Sleeper', 'AC 3-Tier', 'AC 2-Tier']
    }
  ];
}

/**
 * Cloud Function to fetch hotel data from Google Places API
 * Acts as a proxy to avoid CORS issues in Flutter web
 */
exports.searchHotels = onRequest({
  region: 'asia-south1',
  cors: true,
}, async (req, res) => {

    try {
      const { destination } = req.query;
      // maxBudget can be used for future filtering

      if (!destination) {
        res.status(400).json({ error: 'Destination is required' });
        return;
      }

      // Get API key from environment variable
      // Set via: gcloud functions deploy searchHotels --set-env-vars GOOGLE_PLACES_API_KEY=your_key
      const GOOGLE_PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY;
      
      if (!GOOGLE_PLACES_API_KEY) {
        console.error('GOOGLE_PLACES_API_KEY environment variable not set');
        res.status(500).json({
          error: 'API key not configured',
          message: 'Please set GOOGLE_PLACES_API_KEY environment variable'
        });
        return;
      }

      // Step 1: Geocode the destination
      const geocodeUrl = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(destination)}&key=${GOOGLE_PLACES_API_KEY}`;
      
      const geocodeResponse = await axios.get(geocodeUrl, { timeout: 10000 });
      
      if (geocodeResponse.data.status !== 'OK' || !geocodeResponse.data.results.length) {
        res.status(404).json({
          error: 'Location not found',
          status: geocodeResponse.data.status
        });
        return;
      }

      const location = geocodeResponse.data.results[0].geometry.location;

      // Step 2: Search for hotels using NEW Places API (Text Search)
      const placesUrl = `https://places.googleapis.com/v1/places:searchText`;
      
      const placesResponse = await axios.post(
        placesUrl,
        {
          textQuery: `hotels in ${destination}`,
          locationBias: {
            circle: {
              center: {
                latitude: location.lat,
                longitude: location.lng
              },
              radius: 5000.0
            }
          },
          maxResultCount: 20 // Increased from 5 to 20 for more options
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': GOOGLE_PLACES_API_KEY,
            'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.rating,places.priceLevel,places.id'
          },
          timeout: 10000
        }
      );

      if (!placesResponse.data.places || placesResponse.data.places.length === 0) {
        res.status(404).json({
          error: 'No hotels found',
          status: 'ZERO_RESULTS'
        });
        return;
      }

      // Transform results from new API format
      const hotels = placesResponse.data.places.map(place => ({
        name: place.displayName?.text || 'Unknown Hotel',
        rating: place.rating || 3.5,
        address: place.formattedAddress || 'Address not available',
        placeId: place.id,
        priceLevel: place.priceLevel ? ['FREE', 'INEXPENSIVE', 'MODERATE', 'EXPENSIVE', 'VERY_EXPENSIVE'].indexOf(place.priceLevel) : 2
      }));

      res.status(200).json({
        success: true,
        destination: destination,
        hotels: hotels,
        count: hotels.length
      });

    } catch (error) {
      console.error('Error fetching hotels:', error);
      res.status(500).json({
        error: 'Failed to fetch hotels',
        message: error.message
      });
    }
});

// Made with Bob
