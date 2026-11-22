import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/route_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();
  final _durationController = TextEditingController();
  final _fareController = TextEditingController();

  TransportType _transportType = TransportType.bus;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
  bool _isDirect = false;
  bool _isExpress = false;
  bool _isPopular = false;
  bool _isActive = true;
  bool _isSaving = false;
  bool _saveSucceeded = false;
  String? _errorMessage;
  bool _isCheckingAuthorization = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Add Route screen: authenticated UID=${user?.uid ?? 'null'}');
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isCheckingAuthorization = false;
        _isAuthorized = false;
      });
      return;
    }
    try {
      final authorized = await FirebaseService().isCurrentUserAdmin();
      if (!mounted) return;
      setState(() {
        _isCheckingAuthorization = false;
        _isAuthorized = authorized;
      });
    } on FirebaseException catch (error) {
      debugPrint(
        'Add Route authorization FirebaseException '
        '[${error.code}]: ${error.message ?? 'No additional message'}',
      );
      if (!mounted) return;
      setState(() {
        _isCheckingAuthorization = false;
        _isAuthorized = false;
        _errorMessage =
            '${error.code}: ${error.message ?? 'Unable to verify administrator access.'}';
      });
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _startController.dispose();
    _destinationController.dispose();
    _durationController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _pickTime(bool isDeparture) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isDeparture ? _departureTime : _arrivalTime) ??
          const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparture) {
        _departureTime = picked;
      } else {
        _arrivalTime = picked;
      }
      _errorMessage = null;
    });
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departureTime == null || _arrivalTime == null) {
      setState(
        () => _errorMessage = 'Please select both departure and arrival times.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _saveSucceeded = false;
      _errorMessage = null;
    });

    final routeName = _routeNameController.text.trim();
    final routeId = _slug(routeName);
    if (routeId.isEmpty) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Route name must contain letters or numbers.';
      });
      return;
    }

    final fare = double.tryParse(_fareController.text.trim());
    if (fare == null || fare <= 0) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Please enter a valid fare greater than zero.';
      });
      return;
    }

    final route = RouteModel(
      routeId: routeId,
      routeName: routeName,
      transportType: _transportType,
      startLocation: _startController.text.trim(),
      destination: _destinationController.text.trim(),
      estimatedDuration: _durationController.text.trim(),
      isDirect: _isDirect,
      isExpress: _isExpress,
      isPopular: _isPopular,
      isActive: _isActive,
      totalStops: 0,
      departureTime: _formatTime(_departureTime!),
      arrivalTime: _formatTime(_arrivalTime!),
      fare: fare,
      stopIds: const [],
    );

    try {
      await FirebaseService().addRoute(route);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveSucceeded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route saved successfully.'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) Navigator.of(context).pop();
    } on FirebaseException catch (error) {
      debugPrint(
        'Save Route callback FirebaseException '
        '[${error.code}]: ${error.message ?? 'No additional message'}',
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveSucceeded = false;
        _errorMessage = _friendlyFirebaseError(error);
      });
    } catch (error) {
      debugPrint('Save Route callback unexpected error: $error');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveSucceeded = false;
        _errorMessage = 'Unable to save the route. Please try again.';
      });
    }
  }

  String _friendlyFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'permission-denied: ${error.message ?? 'Administrator authorization was denied.'}';
      case 'not-found':
        return 'Firestore database or document was not found.';
      case 'invalid-argument':
        return error.message ??
            'The route contains invalid data. Review all required fields.';
      case 'already-exists':
        return 'A route with this name already exists.';
      case 'unavailable':
        return 'Firestore is temporarily unavailable. Check your connection.';
      default:
        return error.message ?? 'A Firestore error occurred while saving.';
    }
  }

  Widget _timeField({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.schedule_rounded,
            color: AppTheme.primaryGreen,
          ),
        ),
        child: Text(
          time == null ? 'Select time' : _formatTime(time),
          style: TextStyle(
            color: time == null ? Colors.grey.shade600 : AppTheme.textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuthorization) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Route')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Route')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Administrator access required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  FirebaseAuth.instance.currentUser == null
                      ? 'Sign in with an authorized administrator account.'
                      : 'Your account does not have administrator privileges.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add Route')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Route details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Publish a route visible on Home and Search.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _routeNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Route name',
                  hintText: 'e.g. Campus - Central Market',
                  prefixIcon: Icon(Icons.route, color: AppTheme.primaryGreen),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Route name is required'
                    : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Transport type',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TransportType>(
                segments: const [
                  ButtonSegment(
                    value: TransportType.bus,
                    label: Text('Bus'),
                    icon: Icon(Icons.directions_bus),
                  ),
                  ButtonSegment(
                    value: TransportType.van,
                    label: Text('Van'),
                    icon: Icon(Icons.airport_shuttle),
                  ),
                ],
                selected: {_transportType},
                onSelectionChanged: (value) =>
                    setState(() => _transportType = value.first),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _startController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Starting location',
                  prefixIcon: Icon(
                    Icons.my_location,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Starting location is required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.accent,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Destination is required'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timeField(
                      label: 'Departure',
                      time: _departureTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(
                      label: 'Arrival',
                      time: _arrivalTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fareController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fare',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      validator: (value) {
                        final fare = double.tryParse(value?.trim() ?? '');
                        if (fare == null || fare <= 0) {
                          return 'Enter a valid fare';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        hintText: '25 min',
                        prefixIcon: Icon(
                          Icons.timer_outlined,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Duration is required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Direct route'),
                      value: _isDirect,
                      onChanged: (value) => setState(() => _isDirect = value),
                    ),
                    SwitchListTile(
                      title: const Text('Express route'),
                      value: _isExpress,
                      onChanged: (value) => setState(() => _isExpress = value),
                    ),
                    SwitchListTile(
                      title: const Text('Popular route'),
                      value: _isPopular,
                      onChanged: (value) => setState(() => _isPopular = value),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Make this route searchable'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveRoute,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _saveSucceeded
                              ? Icons.check_circle_outline
                              : Icons.save_outlined,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _saveSucceeded
                        ? 'Saved'
                        : 'Save Route',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
