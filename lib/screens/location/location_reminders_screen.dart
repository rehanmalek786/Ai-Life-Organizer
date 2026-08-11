import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class LocationRemindersScreen extends StatefulWidget {
  const LocationRemindersScreen({super.key});
  @override
  State<LocationRemindersScreen> createState() => _LocationRemindersScreenState();
}

class _LocationRemindersScreenState extends State<LocationRemindersScreen> {
  final _fs = FirestoreService();

  void _openForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationForm(fs: _fs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Reminders')),
      floatingActionButton: FloatingActionButton(onPressed: _openForm, child: const Icon(Icons.add_location_alt_outlined)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These check while the app is open (foreground) and when you reopen it - not a background service.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LocationReminderItem>>(
              stream: _fs.locationRemindersStream(),
              builder: (context, snap) {
                if (!snap.hasData) return const LoadingView();
                final items = snap.data!;
                if (items.isEmpty) {
                  return const EmptyState(icon: Icons.location_on_outlined, title: 'No location reminders yet', subtitle: 'Tap + and use your current location to save a place.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final r = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(r.title),
                        subtitle: Text('Within ${r.radiusMeters.round()} m'),
                        trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _fs.deleteLocationReminder(r.id)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationForm extends StatefulWidget {
  final FirestoreService fs;
  const _LocationForm({required this.fs});
  @override
  State<_LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<_LocationForm> {
  final _titleCtrl = TextEditingController();
  final _loc = LocationService();
  double _radius = 200;
  double? _lat;
  double? _lng;
  bool _fetching = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _fetching = true);
    final pos = await _loc.currentPosition();
    setState(() => _fetching = false);
    if (pos == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get your location. Check that location permission and GPS are on.')),
        );
      }
      return;
    }
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty || _lat == null || _lng == null) return;
    widget.fs.addLocationReminder(LocationReminderItem(
      id: '',
      title: _titleCtrl.text.trim(),
      latitude: _lat!,
      longitude: _lng!,
      radiusMeters: _radius,
      createdAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New location reminder', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Remind me when I am near...'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _fetching ? null : _useCurrentLocation,
              icon: _fetching ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 18),
              label: Text(_lat == null ? 'Use my current location' : 'Location set (${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)})'),
            ),
            const SizedBox(height: 14),
            Text('Radius: ${_radius.round()} m'),
            Slider(value: _radius, min: 50, max: 1000, divisions: 19, onChanged: (v) => setState(() => _radius = v)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

