class Budget {
  final String tripId;
  final String travelType; // 'road', 'train', or 'flight'
  final String travelClass; // For train: 'sleeper', 'ac3tier', 'ac2tier', 'ac1st'; For flight: 'economy', 'premium_economy', 'business'
  final double fuelCost;
  final double ticketCost;
  final double hotelCost;
  final double foodCost;
  final double tollCharges;
  final double attractionCost;
  final double miscellaneousCost;
  final String budgetCategory;

  Budget({
    required this.tripId,
    this.travelType = 'road',
    this.travelClass = '',
    this.fuelCost = 0,
    this.ticketCost = 0,
    this.hotelCost = 0,
    this.foodCost = 0,
    this.tollCharges = 0,
    this.attractionCost = 0,
    this.miscellaneousCost = 0,
    this.budgetCategory = 'standard',
  });

  double get totalCost =>
      fuelCost +
      ticketCost +
      hotelCost +
      foodCost +
      tollCharges +
      attractionCost +
      miscellaneousCost;

  Map<String, dynamic> toJson() => {
    'tripId': tripId,
    'travelType': travelType,
    'travelClass': travelClass,
    'fuelCost': fuelCost,
    'ticketCost': ticketCost,
    'hotelCost': hotelCost,
    'foodCost': foodCost,
    'tollCharges': tollCharges,
    'attractionCost': attractionCost,
    'miscellaneousCost': miscellaneousCost,
    'budgetCategory': budgetCategory,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    tripId: json['tripId'],
    travelType: json['travelType'] ?? 'road',
    travelClass: json['travelClass'] ?? '',
    fuelCost: (json['fuelCost'] ?? 0).toDouble(),
    ticketCost: (json['ticketCost'] ?? 0).toDouble(),
    hotelCost: (json['hotelCost'] ?? 0).toDouble(),
    foodCost: (json['foodCost'] ?? 0).toDouble(),
    tollCharges: (json['tollCharges'] ?? 0).toDouble(),
    attractionCost: (json['attractionCost'] ?? 0).toDouble(),
    miscellaneousCost: (json['miscellaneousCost'] ?? 0).toDouble(),
    budgetCategory: json['budgetCategory'] ?? 'standard',
  );
}
