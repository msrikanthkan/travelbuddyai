class Trip {
  final String id;
  final String source;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int familySize;
  final String tripType;
  final double budget;
  final List<String> interests;

  Trip({
    required this.id,
    required this.source,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.familySize,
    this.tripType = 'road',
    this.budget = 0,
    this.interests = const [],
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'familySize': familySize,
    'tripType': tripType,
    'budget': budget,
    'interests': interests,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'],
    source: json['source'],
    destination: json['destination'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    familySize: json['familySize'],
    tripType: json['tripType'] ?? 'road',
    budget: (json['budget'] ?? 0).toDouble(),
    interests: List<String>.from(json['interests'] ?? []),
  );
}
