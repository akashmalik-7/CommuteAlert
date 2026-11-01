import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/route_card.dart';
import '../widgets/search_field.dart';
import '../widgets/section_heading.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget get _body {
    switch (_currentIndex) {
      case 1:
        return const SearchScreen(showNavigation: false);
      case 2:
        return const FavoritesScreen(showNavigation: false);
      case 3:
        return const ProfileScreen(showNavigation: false);
      default:
        return _homeContent;
    }
  }

  Widget get _homeContent => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hello, Commuter! 👋',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Where would you like to go today?',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(height: 22),
        SearchField(
          hintText: 'Search bus or van routes',
          readOnly: true,
          onTap: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 26),
        const SectionHeading(title: 'Quick Actions'),
        const SizedBox(height: 10),
        Row(
          children: [
            _quickAction('Bus Routes', Icons.directions_bus_rounded, 1),
            const SizedBox(width: 12),
            _quickAction('Van Routes', Icons.airport_shuttle_rounded, 1),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _quickAction('Favorites', Icons.favorite_rounded, 2),
            const SizedBox(width: 12),
            _quickAction('Alarms', Icons.alarm_rounded, null),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeading(
          title: 'Popular Routes',
          action: () => setState(() => _currentIndex = 1),
        ),
        const SizedBox(height: 4),
        ...demoRoutes.map((route) => RouteCard(route: route)),
      ],
    ),
  );

  Widget _quickAction(String title, IconData icon, int? destination) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: destination == null
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Alarm reminders will be available in a future module.',
                  ),
                ),
              )
            : () => setState(() => _currentIndex = destination),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 30),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _currentIndex == 0;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          isHome
              ? 'CommuteAlert'
              : [
                  'Home',
                  'Search Routes',
                  'Favorites',
                  'Profile',
                ][_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onNavigate: (index) {
          Navigator.pop(context);
          setState(() => _currentIndex = index);
        },
      ),
      body: _body,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
