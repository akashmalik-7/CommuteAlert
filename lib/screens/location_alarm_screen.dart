import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../services/alarm_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

class LocationAlarmScreen extends StatefulWidget {
  const LocationAlarmScreen({this.existing, super.key});
  final AlarmModel? existing;
  @override
  State<LocationAlarmScreen> createState() => _LocationAlarmScreenState();
}

class _LocationAlarmScreenState extends State<LocationAlarmScreen> {
  final firebase = FirebaseService();
  RouteModel? route;
  StopModel? stop;
  int threshold = 250;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Bus stop alert' : 'Edit stop alert',
      ),
    ),
    body: StreamBuilder<List<RouteModel>>(
      stream: firebase.watchRoutes(includeInactive: true),
      builder: (context, routeSnapshot) {
        final routes = routeSnapshot.data ?? [];
        route ??= routes
            .where((item) => item.routeId == widget.existing?.routeId)
            .firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Alert me near a stop',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<RouteModel>(
              initialValue: route,
              decoration: const InputDecoration(labelText: 'Route'),
              items: routes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.routeName),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                route = value;
                stop = null;
              }),
            ),
            if (route != null) ...[
              const SizedBox(height: 14),
              StreamBuilder<List<StopModel>>(
                stream: firebase.watchStops(route!.routeId),
                builder: (context, snapshot) {
                  final stops = snapshot.data ?? [];
                  stop ??= stops
                      .where((item) => item.stopId == widget.existing?.stopId)
                      .firstOrNull;
                  return DropdownButtonFormField<StopModel>(
                    initialValue: stop,
                    decoration: const InputDecoration(labelText: 'Bus stop'),
                    items: stops
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.stopName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => stop = value),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'Alert distance',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [100, 250, 500, 1000]
                  .map(
                    (value) =>
                        ButtonSegment(value: value, label: Text('${value}m')),
                  )
                  .toList(),
              selected: {threshold},
              onSelectionChanged: (value) =>
                  setState(() => threshold = value.first),
            ),
            const SizedBox(height: 16),
            const Text(
              'Location monitoring runs while the app is active. Android may pause background updates to save battery.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save alert'),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _save() async {
    if (route == null || stop == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a route and stop.')));
      return;
    }
    if (stop!.latitude == null || stop!.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This stop has no coordinates in Firestore.'),
        ),
      );
      return;
    }
    final alarm = AlarmModel(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: AlarmType.location,
      routeId: route!.routeId,
      routeName: route!.routeName,
      destination: route!.destination,
      enabled: true,
      stopId: stop!.stopId,
      stopName: stop!.stopName,
      latitude: stop!.latitude,
      longitude: stop!.longitude,
      thresholdMeters: threshold,
    );
    try {
      await AlarmService.instance.save(alarm);
      final error = await LocationService.instance.start(alarm);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop alert saved and monitoring started.'),
        ),
      );
      Navigator.pop(context);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
