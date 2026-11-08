import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/timetable_model.dart';
import '../services/favorites_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({required this.route, super.key});

  final RouteModel route;

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _firebaseService = FirebaseService();

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

  Future<void> _toggleFavorite(RouteModel route) async {
    await FavoritesService.toggle(route);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.route.routeName),
        actions: [
          ValueListenableBuilder(
            valueListenable: FavoritesService.favorites,
            builder: (context, favorites, _) {
              final saved = favorites.any(
                (route) => route.routeId == widget.route.routeId,
              );
              return IconButton(
                onPressed: () => _toggleFavorite(widget.route),
                icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<RouteModel?>(
        future: _firebaseService.fetchRoute(widget.route.routeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _message(
              'Unable to load route details',
              'Check your connection and try again.',
              Icons.cloud_off,
            );
          }
          final route = snapshot.data;
          if (route == null) {
            return _message(
              'Route not found',
              'This route may have been removed from Firestore.',
              Icons.route_outlined,
            );
          }
          return _routeContent(route);
        },
      ),
    );
  }

  Widget _routeContent(RouteModel route) {
    return ListView(
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
                        if (route.estimatedDuration.isNotEmpty)
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
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (route.departureTime != null)
                      Text('Departs ${route.departureTime}'),
                    if (route.arrivalTime != null)
                      Text('Arrives ${route.arrivalTime}'),
                    if (route.fare != null)
                      Text('Fare ${route.fare!.toStringAsFixed(0)}'),
                  ],
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
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [_timetable(route.routeId), _stops(route.routeId)],
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: FavoritesService.favorites,
          builder: (context, favorites, _) {
            final saved = favorites.any(
              (item) => item.routeId == route.routeId,
            );
            return ElevatedButton.icon(
              onPressed: () => _toggleFavorite(route),
              icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
              label: Text(saved ? 'Saved to Favorites' : 'Save to Favorites'),
            );
          },
        ),
      ],
    );
  }

  Widget _timetable(String routeId) {
    return StreamBuilder<List<TimetableModel>>(
      stream: _firebaseService.watchTimetables(routeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _message(
            'Timetable unavailable',
            'Try again later.',
            Icons.error_outline,
          );
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No timetable has been published yet.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 12),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final timetable = snapshot.data![index];
            return ListTile(
              leading: const Icon(
                Icons.access_time_rounded,
                color: AppTheme.primaryGreen,
              ),
              title: Text(
                '${timetable.departureTime} - ${timetable.arrivalTime}',
              ),
              subtitle: Text(
                timetable.operatingDays.isEmpty
                    ? 'Operating days not specified'
                    : timetable.operatingDays.join(', '),
              ),
              trailing: timetable.scheduleStatus == null
                  ? null
                  : Text(timetable.scheduleStatus!),
            );
          },
        );
      },
    );
  }

  Widget _stops(String routeId) {
    return StreamBuilder<List<StopModel>>(
      stream: _firebaseService.watchStops(routeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _message(
            'Stops unavailable',
            'Try again later.',
            Icons.error_outline,
          );
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No stops have been published yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 12),
          itemCount: snapshot.data!.length,
          itemBuilder: (_, index) {
            final stop = snapshot.data![index];
            return ListTile(
              leading: CircleAvatar(radius: 13, child: Text('${index + 1}')),
              title: Text(stop.stopName),
              subtitle: stop.address == null ? null : Text(stop.address!),
            );
          },
        );
      },
    );
  }

  Widget _message(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
