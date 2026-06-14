# 🌍 TravelBuddyAI

An intelligent travel planning and budgeting application built with Flutter that helps users plan trips, calculate budgets, find attractions, and make informed travel decisions.

## 📱 Features

- **Smart Travel Budget Planner** - Calculate comprehensive trip costs with multi-modal travel support (Road/Train/Flight)
- **Travel Bargain Assistant** - Local pricing and negotiation tips
- **Family Road Trip Planner** - Find family-friendly stops and amenities
- **Travel Scam Alert** - Community-reported scams with AI risk scoring
- **AI Itinerary Generator** - Automated route and schedule planning
- **Safe Travel Companion** - Safe routes and SOS features
- **Offline Travel Translator** - Multi-language support
- **Local Food Finder** - Discover local specialties
- **Road Trip Co-Pilot** - Fuel and toll predictions
- **Travel Health Assistant** - Emergency services locator

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart SDK
- Android Studio / VS Code
- Firebase account

### Installation

1. **Clone the repository:**
   ```bash
   git clone [repository-url]
   cd travelbuddyai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Follow the detailed instructions in [FIREBASE_COMPLETE_SETUP.md](FIREBASE_COMPLETE_SETUP.md)
   - Download `google-services.json` and place in `android/app/`
   - Update `lib/firebase_options.dart` with your Firebase credentials

4. **Run the app:**
   ```bash
   flutter run
   ```

## 📚 Documentation

### Complete Application Documentation
- **[TravelBuddyAI_Documentation.html](TravelBuddyAI_Documentation.html)** - Comprehensive application documentation
  - Open in browser or Microsoft Word
  - Contains architecture, features, APIs, and setup guides
  - 847 lines of detailed technical documentation

### Documentation Maintenance
- **[DOCUMENTATION_MAINTENANCE.md](DOCUMENTATION_MAINTENANCE.md)** - Guide for keeping documentation updated
- **[update_documentation.ps1](update_documentation.ps1)** - Helper script to check what needs updating

**Important:** When making changes to the application, please update the documentation:
```powershell
# Run this script to check what documentation sections need updates
.\update_documentation.ps1
```

### Setup Guides
- [FIREBASE_COMPLETE_SETUP.md](FIREBASE_COMPLETE_SETUP.md) - Complete Firebase setup instructions
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Quick Firebase setup guide
- [FIRESTORE_DESTINATIONS_SETUP.md](FIRESTORE_DESTINATIONS_SETUP.md) - Firestore configuration
- [OPENWEATHER_SETUP.md](OPENWEATHER_SETUP.md) - Weather API setup
- [ENABLE_GOOGLE_SEARCH_API.md](ENABLE_GOOGLE_SEARCH_API.md) - Google Search API setup

## 🏗️ Project Structure

```
travelbuddyai/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── models/                      # Data models
│   ├── screens/                     # UI screens
│   └── services/                    # Business logic & APIs
├── android/                         # Android configuration
├── ios/                            # iOS configuration
├── functions/                      # Firebase Cloud Functions
├── TravelBuddyAI_Documentation.html # Complete documentation
├── DOCUMENTATION_MAINTENANCE.md     # Documentation guide
└── update_documentation.ps1         # Documentation helper script
```

## 🛠️ Tech Stack

- **Framework:** Flutter 3.11.0
- **Language:** Dart
- **Backend:** Firebase (Core, Remote Config)
- **State Management:** StatefulWidget
- **HTTP Client:** http package
- **Caching:** cached_network_image, shared_preferences

## 🔥 Firebase Integration

The app uses Firebase Remote Config for dynamic train schedule updates:
- Train data can be updated without app releases
- 12-hour fetch interval for fresh data
- Local caching for offline access
- See [FIREBASE_COMPLETE_SETUP.md](FIREBASE_COMPLETE_SETUP.md) for setup

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  cached_network_image: ^3.3.0
  firebase_core: ^2.24.2
  firebase_remote_config: ^4.3.8
  shared_preferences: ^2.2.2
```

## 🧪 Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Update documentation** (run `.\update_documentation.ps1`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

### Documentation Updates Required

When contributing, please update the documentation if you:
- Add or modify features
- Change data models
- Update services or APIs
- Modify dependencies
- Change Firebase configuration
- Restructure the codebase

See [DOCUMENTATION_MAINTENANCE.md](DOCUMENTATION_MAINTENANCE.md) for details.

## 📄 License

This project is licensed under the [LICENSE TYPE] - see the LICENSE file for details.

## 📞 Support

- **Documentation:** See [TravelBuddyAI_Documentation.html](TravelBuddyAI_Documentation.html)
- **Issues:** Report bugs via GitHub Issues
- **Setup Help:** Check the setup guides in the repository

## 🎯 Roadmap

- [ ] Real-time Train API integration
- [ ] Weather API integration (OpenWeather)
- [ ] Google Maps integration
- [ ] User authentication
- [ ] Trip history and saved trips
- [ ] Social sharing features
- [ ] Offline mode enhancements
- [ ] Multi-language UI support

## 📊 Version

**Current Version:** 1.0.0+1

---

**Made with ❤️ using Flutter**

For detailed technical documentation, open [TravelBuddyAI_Documentation.html](TravelBuddyAI_Documentation.html) in your browser or Microsoft Word.
