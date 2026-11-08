import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_model.dart';

class FavoritesService {
  static const _storageKey = 'favorite_routes';
  static final ValueNotifier<List<RouteModel>> favorites =
      ValueNotifier<List<RouteModel>>(<RouteModel>[]);
  static SharedPreferences? _preferences;

  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final stored = _preferences!.getStringList(_storageKey) ?? const [];
    favorites.value = stored
        .map((value) => _fromJson(jsonDecode(value) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> toggle(RouteModel route) async {
    if (isFavorite(route.routeId)) {
      await remove(route.routeId);
    } else {
      final updated = [...favorites.value, route];
      favorites.value = updated;
      await _save(updated);
    }
  }

  static Future<void> remove(String routeId) async {
    final updated = favorites.value
        .where((route) => route.routeId != routeId)
        .toList();
    favorites.value = updated;
    await _save(updated);
  }

  static bool isFavorite(String routeId) =>
      favorites.value.any((route) => route.routeId == routeId);

  static Future<void> _save(List<RouteModel> routes) async {
    final preferences = _preferences;
    if (preferences == null) return;
    await preferences.setStringList(
      _storageKey,
      routes.map((route) => jsonEncode(route.toFirestore())).toList(),
    );
  }

  static RouteModel _fromJson(Map<String, dynamic> data) {
    final type = (data['transportType'] as String?)?.toLowerCase() == 'van'
        ? TransportType.van
        : TransportType.bus;
    final stops = data['stops'];
    return RouteModel(
      routeId: data['routeId'] as String? ?? '',
      routeName: data['routeName'] as String? ?? 'Unnamed route',
      transportType: type,
      startLocation: data['startLocation'] as String? ?? '',
      destination:
          data['destination'] as String? ??
          data['endLocation'] as String? ??
          '',
      estimatedDuration: data['estimatedDuration'] as String? ?? '',
      isDirect: data['isDirect'] as bool? ?? false,
      isExpress: data['isExpress'] as bool? ?? false,
      isPopular: data['isPopular'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      totalStops:
          (data['totalStops'] as num?)?.toInt() ??
          (stops is List ? stops.length : 0),
      departureTime: data['departureTime'] as String?,
      arrivalTime: data['arrivalTime'] as String?,
      fare: (data['fare'] as num?)?.toDouble(),
      stopIds: stops is Iterable
          ? stops.map((stop) => stop.toString()).toList()
          : const [],
    );
  }
}
