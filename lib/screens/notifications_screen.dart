import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFFDDF0E7),
              child: Icon(Icons.alarm, color: AppTheme.primaryGreen),
            ),
            title: Text('Your alarms appear here'),
            subtitle: Text(
              'Create a journey reminder or bus stop alert to receive notifications.',
            ),
          ),
        ),
      ],
    ),
  );
}
