import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router.dart';
import '../../../shared/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Profile card ─────────────────────────────
          _ProfileCard(
            name: user?.name ?? 'User',
            email: user?.email ?? '',
          ),

          const SizedBox(height: 20),

          // ── Preferences ──────────────────────────────
          _SectionLabel(label: 'Preferences'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _NavRow(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.primary,
                title: 'Notification settings',
                onTap: () =>
                    context.push(AppRoutes.notificationSettings),
              ),
              _NavRow(
                icon: Icons.language_outlined,
                iconColor: AppColors.primary,
                title: 'Language',
                trailing: const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.access_time_outlined,
                iconColor: AppColors.primary,
                title: 'Timezone',
                trailing: Text(
                  user?.timezone ?? 'Asia/Seoul',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────
          _SectionLabel(label: 'About'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _NavRow(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.grey600,
                title: 'App version',
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.grey600,
                title: 'Privacy policy',
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.description_outlined,
                iconColor: AppColors.grey600,
                title: 'Terms of service',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Account ───────────────────────────────────
          _SectionLabel(label: 'Account'),
          const SizedBox(height: 10),
          _SettingsCard(
            children: [
              _NavRow(
                icon: Icons.logout_rounded,
                iconColor: AppColors.missed,
                title: 'Sign out',
                titleColor: AppColors.missed,
                onTap: () => _confirmSignOut(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.missed),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(authNotifierProvider.notifier).signOut();

    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }
}

// ── Profile card ──────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────

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

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey400,
            size: 20,
          ),
    );
  }
}