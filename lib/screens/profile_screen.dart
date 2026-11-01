import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({this.showNavigation = true, super.key});

  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFDDF0E7),
                child: Icon(Icons.person, color: AppTheme.primaryGreen, size: 38),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Daily Commuter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Plan your journey with ease', style: TextStyle(color: Colors.grey.shade600)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _item(Icons.alt_route, 'My Routes'),
        _item(Icons.favorite_outline, 'Favorites'),
        _item(Icons.settings_outlined, 'Settings'),
        _item(Icons.help_outline, 'Help & Support'),
        _item(Icons.logout, 'Log Out', onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication will be available in a future module.')),
        )),
      ],
    );
    if (!showNavigation) return content;
    return Scaffold(appBar: AppBar(title: const Text('Profile')), body: content);
  }

  Widget _item(IconData icon, String title, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
