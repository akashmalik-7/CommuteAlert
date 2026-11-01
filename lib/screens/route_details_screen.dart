import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({required this.route, super.key});

  final RouteModel route;

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final stopCount = route.totalStops < 1
        ? 1
        : (route.totalStops > 6 ? 6 : route.totalStops);
    final saved = FavoritesService.isFavorite(route.routeId);
    return Scaffold(
      appBar: AppBar(
        title: Text(route.routeName),
        actions: [
          IconButton(
            onPressed: () {
              FavoritesService.toggle(route);
              setState(() {});
            },
            icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 27,
                        backgroundColor: const Color(0xFFDDF0E7),
                        child: Icon(
                          route.transportType == TransportType.bus
                              ? Icons.directions_bus_rounded
                              : Icons.airport_shuttle_rounded,
                          color: AppTheme.primaryGreen,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.transportLabel,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            route.estimatedDuration,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    route.startLocation,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Icon(Icons.more_vert, color: AppTheme.primaryGreen),
                  ),
                  Text(
                    route.destination,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${route.totalStops} stops • ${route.isDirect ? 'Direct route' : 'Connecting route'}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Timetable'),
              Tab(text: 'Stops'),
            ],
          ),
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.separated(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(
                      Icons.access_time_rounded,
                      color: AppTheme.primaryGreen,
                    ),
                    title: Text(
                      ['6:30 AM', '8:30 AM', '10:30 AM', '4:30 PM'][index],
                    ),
                    subtitle: const Text('Demonstration timetable'),
                    trailing: Text(index.isEven ? '7:05 AM' : '9:05 AM'),
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: stopCount,
                  itemBuilder: (_, index) => ListTile(
                    leading: CircleAvatar(
                      radius: 13,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      index == 0
                          ? route.startLocation
                          : index == stopCount - 1
                          ? route.destination
                          : 'Stop ${index + 1}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: saved ? 'Saved to Favorites' : 'Save to Favorites',
            icon: saved ? Icons.favorite : Icons.favorite_border,
            onPressed: () {
              FavoritesService.toggle(route);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Times shown are demonstration data for Module 1.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
