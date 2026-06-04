class Budget {
  final String tripId;
  final double fuelCost;
  final double hotelCost;
  final double foodCost;
  final double tollCharges;
  final double attractionCost;
  final double miscellaneousCost;
  final String budgetCategory;

  Budget({
    required this.tripId,
    this.fuelCost = 0,
    this.hotelCost = 0,
    this.foodCost = 0,
    this.tollCharges = 0,
    this.attractionCost = 0,
    this.miscellaneousCost = 0,
    this.budgetCategory = 'standard',
  });

  double get totalCost =>
      fuelCost +
      hotelCost +
      foodCost +
      tollCharges +
      attractionCost +
      miscellaneousCost;

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'fuelCost': fuelCost,
    'hotelCost': hotelCost,
    'foodCost': foodCost,
    'tollCharges': tollCharges,
    'attractionCost': attractionCost,
    'miscellaneousCost': miscellaneousCost,
    'budgetCategory': budgetCategory,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    tripId: json['tripId'],
    fuelCost: (json['fuelCost'] ?? 0).toDouble(),
    hotelCost: (json['hotelCost'] ?? 0).toDouble(),
    foodCost: (json['foodCost'] ?? 0).toDouble(),
    tollCharges: (json['tollCharges'] ?? 0).toDouble(),
    attractionCost: (json['attractionCost'] ?? 0).toDouble(),
    miscellaneousCost: (json['miscellaneousCost'] ?? 0).toDouble(),
    budgetCategory: json['budgetCategory'] ?? 'standard',
  );
}
