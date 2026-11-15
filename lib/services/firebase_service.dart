import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/timetable_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> seedSampleDataIfEmpty() async {
    final existing = await _firestore.collection('routes').limit(1).get();
    if (existing.docs.isNotEmpty) return false;

    final batch = _firestore.batch();
    final route = _firestore.collection('routes').doc('route_campus_central');
    batch.set(route, {
      'routeId': 'route_campus_central',
      'routeName': 'Campus - Central Market',
      'transportType': 'bus',
      'startLocation': 'University Campus',
      'destination': 'Central Market',
      'estimatedDuration': '25 min',
      'totalStops': 3,
      'isDirect': true,
      'isExpress': false,
      'isPopular': true,
      'isActive': true,
      'fare': 40,
      'stops': ['stop_campus_gate', 'stop_city_hall', 'stop_central_market'],
    });

    final van = _firestore.collection('routes').doc('route_station_airport');
    batch.set(van, {
      'routeId': 'route_station_airport',
      'routeName': 'City Station - Airport',
      'transportType': 'van',
      'startLocation': 'City Station',
      'destination': 'Airport Terminal',
      'estimatedDuration': '35 min',
      'totalStops': 3,
      'isDirect': false,
      'isExpress': true,
      'isPopular': true,
      'isActive': true,
      'fare': 80,
      'stops': ['stop_city_station', 'stop_ring_road', 'stop_airport'],
    });

    final stops = <String, Map<String, Object>>{
      'stop_campus_gate': {
        'stopId': 'stop_campus_gate',
        'routeId': 'route_campus_central',
        'stopName': 'Campus Main Gate',
        'stopOrder': 1,
        'latitude': 24.8607,
        'longitude': 67.0011,
        'address': 'University Campus Main Gate',
      },
      'stop_city_hall': {
        'stopId': 'stop_city_hall',
        'routeId': 'route_campus_central',
        'stopName': 'City Hall',
        'stopOrder': 2,
        'latitude': 24.8615,
        'longitude': 67.0099,
        'address': 'City Hall Road',
      },
      'stop_central_market': {
        'stopId': 'stop_central_market',
        'routeId': 'route_campus_central',
        'stopName': 'Central Market',
        'stopOrder': 3,
        'latitude': 24.8632,
        'longitude': 67.0124,
        'address': 'Central Market Entrance',
      },
      'stop_city_station': {
        'stopId': 'stop_city_station',
        'routeId': 'route_station_airport',
        'stopName': 'City Station',
        'stopOrder': 1,
        'latitude': 24.8587,
        'longitude': 67.0051,
        'address': 'City Station Main Entrance',
      },
      'stop_ring_road': {
        'stopId': 'stop_ring_road',
        'routeId': 'route_station_airport',
        'stopName': 'Ring Road',
        'stopOrder': 2,
        'latitude': 24.8721,
        'longitude': 67.0355,
        'address': 'Ring Road Van Stop',
      },
      'stop_airport': {
        'stopId': 'stop_airport',
        'routeId': 'route_station_airport',
        'stopName': 'Airport Terminal',
        'stopOrder': 3,
        'latitude': 24.9065,
        'longitude': 67.1608,
        'address': 'Airport Terminal Entrance',
      },
    };
    for (final entry in stops.entries) {
      batch.set(_firestore.collection('stops').doc(entry.key), entry.value);
    }

    batch.set(
      _firestore
          .collection('timetables')
          .doc('timetable_campus_central_weekday'),
      {
        'timetableId': 'timetable_campus_central_weekday',
        'routeId': 'route_campus_central',
        'departureTime': '07:30',
        'arrivalTime': '07:55',
        'operatingDays': [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        ],
        'scheduleStatus': 'Active',
      },
    );
    batch.set(
      _firestore
          .collection('timetables')
          .doc('timetable_station_airport_daily'),
      {
        'timetableId': 'timetable_station_airport_daily',
        'routeId': 'route_station_airport',
        'departureTime': '08:00',
        'arrivalTime': '08:35',
        'operatingDays': [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ],
        'scheduleStatus': 'Active',
      },
    );

    await batch.commit();
    return true;
  }

  Future<void> ensurePopularRoutes() async {
    const popularRoutes = <String, Map<String, Object>>{
      'route_north_terminal': {
        'routeId': 'route_north_terminal',
        'routeName': 'North Terminal - Downtown',
        'transportType': 'bus',
        'startLocation': 'North Terminal',
        'destination': 'Downtown',
        'estimatedDuration': '30 min',
        'totalStops': 4,
        'isDirect': true,
        'isExpress': false,
        'isPopular': true,
        'isActive': true,
        'fare': 50,
        'stops': <String>[],
      },
      'route_lakeside_university': {
        'routeId': 'route_lakeside_university',
        'routeName': 'Lakeside - University',
        'transportType': 'van',
        'startLocation': 'Lakeside',
        'destination': 'University Campus',
        'estimatedDuration': '20 min',
        'totalStops': 3,
        'isDirect': true,
        'isExpress': true,
        'isPopular': true,
        'isActive': true,
        'fare': 45,
        'stops': <String>[],
      },
      'route_old_town_station': {
        'routeId': 'route_old_town_station',
        'routeName': 'Old Town - City Station',
        'transportType': 'bus',
        'startLocation': 'Old Town',
        'destination': 'City Station',
        'estimatedDuration': '28 min',
        'totalStops': 5,
        'isDirect': false,
        'isExpress': false,
        'isPopular': true,
        'isActive': true,
        'fare': 35,
        'stops': <String>[],
      },
    };

    final existing = await _firestore.collection('routes').get();
    final existingIds = existing.docs.map((doc) => doc.id).toSet();
    final batch = _firestore.batch();
    var pendingWrites = 0;
    for (final entry in popularRoutes.entries) {
      if (existingIds.contains(entry.key)) continue;
      batch.set(_firestore.collection('routes').doc(entry.key), entry.value);
      pendingWrites++;
    }
    if (pendingWrites > 0) await batch.commit();
  }

  Stream<List<RouteModel>> watchRoutes({bool includeInactive = false}) {
    return _firestore
        .collection('routes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _routeFromDocument(doc.id, doc.data()))
              .where(
                (route) =>
                    route.routeId.isNotEmpty &&
                    (includeInactive || route.isActive),
              )
              .toList(),
        );
  }

  Future<RouteModel?> fetchRoute(String routeId) async {
    final document = await _firestore.collection('routes').doc(routeId).get();
    if (!document.exists || document.data() == null) return null;
    return _routeFromDocument(document.id, document.data()!);
  }

  Stream<List<StopModel>> watchStops(String routeId) {
    return _firestore
        .collection('stops')
        .where('routeId', isEqualTo: routeId)
        .orderBy('stopOrder')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _stopFromDocument(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<TimetableModel>> watchTimetables(String routeId) {
    return _firestore
        .collection('timetables')
        .where('routeId', isEqualTo: routeId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _timetableFromDocument(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<bool> watchOfflineStatus() {
    return _firestore
        .collection('routes')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.metadata.isFromCache);
  }

  RouteModel _routeFromDocument(String documentId, Map<String, dynamic> data) {
    final typeValue = _stringValue(
      data['transportType'] ?? data['vehicleType'] ?? data['type'],
    );
    final type = typeValue?.toLowerCase() == 'van'
        ? TransportType.van
        : TransportType.bus;
    final stops = data['stops'];
    return RouteModel(
      routeId: _stringValue(data['routeId']) ?? documentId,
      routeName:
          _stringValue(data['routeName'] ?? data['name']) ?? 'Unnamed route',
      transportType: type,
      startLocation:
          _stringValue(data['startLocation'] ?? data['origin']) ?? '',
      destination:
          _stringValue(data['endLocation'] ?? data['destination']) ?? '',
      estimatedDuration: _stringValue(data['estimatedDuration']) ?? '',
      isDirect: _boolValue(data['isDirect']),
      isExpress: _boolValue(data['isExpress']),
      isPopular: _boolValue(data['isPopular']),
      isActive: _activeValue(data),
      totalStops:
          _intValue(data['totalStops']) ??
          (stops is Iterable ? stops.length : 0),
      departureTime: _stringValue(data['departureTime']),
      arrivalTime: _stringValue(data['arrivalTime']),
      fare: _doubleValue(data['fare']),
      stopIds: stops is Iterable
          ? stops.map((stop) => stop.toString()).toList()
          : const [],
    );
  }

  String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool _boolValue(Object? value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'no' || normalized == '0') {
        return false;
      }
    }
    return defaultValue;
  }

  int? _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool _activeValue(Map<String, dynamic> data) {
    final value = data.containsKey('isActive')
        ? data['isActive']
        : data.containsKey('active')
        ? data['active']
        : data['status'];
    if (value == null) return true;
    if (value is String && value.trim().toLowerCase() == 'active') {
      return true;
    }
    return _boolValue(value);
  }

  StopModel _stopFromDocument(String documentId, Map<String, dynamic> data) {
    return StopModel(
      stopId: data['stopId'] as String? ?? documentId,
      routeId: data['routeId'] as String?,
      stopName: data['stopName'] as String? ?? 'Unnamed stop',
      stopOrder: (data['stopOrder'] as num?)?.toInt() ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      address: data['address'] as String?,
    );
  }

  TimetableModel _timetableFromDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final days = data['operatingDays'];
    return TimetableModel(
      timetableId: data['timetableId'] as String? ?? documentId,
      routeId: data['routeId'] as String? ?? '',
      departureTime: data['departureTime'] as String? ?? '',
      arrivalTime: data['arrivalTime'] as String? ?? '',
      operatingDays: days is Iterable
          ? days.map((day) => day.toString()).toList()
          : const [],
      scheduleStatus: data['scheduleStatus'] as String?,
    );
  }
}
