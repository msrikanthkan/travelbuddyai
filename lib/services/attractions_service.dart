import '../models/models.dart';

class AttractionsService {
  static final Map<String, List<Attraction>> _attractionsByDestination = {
    'Tirupati': [
      Attraction(
        id: '1',
        name: 'Tirupati Venkateswara Temple',
        description: 'Ancient Hindu temple on a hilltop',
        location: 'Tirupati',
        ticketPrice: 50,
        rating: 4.8,
        images: ['https://picsum.photos/800/600?random=1'],
        category: 'Religious',
        isKidFriendly: true,
      ),
      Attraction(
        id: '2',
        name: 'Sri Kalahasteeswara Temple',
        description: 'Temple dedicated to Lord Shiva',
        location: 'Srikalahasti',
        ticketPrice: 0,
        rating: 4.6,
        images: ['https://picsum.photos/800/600?random=2'],
        category: 'Religious',
        isKidFriendly: true,
      ),
      Attraction(
        id: '3',
        name: 'Chandragiri Fort',
        description: 'Historic fort with panoramic views',
        location: 'Chandragiri',
        ticketPrice: 100,
        rating: 4.3,
        images: ['https://picsum.photos/800/600?random=3'],
        category: 'Historical',
        isKidFriendly: true,
      ),
    ],
    'Vizag': [
      Attraction(
        id: '4',
        name: 'Kailasagiri',
        description: '380m high hill with ropeway and sea views',
        location: 'Visakhapatnam',
        ticketPrice: 200,
        rating: 4.5,
        images: ['https://picsum.photos/800/600?random=4'],
        category: 'Nature',
        isKidFriendly: true,
      ),
      Attraction(
        id: '5',
        name: 'Submarine Museum',
        description: 'INS Kursura submarine converted to museum',
        location: 'Visakhapatnam',
        ticketPrice: 100,
        rating: 4.4,
        images: ['https://picsum.photos/800/600?random=5'],
        category: 'Museum',
        isKidFriendly: true,
      ),
      Attraction(
        id: '6',
        name: 'Araku Valley',
        description: 'Scenic valley with waterfalls and coffee plantations',
        location: 'Araku',
        ticketPrice: 0,
        rating: 4.6,
        images: ['https://picsum.photos/800/600?random=6'],
        category: 'Nature',
        isKidFriendly: true,
      ),
    ],
    'Hyderabad': [
      Attraction(
        id: '7',
        name: 'Charminar',
        description: 'Historic monument and mosque in old city',
        location: 'Hyderabad',
        ticketPrice: 25,
        rating: 4.5,
        images: ['https://picsum.photos/800/600?random=7'],
        category: 'Historical',
        isKidFriendly: true,
      ),
      Attraction(
        id: '8',
        name: 'Hussain Sagar Lake',
        description: 'Large artificial lake with scenic views',
        location: 'Hyderabad',
        ticketPrice: 0,
        rating: 4.3,
        images: ['https://picsum.photos/800/600?random=8'],
        category: 'Nature',
        isKidFriendly: true,
      ),
      Attraction(
        id: '9',
        name: 'Salarjung Museum',
        description: 'World-class museum with artifacts',
        location: 'Hyderabad',
        ticketPrice: 150,
        rating: 4.5,
        images: ['https://picsum.photos/800/600?random=9'],
        category: 'Museum',
        isKidFriendly: true,
      ),
    ],
  };

  Future<List<Attraction>> getAttractionsByDestination(String destination) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final key = _attractionsByDestination.keys.firstWhere(
      (k) => k.toLowerCase().contains(destination.toLowerCase()) || destination.toLowerCase().contains(k.toLowerCase()),
      orElse: () => '',
    );

    return key.isEmpty ? _getDefaultAttractions() : _attractionsByDestination[key]!;
  }

  List<Attraction> _getDefaultAttractions() {
    return [
      Attraction(
        id: '10',
        name: 'Local Market',
        description: 'Traditional market for local crafts',
        location: 'City Center',
        ticketPrice: 0,
        rating: 4.0,
        images: ['https://picsum.photos/800/600?random=10'],
        category: 'Shopping',
        isKidFriendly: true,
      ),
      Attraction(
        id: '11',
        name: 'City Beach',
        description: 'Scenic beach for relaxation',
        location: 'Coastal Area',
        ticketPrice: 0,
        rating: 4.2,
        images: ['https://picsum.photos/800/600?random=11'],
        category: 'Nature',
        isKidFriendly: true,
      ),
    ];
  }
}
