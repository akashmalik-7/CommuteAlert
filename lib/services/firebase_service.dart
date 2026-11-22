import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/timetable_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Admin check: no authenticated user');
      return false;
    }
    debugPrint('Admin check: authenticated UID=${user.uid}');
    final roleDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    debugPrint(
      'Admin check: documentID=${roleDocument.id}, '
      'exists=${roleDocument.exists}, '
      'data=${roleDocument.data()}',
    );
    if (!roleDocument.exists) return false;
    final role = roleDocument.data()?['role'];
    debugPrint('Admin check: role=$role');
    return role == 'admin';
  }

  Future<void> updateRoute(RouteModel route) async {
    await requireAdmin();
    final routeId = _normalizeRouteId(route.routeId);
    if (routeId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A route ID is required.',
      );
    }
    final data = route.toFirestore();
    data['routeId'] = routeId;
    await _firestore.collection('routes').doc(routeId).update(data);
  }

  Future<void> deleteRoute(String routeId) async {
    await requireAdmin();
    final normalizedId = _normalizeRouteId(routeId);
    if (normalizedId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A route ID is required.',
      );
    }
    await _firestore.collection('routes').doc(normalizedId).delete();
  }

  Future<void> requireAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Add route authorization: currentUser=${user?.uid ?? 'null'}');
    if (!await isCurrentUserAdmin()) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Administrator authorization is required.',
      );
    }
  }

  Future<void> addRoute(RouteModel route) async {
    await requireAdmin();
    final routeId = _normalizeRouteId(route.routeId);
    if (routeId.isEmpty) {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'A route ID is required.',
      );
      _logFirestoreException('addRoute', error);
      throw error;
    }

    final routeName = route.routeName.trim();
    final startLocation = route.startLocation.trim();
    final destination = route.destination.trim();
    final estimatedDuration = route.estimatedDuration.trim();
    final departureTime = route.departureTime?.trim();
    final arrivalTime = route.arrivalTime?.trim();

    if (routeName.isEmpty ||
        startLocation.isEmpty ||
        destination.isEmpty ||
        departureTime == null ||
        departureTime.isEmpty ||
        arrivalTime == null ||
        arrivalTime.isEmpty ||
        estimatedDuration.isEmpty ||
        route.fare == null ||
        route.fare! <= 0) {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message:
            'Route name, locations, times, duration, and a positive fare are required.',
      );
      _logFirestoreException('addRoute', error);
      throw error;
    }

    try {
      final documentReference = _firestore.collection('routes').doc(routeId);
      debugPrint(
        'Add route: documentID=${documentReference.id}, '
        'routeIdField=$routeId',
      );
      final existingDocument = await documentReference.get();
      if (existingDocument.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A route with this ID already exists.',
        );
      }

      final matchingRoutes = await _firestore
          .collection('routes')
          .where('routeId', isEqualTo: routeId)
          .limit(1)
          .get();
      if (matchingRoutes.docs.isNotEmpty) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A route with this ID already exists.',
        );
      }

      final data = <String, dynamic>{
        'routeId': documentReference.id,
        'routeName': routeName,
        'transportType': route.transportLabel.toLowerCase(),
        'startLocation': startLocation,
        'destination': destination,
        'estimatedDuration': estimatedDuration,
        'totalStops': route.totalStops,
        'isDirect': route.isDirect,
        'isExpress': route.isExpress,
        'isPopular': route.isPopular,
        'isActive': route.isActive,
        'fare': route.fare,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'stops': route.stopIds,
        'isDemo': false,
        'demoSource': null,
      };
      debugPrint('Add route payload=$data');

      await _firestore.runTransaction((transaction) async {
        final latestDocument = await transaction.get(documentReference);
        if (latestDocument.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
            message: 'A route with this ID already exists.',
          );
        }
        transaction.set(documentReference, data);
      });

      final written = await documentReference.get();
      if (!written.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'write-failed',
          message:
              'The route transaction completed but the document was not found.',
        );
      }
      final writtenData = written.data();
      if (writtenData?['routeId'] != documentReference.id) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-data',
          message:
              'The written routeId does not match document ID ${documentReference.id}.',
        );
      }
      debugPrint(
        'Add route successful: documentID=${written.id}, '
        'routeId=${writtenData?['routeId']}',
      );
    } on FirebaseException catch (error) {
      _logFirestoreException('addRoute', error);
      rethrow;
    }
  }

  String _normalizeRouteId(String routeId) {
    final normalized = routeId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? '' : 'route_$normalized';
  }

  void _logFirestoreException(String operation, FirebaseException error) {
    debugPrint(
      'Firestore $operation failed [${error.code}]: '
      '${error.message ?? 'No additional Firestore message'}',
    );
  }

  Future<bool> seedSampleDataIfEmpty() async {
    final existing = await _firestore.collection('routes').limit(1).get();
    if (existing.docs.isNotEmpty) return false;

    final batch = _firestore.batch();
    final route = _firestore.collection('routes').doc('route_campus_central');
    batch.set(route, {
      'isDemo': true,
      'demoSource': 'seedSampleDataIfEmpty',
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
      'isDemo': true,
      'demoSource': 'seedSampleDataIfEmpty',
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
        'isDemo': true,
        'demoSource': 'ensurePopularRoutes',
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
        'isDemo': true,
        'demoSource': 'ensurePopularRoutes',
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
        'isDemo': true,
        'demoSource': 'ensurePopularRoutes',
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

  Stream<List<RouteModel>> watchRoutes() {
    // Rules only allow active-route reads for normal users. This constrained
    // query is required for collection listeners; an unconstrained routes
    // listener can be denied before inactive documents are filtered in Dart.
    final Query<Map<String, dynamic>> routesQuery = _firestore
        .collection('routes')
        .where('isActive', isEqualTo: true);
    return routesQuery.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => _routeFromDocument(doc.id, doc.data()))
          .where((route) => route.routeId.isNotEmpty)
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
        .where('isActive', isEqualTo: true)
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
