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
    this.isActive = true,
    this.departureTime,
    this.arrivalTime,
    this.fare,
    this.stopIds = const [],
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
  final bool isActive;
  final String? departureTime;
  final String? arrivalTime;
  final double? fare;
  final List<String> stopIds;

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
    'isActive': isActive,
    'departureTime': departureTime,
    'arrivalTime': arrivalTime,
    'fare': fare,
    'stops': stopIds,
  };
}
