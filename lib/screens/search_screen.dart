import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/route_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({this.showNavigation = true, super.key});

  final bool showNavigation;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _firebaseService = FirebaseService();
  int _transportIndex = 0;
  String _filter = 'All';
  bool _searched = false;

  void _search() {
    if (_fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both starting point and destination.'),
        ),
      );
      return;
    }
    setState(() => _searched = true);
  }

  void _clearSearch() {
    _fromController.clear();
    _toController.clear();
    setState(() => _searched = false);
  }

  List<RouteModel> _filterRoutes(List<RouteModel> routes) {
    final from = _fromController.text.trim().toLowerCase();
    final to = _toController.text.trim().toLowerCase();
    return routes.where((route) {
      final matchesType =
          _transportIndex == 0 ||
          (_transportIndex == 1 && route.transportType == TransportType.bus) ||
          (_transportIndex == 2 && route.transportType == TransportType.van);
      final matchesFrom =
          from.isEmpty || route.startLocation.toLowerCase().contains(from);
      final matchesTo =
          to.isEmpty || route.destination.toLowerCase().contains(to);
      final matchesFilter =
          _filter == 'All' ||
          (_filter == 'Direct' && route.isDirect) ||
          (_filter == 'Express' && route.isExpress) ||
          (_filter == 'Popular' && route.isPopular);
      return matchesType && matchesFrom && matchesTo && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<RouteModel>>(
      stream: _firebaseService.watchRoutes(),
      builder: (context, snapshot) {
        final results = snapshot.hasData && _searched
            ? _filterRoutes(snapshot.data!)
            : const <RouteModel>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Your Journey',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Search available local bus and van routes.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('All'),
                    icon: Icon(Icons.alt_route),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Bus'),
                    icon: Icon(Icons.directions_bus),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Van'),
                    icon: Icon(Icons.airport_shuttle),
                  ),
                ],
                selected: {_transportIndex},
                onSelectionChanged: (value) =>
                    setState(() => _transportIndex = value.first),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _fromController,
                        decoration: const InputDecoration(
                          hintText: 'Starting location',
                          prefixIcon: Icon(
                            Icons.my_location,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _toController,
                        decoration: const InputDecoration(
                          hintText: 'Destination',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.accent,
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Search Routes',
                        icon: Icons.search,
                        onPressed: _search,
                      ),
                      if (_searched)
                        TextButton.icon(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear search'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Quick Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ['All', 'Direct', 'Express', 'Popular']
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                EmptyState(
                  icon: Icons.cloud_off,
                  title: 'Unable to load routes',
                  message:
                      'Check your connection and Firestore configuration, then try again.',
                )
              else if (!_searched)
                const EmptyState(
                  icon: Icons.search_rounded,
                  title: 'Search routes',
                  message: 'Enter a starting point and destination to begin.',
                )
              else ...[
                Text(
                  'Search Results (${results.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (results.isEmpty)
                  const EmptyState(
                    title: 'No routes found',
                    message: 'Try different locations or filters.',
                  )
                else
                  ...results.map(
                    (route) => RouteCard(route: route, showFavorite: true),
                  ),
              ],
            ],
          ),
        );
      },
    );

    if (!widget.showNavigation) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Routes')),
      body: content,
    );
  }
}
