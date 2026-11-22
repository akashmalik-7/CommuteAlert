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
  String? selectedRouteId;
  String? selectedStopId;
  int threshold = 250;

  @override
  void initState() {
    super.initState();
    selectedRouteId = widget.existing?.routeId;
    selectedStopId = widget.existing?.stopId;
    threshold = widget.existing?.thresholdMeters ?? threshold;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Bus stop alert' : 'Edit stop alert',
      ),
    ),
    body: StreamBuilder<List<RouteModel>>(
      stream: firebase.watchRoutes(),
      builder: (context, routeSnapshot) {
        final routes = <RouteModel>[];
        final routeIds = <String>{};
        for (final item in routeSnapshot.data ?? const <RouteModel>[]) {
          if (item.routeId.isEmpty || !routeIds.add(item.routeId)) continue;
          routes.add(item);
        }
        if (routeSnapshot.hasError) {
          return const Center(
            child: Text('Routes unavailable. Check your connection.'),
          );
        }
        if (routeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (routes.isEmpty) {
          return const Center(child: Text('No active routes are available.'));
        }
        if (selectedRouteId == null &&
            widget.existing != null &&
            routes.any((item) => item.routeId == widget.existing!.routeId)) {
          selectedRouteId = widget.existing!.routeId;
        }
        route = routes
            .where((item) => item.routeId == selectedRouteId)
            .firstOrNull;
        if (route == null) {
          selectedRouteId = null;
          selectedStopId = null;
          stop = null;
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Alert me near a stop',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey<String>('bus-route-${selectedRouteId ?? 'none'}'),
              initialValue: selectedRouteId,
              decoration: const InputDecoration(labelText: 'Route'),
              items: routes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.routeId,
                      child: Text(item.routeName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRouteId = value;
                  route = routes
                      .where((item) => item.routeId == value)
                      .firstOrNull;
                  selectedStopId = null;
                  stop = null;
                });
              },
            ),
            if (route != null) ...[
              const SizedBox(height: 14),
              StreamBuilder<List<StopModel>>(
                stream: firebase.watchStops(route!.routeId),
                builder: (context, snapshot) {
                  final stops = <StopModel>[];
                  final stopIds = <String>{};
                  for (final item in snapshot.data ?? const <StopModel>[]) {
                    if (item.stopId.isEmpty || !stopIds.add(item.stopId)) {
                      continue;
                    }
                    stops.add(item);
                  }
                  if (selectedStopId == null &&
                      widget.existing != null &&
                      stops.any(
                        (item) => item.stopId == widget.existing!.stopId,
                      )) {
                    selectedStopId = widget.existing!.stopId;
                  }
                  stop = stops
                      .where((item) => item.stopId == selectedStopId)
                      .firstOrNull;
                  if (stop == null) selectedStopId = null;
                  return DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'bus-stop-${selectedStopId ?? 'none'}',
                    ),
                    initialValue: selectedStopId,
                    decoration: const InputDecoration(labelText: 'Bus stop'),
                    items: stops
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.stopId,
                            child: Text(item.stopName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStopId = value;
                        stop = stops
                            .where((item) => item.stopId == value)
                            .firstOrNull;
                      });
                    },
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
