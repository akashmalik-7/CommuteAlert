enum TransportType { bus, van }

class RouteModel {
  const RouteModel({
    required this.routeId,
    required this.routeName,
    required this.transportType,
    required this.startLocation,
    required this.destination,
    required this.estimatedDuration,
    required this.isDirect,
    required this.isExpress,
    required this.isPopular,
    this.totalStops = 0,
  });

  final String routeId;
  final String routeName;
  final TransportType transportType;
  final String startLocation;
  final String destination;
  final String estimatedDuration;
  final bool isDirect;
  final bool isExpress;
  final bool isPopular;
  final int totalStops;

  String get transportLabel =>
      transportType == TransportType.bus ? 'Bus' : 'Van';

  Map<String, dynamic> toFirestore() => {
        'routeId': routeId,
        'routeName': routeName,
        'transportType': transportLabel.toLowerCase(),
        'startLocation': startLocation,
        'destination': destination,
        'totalStops': totalStops,
        'estimatedDuration': estimatedDuration,
        'isDirect': isDirect,
        'isExpress': isExpress,
        'isPopular': isPopular,
      };
}

const demoRoutes = <RouteModel>[
  RouteModel(
    routeId: 'demo-01',
    routeName: 'Route 01',
    transportType: TransportType.bus,
    startLocation: 'General Bus Stand',
    destination: 'Bosan Road',
    estimatedDuration: '35 min',
    isDirect: true,
    isExpress: false,
    isPopular: true,
    totalStops: 8,
  ),
  RouteModel(
    routeId: 'demo-02',
    routeName: 'Route 02',
    transportType: TransportType.van,
    startLocation: 'Cantt',
    destination: 'Multan University',
    estimatedDuration: '25 min',
    isDirect: true,
    isExpress: true,
    isPopular: true,
    totalStops: 5,
  ),
  RouteModel(
    routeId: 'demo-03',
    routeName: 'Route 03',
    transportType: TransportType.bus,
    startLocation: 'Chowk Kumharanwala',
    destination: 'Gulgasht Colony',
    estimatedDuration: '40 min',
    isDirect: false,
    isExpress: false,
    isPopular: true,
    totalStops: 10,
  ),
];
