import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  static const List<int> _advanceOptions = [0, 5, 10, 15, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Master toggle ────────────────────────────
          _SettingsCard(
            children: [
              _ToggleRow(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.primary,
                title: 'Enable notifications',
                subtitle: 'Receive reminders for all medications',
                value: settings.enabled,
                onChanged: (v) => ref
                    .read(notificationSettingsProvider.notifier)
                    .setEnabled(v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Advance notice ───────────────────────────
          if (settings.enabled) ...[
            _SectionLabel(label: 'Remind me before scheduled time'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: _advanceOptions.map((minutes) {
                final label = minutes == 0
                    ? 'At scheduled time'
                    : '$minutes minutes before';
                final isSelected =
                    settings.advanceMinutes == minutes;
                return _SelectableRow(
                  title: label,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(notificationSettingsProvider.notifier)
                      .setAdvanceMinutes(minutes),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can respond to reminders directly '
                          'from your lock screen without opening the app.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared card components ────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((entry) => Column(
          children: [
            entry.value,
            if (entry.key < children.length - 1)
              const Divider(
                  height: 1, color: AppColors.grey200),
          ],
        ))
            .toList(),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: isSelected
              ? AppColors.primary
              : AppColors.textPrimary,
          fontWeight:
          isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded,
          color: AppColors.primary, size: 20)
          : null,
    );
  }
}

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