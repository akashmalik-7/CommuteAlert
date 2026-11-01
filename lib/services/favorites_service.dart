import 'package:flutter/foundation.dart';

import '../models/route_model.dart';

class FavoritesService {
  static final ValueNotifier<List<RouteModel>> favorites =
      ValueNotifier<List<RouteModel>>(<RouteModel>[]);

  static void toggle(RouteModel route) {
    if (isFavorite(route.routeId)) {
      remove(route.routeId);
    } else {
      favorites.value = [...favorites.value, route];
    }
  }

  static void remove(String routeId) {
    favorites.value =
        favorites.value.where((route) => route.routeId != routeId).toList();
  }

  static bool isFavorite(String routeId) =>
      favorites.value.any((route) => route.routeId == routeId);
}
