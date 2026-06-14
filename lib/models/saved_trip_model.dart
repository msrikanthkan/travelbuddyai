class SavedTrip {
  final String id;
  final String name;
  final String destination;
  final String occasion;
  final int budget;
  final String travelType;
  final String? trainClass;
  final int adults;
  final int children;
  final int infants;
  final int tripDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  SavedTrip({
    required this.id,
    required this.name,
    required this.destination,
    required this.occasion,
    required this.budget,
    required this.travelType,
    this.trainClass,
    required this.adults,
    required this.children,
    required this.infants,
    required this.tripDays,
    this.startDate,
    this.endDate,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'occasion': occasion,
      'budget': budget,
      'travelType': travelType,
      'trainClass': trainClass,
      'adults': adults,
      'children': children,
      'infants': infants,
      'tripDays': tripDays,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory SavedTrip.fromJson(Map<String, dynamic> json) {
    return SavedTrip(
      id: json['id'] as String,
      name: json['name'] as String,
      destination: json['destination'] as String,
      occasion: json['occasion'] as String,
      budget: json['budget'] as int,
      travelType: json['travelType'] as String,
      trainClass: json['trainClass'] as String?,
      adults: json['adults'] as int,
      children: json['children'] as int,
      infants: json['infants'] as int,
      tripDays: json['tripDays'] as int,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Helper getters
  int get totalTravelers => adults + children + infants;
  
  double get perPersonBudget => budget / totalTravelers;
  
  String get formattedBudget => '₹${budget.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  String get dateRange {
    if (startDate == null || endDate == null) return 'Dates not set';
    return '${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}';
  }

  // Create a copy with updated fields
  SavedTrip copyWith({
    String? id,
    String? name,
    String? destination,
    String? occasion,
    int? budget,
    String? travelType,
    String? trainClass,
    int? adults,
    int? children,
    int? infants,
    int? tripDays,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return SavedTrip(
      id: id ?? this.id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      occasion: occasion ?? this.occasion,
      budget: budget ?? this.budget,
      travelType: travelType ?? this.travelType,
      trainClass: trainClass ?? this.trainClass,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      tripDays: tripDays ?? this.tripDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Made with Bob
