class StopModel {
  const StopModel({
    required this.stopId,
    required this.stopName,
    this.routeId,
    this.stopOrder = 0,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String stopId;
  final String? routeId;
  final String stopName;
  final int stopOrder;
  final double? latitude;
  final double? longitude;
  final String? address;
}
