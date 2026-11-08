import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/timetable_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RouteModel>> watchRoutes() {
    return _firestore
        .collection('routes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _routeFromDocument(doc.id, doc.data()))
              .where((route) => route.routeId.isNotEmpty && route.isActive)
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
    final type = (data['transportType'] as String?)?.toLowerCase() == 'van'
        ? TransportType.van
        : TransportType.bus;
    final stops = data['stops'];
    return RouteModel(
      routeId: data['routeId'] as String? ?? documentId,
      routeName: data['routeName'] as String? ?? 'Unnamed route',
      transportType: type,
      startLocation: data['startLocation'] as String? ?? '',
      destination:
          data['endLocation'] as String? ??
          data['destination'] as String? ??
          '',
      estimatedDuration: data['estimatedDuration'] as String? ?? '',
      isDirect: data['isDirect'] as bool? ?? false,
      isExpress: data['isExpress'] as bool? ?? false,
      isPopular: data['isPopular'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      totalStops:
          data['totalStops'] as int? ?? (stops is List ? stops.length : 0),
      departureTime: data['departureTime'] as String?,
      arrivalTime: data['arrivalTime'] as String?,
      fare: (data['fare'] as num?)?.toDouble(),
      stopIds: stops is Iterable
          ? stops.map((stop) => stop.toString()).toList()
          : const [],
    );
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
