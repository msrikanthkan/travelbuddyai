import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_destinations_service.dart';
import 'services/toll_service.dart';
import 'services/train_data_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Train Data Service
    await TrainDataService().initialize();
    
    // Initialize Firebase Destinations Service
    await FirebaseDestinationsService().initialize();
    
    // Initialize Toll Service (loads bundled toll_plazas.json asset)
    await TollService().initialize();
  } catch (e) {
    print('Error initializing Firebase: $e');
    // App will continue with fallback data
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelBuddyAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
