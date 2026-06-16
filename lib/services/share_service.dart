import 'package:share_plus/share_plus.dart';
import '../models/itinerary_day_model.dart';

class ShareService {
  /// Share trip summary from trip planner screen
  static Future<void> shareTripSummary({
    required String destination,
    required String occasion,
    required int budget,
    required String travelType,
    String? trainClass,
    required int adults,
    required int children,
    required int infants,
    required int tripDays,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final totalTravelers = adults + children + infants;
    final perPersonBudget = (budget / totalTravelers).toStringAsFixed(0);
    
    final StringBuffer message = StringBuffer();
    message.writeln('🌍 TravelBuddyAI Trip Plan');
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln();
    
    if (destination.isNotEmpty) {
      message.writeln('📍 Destination: $destination');
      message.writeln('🎉 Occasion: ${_formatOccasion(occasion)}');
      message.writeln();
    }
    
    message.writeln('💰 Budget Details:');
    message.writeln('   Total Budget: ₹$budget');
    message.writeln('   Per Person: ₹$perPersonBudget');
    message.writeln('   Trip Duration: $tripDays ${tripDays == 1 ? 'Day' : 'Days'}');
    
    if (startDate != null && endDate != null) {
      message.writeln('   Travel Dates: ${_formatDate(startDate)} - ${_formatDate(endDate)}');
    }
    
    message.writeln('   Per Day (Total): ₹${(budget / tripDays).toStringAsFixed(0)}');
    message.writeln();
    
    message.writeln('🚗 Travel Details:');
    message.writeln('   Travel Mode: ${_formatTravelType(travelType)}');
    if (trainClass != null) {
      message.writeln('   Train Class: ${_formatTrainClass(trainClass)}');
    }
    message.writeln();
    
    message.writeln('👥 Travelers: $totalTravelers ${totalTravelers == 1 ? 'Person' : 'People'}');
    if (adults > 0) message.writeln('   👨 Adults: $adults');
    if (children > 0) message.writeln('   👦 Children: $children');
    if (infants > 0) message.writeln('   👶 Infants: $infants');
    message.writeln();
    
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln('Planned with TravelBuddyAI 🤖');
    
    await Share.share(
      message.toString(),
      subject: 'My $destination Trip Plan',
    );
  }

  /// Share detailed itinerary
  static Future<void> shareDetailedItinerary({
    required String destination,
    required String occasion,
    required int tripDays,
    required int budget,
    required int totalTravelers,
    required List<ItineraryDay> itinerary,
    DateTime? startDate,
  }) async {
    final totalCost = itinerary.fold<double>(0, (sum, day) => sum + day.estimatedCost);
    
    final StringBuffer message = StringBuffer();
    message.writeln('🌍 TravelBuddyAI Detailed Itinerary');
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln();
    
    message.writeln('📍 $destination');
    message.writeln('🎉 ${_formatOccasion(occasion)} Trip');
    message.writeln('📅 $tripDays Days | 👥 $totalTravelers Travelers');
    message.writeln('💰 Estimated Cost: ₹${totalCost.toStringAsFixed(0)}');
    message.writeln();
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln();
    
    for (var day in itinerary) {
      final date = startDate?.add(Duration(days: day.dayNumber - 1));
      
      message.writeln('📆 Day ${day.dayNumber}${date != null ? ' (${_formatDate(date)})' : ''}');
      message.writeln('${day.title}');
      message.writeln('Est. Cost: ${day.formattedCost}');
      message.writeln();
      
      // Activities
      if (day.activities.isNotEmpty) {
        message.writeln('🎯 Activities:');
        for (var activity in day.activities) {
          message.writeln('   ${activity.icon} ${activity.name}');
          message.writeln('      ⏰ ${activity.time} • ${activity.duration}');
          message.writeln('      💵 ${activity.formattedCost}');
          if (activity.location != null) {
            message.writeln('      📍 ${activity.location}');
          }
        }
        message.writeln();
      }
      
      // Meals
      if (day.meals.isNotEmpty) {
        message.writeln('🍽️ Meals:');
        for (var meal in day.meals) {
          message.writeln('   ${meal.icon} ${meal.name}');
          message.writeln('      ${meal.type.toUpperCase()} • ${meal.time}');
          message.writeln('      💵 ${meal.formattedCost}');
          if (meal.restaurant != null) {
            message.writeln('      🍴 ${meal.restaurant}');
          }
        }
        message.writeln();
      }
      
      // Accommodation
      if (day.accommodation != null) {
        final acc = day.accommodation!;
        message.writeln('🏨 Accommodation:');
        message.writeln('   ${acc.name}');
        message.writeln('      ${acc.type} • ⭐ ${acc.rating}');
        message.writeln('      💵 ${acc.formattedCost}');
        if (acc.address != null) {
          message.writeln('      📍 ${acc.address}');
        }
        message.writeln();
      }
      
      message.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      message.writeln();
    }
    
    message.writeln('Planned with TravelBuddyAI 🤖');
    message.writeln('Your AI-powered travel companion');
    
    await Share.share(
      message.toString(),
      subject: '$destination - $tripDays Day Itinerary',
    );
  }

  /// Share a specific day's itinerary
  static Future<void> shareDayItinerary({
    required String destination,
    required ItineraryDay day,
    DateTime? date,
  }) async {
    final StringBuffer message = StringBuffer();
    message.writeln('🌍 TravelBuddyAI Day Plan');
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln();
    
    message.writeln('📍 $destination');
    message.writeln('📆 Day ${day.dayNumber}${date != null ? ' (${_formatDate(date)})' : ''}');
    message.writeln('${day.title}');
    message.writeln('Est. Cost: ${day.formattedCost}');
    message.writeln();
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln();
    
    // Activities
    if (day.activities.isNotEmpty) {
      message.writeln('🎯 Activities:');
      for (var activity in day.activities) {
        message.writeln('${activity.icon} ${activity.name}');
        message.writeln('   ⏰ ${activity.time} • ${activity.duration}');
        message.writeln('   💵 ${activity.formattedCost}');
        message.writeln('   ${activity.description}');
        if (activity.location != null) {
          message.writeln('   📍 ${activity.location}');
        }
        message.writeln();
      }
    }
    
    // Meals
    if (day.meals.isNotEmpty) {
      message.writeln('🍽️ Meals:');
      for (var meal in day.meals) {
        message.writeln('${meal.icon} ${meal.name}');
        message.writeln('   ${meal.type.toUpperCase()} • ${meal.time}');
        message.writeln('   💵 ${meal.formattedCost}');
        if (meal.restaurant != null) {
          message.writeln('   🍴 ${meal.restaurant}');
        }
        message.writeln();
      }
    }
    
    // Accommodation
    if (day.accommodation != null) {
      final acc = day.accommodation!;
      message.writeln('🏨 Accommodation:');
      message.writeln('${acc.name}');
      message.writeln('   ${acc.type} • ⭐ ${acc.rating}');
      message.writeln('   💵 ${acc.formattedCost}');
      if (acc.address != null) {
        message.writeln('   📍 ${acc.address}');
      }
      message.writeln();
    }
    
    message.writeln('━━━━━━━━━━━━━━━━━━━━━━');
    message.writeln('Planned with TravelBuddyAI 🤖');
    
    await Share.share(
      message.toString(),
      subject: '$destination - Day ${day.dayNumber} Plan',
    );
  }

  // Helper methods
  static String _formatOccasion(String occasion) {
    return occasion[0].toUpperCase() + occasion.substring(1);
  }

  static String _formatTravelType(String travelType) {
    return travelType[0].toUpperCase() + travelType.substring(1);
  }

  static String _formatTrainClass(String trainClass) {
    final Map<String, String> classNames = {
      'sleeper': 'Sleeper Class',
      'ac3tier': 'AC 3-Tier',
      'ac2tier': 'AC 2-Tier',
      'ac1st': 'AC 1st Class',
    };
    return classNames[trainClass] ?? trainClass;
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Made with Bob
