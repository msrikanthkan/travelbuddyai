class Train {
  final String trainNumber;
  final String trainName;
  final String origin;
  final String originName;
  final String destination;
  final String destinationName;
  final String departureTime;
  final String arrivalTime;
  final double durationHours;
  final List<String> runsOn;
  final List<String> classesAvailable;

  Train({
    required this.trainNumber,
    required this.trainName,
    required this.origin,
    required this.originName,
    required this.destination,
    required this.destinationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationHours,
    required this.runsOn,
    required this.classesAvailable,
  });

  factory Train.fromJson(Map<String, dynamic> json) => Train(
        trainNumber: json['train_number'] ?? '',
        trainName: json['train_name'] ?? '',
        origin: json['origin'] ?? '',
        originName: json['origin_name'] ?? '',
        destination: json['destination'] ?? '',
        destinationName: json['destination_name'] ?? '',
        departureTime: json['departure_time'] ?? '',
        arrivalTime: json['arrival_time'] ?? '',
        durationHours: (json['duration_hours'] ?? 0).toDouble(),
        runsOn: List<String>.from(json['runs_on'] ?? []),
        classesAvailable: List<String>.from(json['classes_available'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'train_number': trainNumber,
        'train_name': trainName,
        'origin': origin,
        'origin_name': originName,
        'destination': destination,
        'destination_name': destinationName,
        'departure_time': departureTime,
        'arrival_time': arrivalTime,
        'duration_hours': durationHours,
        'runs_on': runsOn,
        'classes_available': classesAvailable,
      };

  String get displayName => '$trainNumber - $trainName';
  
  String get timingInfo => 'Dep: $departureTime | Arr: $arrivalTime';
  
  String get durationInfo {
    final hours = durationHours.floor();
    final minutes = ((durationHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }
}

// Made with Bob
