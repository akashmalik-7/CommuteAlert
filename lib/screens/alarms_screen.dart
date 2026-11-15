import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'location_alarm_screen.dart';
import 'timer_alarm_screen.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});
  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  final service = AlarmService.instance;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Alarms')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addAlarm,
      icon: const Icon(Icons.add_alarm),
      label: const Text('Add alarm'),
    ),
    body: service.alarms.isEmpty
        ? const Center(
            child: Text(
              'No alarms yet.\nCreate a journey or stop alert.',
              textAlign: TextAlign.center,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.alarms.length,
            itemBuilder: (_, index) => _card(service.alarms[index]),
          ),
  );

  Widget _card(AlarmModel alarm) {
    final time = alarm.hour == null
        ? 'Location alert'
        : TimeOfDay(hour: alarm.hour!, minute: alarm.minute!).format(context);
    final days = alarm.repeatDays.isEmpty
        ? 'Once'
        : alarm.repeatDays
              .map(
                (day) =>
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1],
              )
              .join(' ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDDF0E7),
          child: Icon(
            alarm.type == AlarmType.timer ? Icons.alarm : Icons.location_on,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          alarm.type == AlarmType.timer ? time : alarm.stopName ?? 'Bus stop',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${alarm.routeName} • ${alarm.type == AlarmType.timer ? days : '${alarm.thresholdMeters}m threshold'}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alarm.enabled,
              onChanged: (value) async {
                await service.setEnabled(alarm, value);
                if (mounted) setState(() {});
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  await service.delete(alarm.id);
                }
                if (value == 'edit') {
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => alarm.type == AlarmType.timer
                          ? TimerAlarmScreen(existing: alarm)
                          : LocationAlarmScreen(existing: alarm),
                    ),
                  );
                  if (mounted) setState(() {});
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () async {
          if (alarm.type == AlarmType.location && alarm.enabled) {
            final message = await LocationService.instance.start(alarm);
            if (message != null && mounted) _message(message);
          }
        },
      ),
    );
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<void> _addAlarm() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Journey timer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TimerAlarmScreen()),
                ).then((_) => setState(() {}));
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Bus stop alert'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LocationAlarmScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
          ],
        ),
      ),
    );
  }
}
