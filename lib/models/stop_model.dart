class StopModel {
  const StopModel({
    required this.stopId,
    required this.routeId,
    required this.stopName,
    required this.stopOrder,
    this.latitude,
    this.longitude,
  });

  final String stopId;
  final String routeId;
  final String stopName;
  final int stopOrder;
  final double? latitude;
  final double? longitude;
}
