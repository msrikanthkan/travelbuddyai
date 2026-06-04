import '../models/models.dart';
import 'pricing_service.dart';

class BudgetService {
  final PricingService _pricingService;
  
  // Constants that don't change
  static const double avgMileageKmPerLiter = 15.0; // Average car mileage
  static const double avgSpeedKmh = 60.0;

  BudgetService([PricingService? pricingService])
      : _pricingService = pricingService ?? PricingService();

  /// Calculate fuel cost based on location-specific fuel prices
  Future<double> calculateFuelCost(
    double distanceKm,
    String origin,
    [double mileage = avgMileageKmPerLiter]
  ) async {
    // Get dynamic fuel price for the origin location
    final fuelPricePerLiter = await _pricingService.getFuelPrice(origin);
    
    // Round trip calculation
    final totalDistance = distanceKm * 2;
    final litersNeeded = totalDistance / mileage;
    final fuelCost = litersNeeded * fuelPricePerLiter;
    return fuelCost;
  }

  /// Calculate toll charges based on route
  Future<double> calculateTollCharges(
    double distanceKm,
    String origin,
    String destination,
  ) async {
    // Get dynamic toll rate based on route
    final tollRatePerKm = await _pricingService.getTollRatePerKm(origin, destination);
    
    // Round trip tolls
    return distanceKm * 2 * tollRatePerKm;
  }

  /// Calculate food cost based on destination pricing
  Future<double> calculateFoodCost(
    int days,
    int familySize,
    String destination,
  ) async {
    // Get dynamic food cost per person per day
    final foodCostPerPersonPerDay = await _pricingService.getFoodCostPerPersonPerDay(destination);
    
    return days * familySize * foodCostPerPersonPerDay;
  }

  /// Estimate hotel cost based on destination and category
  Future<double> estimateHotelCost(
    int days,
    String category,
    String destination,
  ) async {
    // Get dynamic hotel prices for the destination
    final hotelPrices = await _pricingService.getHotelPrices(destination);
    
    final pricePerNight = hotelPrices[category] ?? hotelPrices['budget']!;
    
    // Number of nights = days - 1 (if 3 days trip, 2 nights stay)
    final nights = days > 1 ? days - 1 : 0;
    return pricePerNight * nights;
  }

  /// Get dynamic attraction budget
  Future<double> getAttractionBudget(
    String destination,
    int days,
    int familySize,
  ) async {
    return await _pricingService.getAttractionBudget(destination, days, familySize);
  }

  /// Calculate total budget with dynamic pricing based on travel type
  Future<Budget> calculateTotalBudget({
    required String tripId,
    required String origin,
    required String destination,
    required double distanceKm,
    required int days,
    required int adults,
    required int kids,
    required String hotelCategory,
    required String travelType, // 'road', 'train', or 'flight'
    double? attractionBudget,
  }) async {
    final familySize = adults + kids;
    
    double transportCost = 0;
    double tollCost = 0;
    
    // Calculate transport cost based on travel type
    if (travelType == 'road') {
      // Road trip: fuel + tolls
      final results = await Future.wait([
        calculateFuelCost(distanceKm, origin),
        calculateTollCharges(distanceKm, origin, destination),
      ]);
      transportCost = results[0];
      tollCost = results[1];
    } else if (travelType == 'train') {
      // Train: ticket cost (no tolls)
      transportCost = await _pricingService.getTrainTicketPrice(
        origin: origin,
        destination: destination,
        distanceKm: distanceKm,
        adults: adults,
        kids: kids,
      );
      tollCost = 0;
    } else if (travelType == 'flight') {
      // Flight: ticket cost (no tolls)
      transportCost = await _pricingService.getFlightTicketPrice(
        origin: origin,
        destination: destination,
        distanceKm: distanceKm,
        adults: adults,
        kids: kids,
      );
      tollCost = 0;
    }
    
    // Fetch other costs in parallel
    final results = await Future.wait([
      estimateHotelCost(days, hotelCategory, destination),
      calculateFoodCost(days, familySize, destination),
      attractionBudget != null
          ? Future.value(attractionBudget)
          : getAttractionBudget(destination, days, familySize),
    ]);

    return Budget(
      tripId: tripId,
      fuelCost: transportCost, // This will be fuel for road, ticket for train/flight
      hotelCost: results[0],
      foodCost: results[1],
      tollCharges: tollCost,
      attractionCost: results[2],
      budgetCategory: hotelCategory,
    );
  }

  Map<String, double> getBudgetBreakdown(Budget budget) {
    return {
      'Fuel': budget.fuelCost,
      'Hotel': budget.hotelCost,
      'Food': budget.foodCost,
      'Tolls': budget.tollCharges,
      'Attractions': budget.attractionCost,
      'Misc': budget.miscellaneousCost,
    };
  }
}
