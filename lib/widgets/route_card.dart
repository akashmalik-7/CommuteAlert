import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../screens/route_details_screen.dart';

class RouteCard extends StatelessWidget {
  const RouteCard({
    required this.route,
    this.onFavorite,
    this.showFavorite = false,
    super.key,
  });

  final RouteModel route;
  final VoidCallback? onFavorite;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RouteDetailsScreen(route: route)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDDF0E7),
                child: Icon(
                  route.transportType == TransportType.bus
                      ? Icons.directions_bus_rounded
                      : Icons.airport_shuttle_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.routeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${route.startLocation} → ${route.destination}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${route.transportLabel} • ${route.estimatedDuration}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showFavorite)
                ValueListenableBuilder(
                  valueListenable: FavoritesService.favorites,
                  builder: (context, favorites, _) => IconButton(
                    onPressed:
                        onFavorite ?? () => FavoritesService.toggle(route),
                    icon: Icon(
                      favorites.any(
                            (savedRoute) => savedRoute.routeId == route.routeId,
                          )
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    color: AppTheme.accent,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
