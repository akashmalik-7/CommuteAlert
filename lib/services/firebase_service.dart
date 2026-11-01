import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RouteModel>> watchRoutes() {
    return _firestore.collection('routes').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => _routeFromDocument(doc.data()))
              .toList(),
        );
  }

  RouteModel _routeFromDocument(Map<String, dynamic> data) {
    final type = data['transportType'] == 'van'
        ? TransportType.van
        : TransportType.bus;
    return RouteModel(
      routeId: data['routeId'] as String? ?? '',
      routeName: data['routeName'] as String? ?? 'Unnamed route',
      transportType: type,
      startLocation: data['startLocation'] as String? ?? '',
      destination: data['destination'] as String? ?? '',
      estimatedDuration: data['estimatedDuration'] as String? ?? '',
      isDirect: data['isDirect'] as bool? ?? false,
      isExpress: data['isExpress'] as bool? ?? false,
      isPopular: data['isPopular'] as bool? ?? false,
      totalStops: data['totalStops'] as int? ?? 0,
    );
  }
}
