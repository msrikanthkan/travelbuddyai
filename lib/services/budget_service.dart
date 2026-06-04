import '../models/models.dart';

class BudgetService {
  static const double fuelRatePerKm = 3.5;
  static const double avgSpeedKmh = 50;
  static const double foodCostPerPersonPerDay = 300;
  static const double tollRatePerKm = 0.5;

  double calculateFuelCost(double distanceKm, double mileage = 15) {
    return (distanceKm / mileage) * fuelRatePerKm * 2;
  }

  double calculateTollCharges(double distanceKm) {
    return distanceKm * tollRatePerKm;
  }

  double calculateFoodCost(int days, int familySize) {
    return days * familySize * foodCostPerPersonPerDay;
  }

  double estimateHotelCost(int days, String category) {
    double basePrice;
    switch (category) {
      case 'budget':
        basePrice = 500;
        break;
      case 'premium':
        basePrice = 2500;
        break;
      case 'luxury':
        basePrice = 5000;
        break;
      default:
        basePrice = 1000;
    }
    return basePrice * (days - 1);
  }

  Budget calculateTotalBudget({
    required String tripId,
    required double distanceKm,
    required int days,
    required int familySize,
    required String hotelCategory,
    double attractionBudget = 1000,
  }) {
    return Budget(
      tripId: tripId,
      fuelCost: calculateFuelCost(distanceKm),
      hotelCost: estimateHotelCost(days, hotelCategory),
      foodCost: calculateFoodCost(days, familySize),
      tollCharges: calculateTollCharges(distanceKm),
      attractionCost: attractionBudget,
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
