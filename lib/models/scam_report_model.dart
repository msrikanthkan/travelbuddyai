enum ScamType { fakeGuide, overchargingTaxi, unsafeHotel, fraudAgent, other }

enum RiskLevel { low, medium, high }

class ScamReport {
  final String id;
  final String location;
  final ScamType scamType;
  final String description;
  final DateTime reportedAt;
  final RiskLevel riskLevel;
  final String reportedBy;
  final bool isVerified;

  ScamReport({
    required this.id,
    required this.location,
    required this.scamType,
    required this.description,
    required this.reportedAt,
    this.riskLevel = RiskLevel.medium,
    this.reportedBy = 'Anonymous',
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'location': location,
    'scamType': scamType.name,
    'description': description,
    'reportedAt': reportedAt.toIso8601String(),
    'riskLevel': riskLevel.name,
    'reportedBy': reportedBy,
    'isVerified': isVerified,
  };

  factory ScamReport.fromJson(Map<String, dynamic> json) => ScamReport(
    id: json['id'],
    location: json['location'],
    scamType: ScamType.values.firstWhere(
      (e) => e.name == json['scamType'],
      orElse: () => ScamType.other,
    ),
    description: json['description'],
    reportedAt: DateTime.parse(json['reportedAt']),
    riskLevel: RiskLevel.values.firstWhere(
      (e) => e.name == json['riskLevel'],
      orElse: () => RiskLevel.medium,
    ),
    reportedBy: json['reportedBy'] ?? 'Anonymous',
    isVerified: json['isVerified'] ?? false,
  );
}
