import 'package:flutter/material.dart';

import '../services/favorites_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/route_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({this.showNavigation = true, super.key});

  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final content = ValueListenableBuilder(
      valueListenable: FavoritesService.favorites,
      builder: (context, favorites, _) {
        if (favorites.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No saved routes yet',
            message: 'Save a route from its details page to find it quickly here.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: favorites
              .map((route) => RouteCard(
                    route: route,
                    onFavorite: () => FavoritesService.remove(route.routeId),
                  ))
              .toList(),
        );
      },
    );
    if (!showNavigation) return content;
    return Scaffold(appBar: AppBar(title: const Text('Favorites')), body: content);
  }
}
