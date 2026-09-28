import 'package:flutter/material.dart';

import '../models/feeding_schedule.dart';
import '../services/firebase_service.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({required this.firebaseService, super.key});

  final FirebaseService firebaseService;

  Future<void> _showAddSchedule(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddScheduleSheet(firebaseService: firebaseService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feeding schedules')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSchedule(context),
        icon: const Icon(Icons.add),
        label: const Text('Add schedule'),
      ),
      body: StreamBuilder<List<FeedingSchedule>>(
        stream: firebaseService.schedulesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final schedules = snapshot.data ?? [];
          if (schedules.isEmpty) {
            return const Center(
              child: Text('No schedules yet. Add your first feeding time.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ScheduleTile(
              schedule: schedules[index],
              onDelete: () =>
                  firebaseService.deleteSchedule(schedules[index].id),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule, required this.onDelete});

  final FeedingSchedule schedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time =
        '${schedule.hour.toString().padLeft(2, '0')}:${schedule.minute.toString().padLeft(2, '0')}';
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.schedule)),
        title: Text(time, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${schedule.portion} portion${schedule.portion == 1 ? '' : 's'}',
        ),
        trailing: IconButton(
          onPressed: onDelete,
          tooltip: 'Delete schedule',
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _AddScheduleSheet extends StatefulWidget {
  const _AddScheduleSheet({required this.firebaseService});

  final FirebaseService firebaseService;

  @override
  State<_AddScheduleSheet> createState() => _AddScheduleSheetState();
}

class _AddScheduleSheetState extends State<_AddScheduleSheet> {
  TimeOfDay _time = TimeOfDay.now();
  int _portion = 1;
  bool _saving = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.firebaseService.saveSchedule(
        hour: _time.hour,
        minute: _time.minute,
        portion: _portion,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the schedule.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add schedule',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time),
            label: Text('Feed at ${_time.format(context)}'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _portion,
            decoration: const InputDecoration(
              labelText: 'Portion size',
              border: OutlineInputBorder(),
            ),
            items: [1, 2, 3, 4]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value portion${value == 1 ? '' : 's'}'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _portion = value);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save schedule'),
          ),
        ],
      ),
    );
  }
}
