import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../screens/alarms_screen.dart';
import '../screens/add_route_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({this.onNavigate, super.key});

  final ValueChanged<int>? onNavigate;
  final AuthService _authService = AuthService();

  void _navigate(BuildContext context, int index) {
    if (onNavigate != null) {
      onNavigate!(index);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              color: AppTheme.primaryGreen,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CommuteAlert',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your Journey, Our Priority',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              onTap: () => _navigate(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Routes'),
              onTap: () => _navigate(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              onTap: () => _navigate(context, 2),
            ),
            StreamBuilder<User?>(
              stream: _authService.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.data == null) {
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign In'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  );
                }
                final user = authSnapshot.data!;
                return StreamBuilder<AdminRoleStatus>(
                  stream: _authService.adminRoleState(user),
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        leading: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Checking administrator access'),
                      );
                    }
                    final status = adminSnapshot.data;
                    if (adminSnapshot.hasError) {
                      return ListTile(
                        leading: const Icon(Icons.error_outline),
                        title: const Text('Administrator access unavailable'),
                        subtitle: Text(
                          adminSnapshot.error.toString(),
                          maxLines: 2,
                        ),
                        onTap: () => _navigate(context, 3),
                      );
                    }
                    if (status == null ||
                        !status.exists ||
                        status.role != 'admin') {
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Signed In'),
                        onTap: () => _navigate(context, 3),
                      );
                    }
                    return ListTile(
                      leading: const Icon(Icons.add_road_rounded),
                      title: const Text('Add Route'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddRouteScreen(),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_outlined),
              title: const Text('My Alarms'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlarmsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
