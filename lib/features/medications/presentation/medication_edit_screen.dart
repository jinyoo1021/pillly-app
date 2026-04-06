import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/primary_text_field.dart';
import '../domain/medication.dart';
import '../providers/medication_provider.dart';

class MedicationEditScreen extends ConsumerStatefulWidget {
  const MedicationEditScreen({super.key, required this.medication});
  final Medication medication;

  @override
  ConsumerState<MedicationEditScreen> createState() =>
      _MedicationEditScreenState();
}

class _MedicationEditScreenState
    extends ConsumerState<MedicationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _memoController;

  late CycleType _cycleType;
  late String _unit;
  late int _intervalDays;
  late List<int> _weekdays;
  late List<TimeOfDay> _times;

  static const List<String> _units = ['capsule', 'mg', 'ml', 'tablet', 'drop'];

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    _nameController = TextEditingController(text: m.name);
    _dosageController =
        TextEditingController(text: m.dosage?.toString() ?? '');
    _memoController = TextEditingController(text: m.memo ?? '');
    _cycleType = m.cycleType;
    _unit = m.unit ?? 'mg';
    _intervalDays = m.intervalDays ?? 2;
    _weekdays = List<int>.from(m.weekdays ?? []);
    _times = m.scheduledTimes.map((t) {
      final parts = t.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cycleType == CycleType.weekly && _weekdays.isEmpty) {
      _showError('Please select at least one day of the week.');
      return;
    }
    if (_times.isEmpty) {
      _showError('Please add at least one reminder time.');
      return;
    }

    final request = MedicationUpdateRequest(
      name: _nameController.text.trim(),
      cycleType: _cycleType,
      scheduledTimes: _times.map(_formatTime).toList(),
      dosage: double.tryParse(_dosageController.text),
      unit: _unit,
      intervalDays:
      _cycleType == CycleType.interval ? _intervalDays : null,
      weekdays:
      _cycleType == CycleType.weekly ? List<int>.from(_weekdays) : null,
      memo: _memoController.text.trim(),
    );

    final success = await ref
        .read(medicationUpdateProvider.notifier)
        .save(id: widget.medication.id, request: request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Medication updated successfully!'),
          backgroundColor: AppColors.done,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.pop();
    } else {
      _showError('Failed to update. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.missed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(medicationUpdateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit medication'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _onSave,
            child: isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
                : const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Name
            PrimaryTextField(
              label: 'Medication name',
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the medication name.';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Dosage + Unit
            _SectionLabel(label: 'Dosage'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dosageController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                    const InputDecoration(hintText: 'Amount'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(),
                    items: _units
                        .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _unit = value);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Cycle type
            _SectionLabel(label: 'Schedule'),
            const SizedBox(height: 8),
            _CycleTypeSelector(
              selected: _cycleType,
              onChanged: (type) => setState(() => _cycleType = type),
            ),

            const SizedBox(height: 16),

            if (_cycleType == CycleType.weekly) ...[
              _SectionLabel(label: 'Days of the week'),
              const SizedBox(height: 8),
              _WeekdaySelector(
                selected: _weekdays,
                onChanged: (days) => setState(() {
                  _weekdays
                    ..clear()
                    ..addAll(days);
                }),
              ),
              const SizedBox(height: 16),
            ],

            if (_cycleType == CycleType.interval) ...[
              _SectionLabel(label: 'Every N days'),
              const SizedBox(height: 8),
              _IntervalSelector(
                value: _intervalDays,
                onChanged: (v) => setState(() => _intervalDays = v),
              ),
              const SizedBox(height: 16),
            ],

            // Reminder times
            _SectionLabel(label: 'Reminder times'),
            const SizedBox(height: 8),
            ..._times.asMap().entries.map((entry) {
              final index = entry.key;
              final time = entry.value;
              return _TimeRow(
                time: time,
                canDelete: _times.length > 1,
                onTap: () => _pickTime(index),
                onDelete: () =>
                    setState(() => _times.removeAt(index)),
              );
            }),

            TextButton.icon(
              onPressed: _times.length < 6
                  ? () => setState(() => _times
                  .add(const TimeOfDay(hour: 12, minute: 0)))
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 18),
              label: const Text('Add time'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
            ),

            const SizedBox(height: 24),

            // Memo
            PrimaryTextField(
              label: 'Notes (optional)',
              hint: 'e.g. Take after meals',
              controller: _memoController,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Supporting widgets (shared with add screen)

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _CycleTypeSelector extends StatelessWidget {
  const _CycleTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final CycleType selected;
  final void Function(CycleType) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CycleType.values.map((type) {
        final label = switch (type) {
          CycleType.daily => 'Every day',
          CycleType.weekly => 'Weekly',
          CycleType.interval => 'Interval',
        };
        final isSelected = selected == type;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.grey200,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selected,
    required this.onChanged,
  });

  final List<int> selected;
  final void Function(List<int>) onChanged;

  static const List<String> _labels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final day = index + 1;
        final isSelected = selected.contains(day);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              final updated = List<int>.from(selected);
              if (isSelected) {
                updated.remove(day);
              } else {
                updated.add(day);
              }
              onChanged(updated);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.grey200,
                ),
              ),
              child: Text(
                _labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value > 2 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppColors.primary,
        ),
        Text(
          'Every $value days',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.time,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final TimeOfDay time;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.access_time_rounded,
          color: AppColors.primary,
        ),
        title: Text(
          '$h:$m',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: canDelete
            ? IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.grey400,
            size: 20,
          ),
          onPressed: onDelete,
        )
            : null,
      ),
    );
  }
}