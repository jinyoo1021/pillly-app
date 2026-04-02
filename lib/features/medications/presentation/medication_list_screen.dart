import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../shared/theme/app_colors.dart';
import '../domain/medication.dart';
import '../providers/medication_provider.dart';
import '../../../shared/widgets/bottom_nav.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(AppRoutes.medicationAdd),
          ),
        ],
      ),
      body: medicationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _ErrorView(
          onRetry: () =>
              ref.read(medicationListProvider.notifier).refresh(),
        ),
        data: (medications) {
          if (medications.isEmpty) {
            return const _EmptyView();
          }

          // Separate active and inactive
          final active =
          medications.where((m) => m.isActive).toList();
          final inactive =
          medications.where((m) => !m.isActive).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(medicationListProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(label: 'Active (${active.length})'),
                  ...active.map((m) => _MedicationTile(medication: m)),
                ],
                if (inactive.isNotEmpty) ...[
                  _SectionHeader(
                      label: 'Inactive (${inactive.length})'),
                  ...inactive
                      .map((m) => _MedicationTile(medication: m)),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNav(),
    );
  }
}

// Section header

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Medication tile

class _MedicationTile extends ConsumerWidget {
  const _MedicationTile({required this.medication});
  final Medication medication;

  String get _scheduleLabel {
    return switch (medication.cycleType) {
      CycleType.daily => 'Every day',
      CycleType.weekly => 'Weekly',
      CycleType.interval =>
      'Every ${medication.intervalDays ?? '?'} days',
    };
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete medication'),
        content: Text(
            'Delete "${medication.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
            TextButton.styleFrom(foregroundColor: AppColors.missed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success =
    await ref.read(medicationListProvider.notifier).delete(medication.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '"${medication.name}" deleted.'
              : 'Failed to delete. Please try again.'),
          backgroundColor:
          success ? AppColors.done : AppColors.missed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: medication.isActive
                ? AppColors.primarySurface
                : AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medication_rounded,
            color: medication.isActive
                ? AppColors.primary
                : AppColors.grey400,
            size: 22,
          ),
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: medication.isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            [
              _scheduleLabel,
              medication.scheduledTimes.join(', '),
              if (medication.dosage != null)
                '${medication.dosage} ${medication.unit ?? ''}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active toggle
            Switch(
              value: medication.isActive,
              onChanged: (_) => ref
                  .read(medicationListProvider.notifier)
                  .toggle(medication.id),
              activeThumbColor: AppColors.primary,
            ),
            // More options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.grey400),
              onSelected: (value) {
                if (value == 'edit') {
                  context.push(
                    AppRoutes.medicationEdit
                        .replaceFirst(':id', medication.id),
                    extra: medication,
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.textSecondary),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.missed),
                      SizedBox(width: 10),
                      Text('Delete',
                          style: TextStyle(color: AppColors.missed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Empty / Error views

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💊', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No medications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first medication.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.medicationAdd),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add medication'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Failed to load medications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}