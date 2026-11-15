enum AlarmType { timer, location }

class AlarmModel {
  const AlarmModel({
    required this.id,
    required this.type,
    required this.routeId,
    required this.routeName,
    required this.destination,
    required this.enabled,
    this.hour,
    this.minute,
    this.repeatDays = const [],
    this.stopId,
    this.stopName,
    this.latitude,
    this.longitude,
    this.thresholdMeters,
  });

  final String id;
  final AlarmType type;
  final String routeId;
  final String routeName;
  final String destination;
  final bool enabled;
  final int? hour;
  final int? minute;
  final List<int> repeatDays;
  final String? stopId;
  final String? stopName;
  final double? latitude;
  final double? longitude;
  final int? thresholdMeters;

  AlarmModel copyWith({bool? enabled}) => AlarmModel(
    id: id,
    type: type,
    routeId: routeId,
    routeName: routeName,
    destination: destination,
    enabled: enabled ?? this.enabled,
    hour: hour,
    minute: minute,
    repeatDays: repeatDays,
    stopId: stopId,
    stopName: stopName,
    latitude: latitude,
    longitude: longitude,
    thresholdMeters: thresholdMeters,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'routeId': routeId,
    'routeName': routeName,
    'destination': destination,
    'enabled': enabled,
    'hour': hour,
    'minute': minute,
    'repeatDays': repeatDays,
    'stopId': stopId,
    'stopName': stopName,
    'latitude': latitude,
    'longitude': longitude,
    'thresholdMeters': thresholdMeters,
  };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
    id: json['id'] as String,
    type: AlarmType.values.byName(json['type'] as String),
    routeId: json['routeId'] as String,
    routeName: json['routeName'] as String,
    destination: json['destination'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
    hour: (json['hour'] as num?)?.toInt(),
    minute: (json['minute'] as num?)?.toInt(),
    repeatDays: (json['repeatDays'] as List? ?? const [])
        .map((day) => (day as num).toInt())
        .toList(),
    stopId: json['stopId'] as String?,
    stopName: json['stopName'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    thresholdMeters: (json['thresholdMeters'] as num?)?.toInt(),
  );
}
