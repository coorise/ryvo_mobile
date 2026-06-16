import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/index.dart';

Future<void> showCreateTaskSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback onCreated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _CreateTaskSheet(onCreated: onCreated),
  );
}

class _CreateTaskSheet extends ConsumerStatefulWidget {
  const _CreateTaskSheet({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _nameCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '02:00');
  String _scheduleMode = 'daily';
  DateTime? _runAt;
  bool _pausedOnCreate = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRunAt() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _runAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_runAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _runAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name is required.')),
      );
      return;
    }
    if (_scheduleMode == 'one_time' && _runAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a run date/time for one-time tasks.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'name': name,
        'kind': 'preset',
        'task_key': 'purge_abandoned_checkouts',
        'params': {'older_than_days': 90, 'limit': 2000},
        'schedule_mode': _scheduleMode,
        'run_at': _scheduleMode == 'one_time' ? _runAt!.toUtc().toIso8601String() : null,
        'time_of_day': _scheduleMode == 'daily' ? _timeCtrl.text.trim() : null,
      };
      final res = await tasksService.create(
        ref.read(authProvider).accessToken,
        body,
      );
      final task = res['task'];
      final id = task is Map ? task['id']?.toString() : null;
      if (_pausedOnCreate && id != null) {
        await tasksService.pause(ref.read(authProvider).accessToken, id);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New scheduled task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Task name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _scheduleMode,
              decoration: const InputDecoration(
                labelText: 'Schedule',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'one_time', child: Text('One time')),
              ],
              onChanged: (v) => setState(() => _scheduleMode = v ?? 'daily'),
            ),
            if (_scheduleMode == 'daily') ...[
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Time of day (HH:mm)',
                  border: OutlineInputBorder(),
                ),
                controller: _timeCtrl,
              ),
            ],
            if (_scheduleMode == 'one_time') ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickRunAt,
                icon: const Icon(Icons.event, size: 16),
                label: Text(
                  _runAt == null
                      ? 'Pick run date/time'
                      : _runAt!.toLocal().toString().substring(0, 16),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Create paused'),
              value: _pausedOnCreate,
              onChanged: (v) => setState(() => _pausedOnCreate = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create task'),
            ),
          ],
        ),
      ),
    );
  }
}
