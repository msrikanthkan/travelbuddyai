class Itinerary {
  final String id;
  final String tripId;
  final List<ItineraryDay> days;
  final double totalEstimatedCost;
  final String summary;

  Itinerary({
    required this.id,
    required this.tripId,
    required this.days,
    this.totalEstimatedCost = 0,
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'days': days.map((d) => d.toJson()).toList(),
    'totalEstimatedCost': totalEstimatedCost,
    'summary': summary,
  };

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
    id: json['id'],
    tripId: json['tripId'],
    days: (json['days'] as List).map((d) => ItineraryDay.fromJson(d)).toList(),
    totalEstimatedCost: (json['totalEstimatedCost'] ?? 0).toDouble(),
    summary: json['summary'] ?? '',
  );
}

class ItineraryDay {
  final int dayNumber;
  final String date;
  final List<ItineraryItem> items;

  ItineraryDay({
    required this.dayNumber,
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'dayNumber': dayNumber,
    'date': date,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
    dayNumber: json['dayNumber'],
    date: json['date'],
    items: (json['items'] as List)
        .map((i) => ItineraryItem.fromJson(i))
        .toList(),
  );
}

class ItineraryItem {
  final String time;
  final String title;
  final String description;
  final double cost;
  final String type;

  ItineraryItem({
    required this.time,
    required this.title,
    required this.description,
    this.cost = 0,
    this.type = 'activity',
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'title': title,
    'description': description,
    'cost': cost,
    'type': type,
  };

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
    time: json['time'],
    title: json['title'],
    description: json['description'],
    cost: (json['cost'] ?? 0).toDouble(),
    type: json['type'] ?? 'activity',
  );
}
