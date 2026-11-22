import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../models/route_model.dart';
import '../services/alarm_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class TimerAlarmScreen extends StatefulWidget {
  const TimerAlarmScreen({this.existing, super.key});
  final AlarmModel? existing;
  @override
  State<TimerAlarmScreen> createState() => _TimerAlarmScreenState();
}

class _TimerAlarmScreenState extends State<TimerAlarmScreen> {
  final firebase = FirebaseService();
  RouteModel? route;
  String? selectedRouteId;
  TimeOfDay? time;
  final days = <int>{};
  final destination = TextEditingController();

  @override
  void initState() {
    super.initState();
    final alarm = widget.existing;
    if (alarm != null) {
      selectedRouteId = alarm.routeId;
      time = TimeOfDay(hour: alarm.hour!, minute: alarm.minute!);
      days.addAll(alarm.repeatDays);
      destination.text = alarm.destination;
    }
  }

  @override
  void dispose() {
    destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Journey alarm' : 'Edit journey alarm',
      ),
    ),
    body: StreamBuilder<List<RouteModel>>(
      stream: firebase.watchRoutes(),
      builder: (context, snapshot) {
        final routes = <RouteModel>[];
        final routeIds = <String>{};
        for (final item in snapshot.data ?? const <RouteModel>[]) {
          if (item.routeId.isEmpty || !routeIds.add(item.routeId)) continue;
          routes.add(item);
        }
        if (selectedRouteId == null &&
            widget.existing != null &&
            routes.any((item) => item.routeId == widget.existing!.routeId)) {
          selectedRouteId = widget.existing!.routeId;
        }
        final selectedRoute = routes
            .where((item) => item.routeId == selectedRouteId)
            .firstOrNull;
        if (selectedRoute == null) {
          selectedRouteId = null;
          route = null;
        } else {
          route = selectedRoute;
        }
        if (snapshot.hasError) {
          return _stateMessage(
            'Routes unavailable',
            'We could not load routes from Firestore. Check your connection and try again.',
            Icons.cloud_off,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (routes.isEmpty) {
          return _stateMessage(
            'No active routes',
            'Add an active route to Firestore before creating a journey alarm.',
            Icons.directions_bus_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Remind me before my journey',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'journey-route-${selectedRouteId ?? 'none'}',
              ),
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
                  destination.text = route?.destination ?? '';
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: destination,
              decoration: const InputDecoration(labelText: 'Destination'),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                time == null ? 'Select alarm time' : time!.format(context),
              ),
              leading: const Icon(Icons.schedule, color: AppTheme.primaryGreen),
              onTap: () async {
                final value = await showTimePicker(
                  context: context,
                  initialTime: time ?? TimeOfDay.now(),
                );
                if (value != null) setState(() => time = value);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Repeat on',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 6,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                  ),
                  selected: days.contains(day),
                  onSelected: (selected) => setState(
                    () => selected ? days.add(day) : days.remove(day),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save alarm'),
            ),
          ],
        );
      },
    ),
  );

  Widget _stateMessage(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (route == null || time == null || destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a route, time, and destination.')),
      );
      return;
    }

    try {
      await AlarmService.instance.save(
        AlarmModel(
          id:
              widget.existing?.id ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          type: AlarmType.timer,
          routeId: route!.routeId,
          routeName: route!.routeName,
          destination: destination.text.trim(),
          enabled: true,
          hour: time!.hour,
          minute: time!.minute,
          repeatDays: days.toList()..sort(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm saved successfully.')),
        );
        Navigator.pop(context);
      }
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
