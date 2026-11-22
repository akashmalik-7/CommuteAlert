import 'package:commutealert_app/models/alarm_model.dart';
import 'package:commutealert_app/models/route_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Route model', () {
    test('serializes required Firestore fields with correct types', () {
      const route = RouteModel(
        routeId: 'route_test',
        routeName: 'Test Route',
        transportType: TransportType.bus,
        startLocation: 'Start',
        destination: 'Destination',
        estimatedDuration: '20 min',
        isDirect: true,
        isExpress: false,
        isPopular: false,
        isActive: true,
        departureTime: '08:00',
        arrivalTime: '08:20',
        fare: 25,
      );

      final data = route.toFirestore();

      expect(data['routeId'], 'route_test');
      expect(data['estimatedDuration'], '20 min');
      expect(data['fare'], isA<num>());
      expect(data['isActive'], isA<bool>());
    });
  });

  group('Alarm model', () {
    test('falls back safely for a malformed local alarm entry', () {
      final alarm = AlarmModel.fromJson({
        'id': null,
        'type': 'unsupported',
        'routeId': null,
        'routeName': null,
        'destination': null,
        'enabled': null,
      });

      expect(alarm.id, '');
      expect(alarm.type, AlarmType.timer);
      expect(alarm.routeId, '');
      expect(alarm.routeName, 'Unknown route');
      expect(alarm.enabled, true);
    });
  });
}
