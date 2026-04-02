import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../theme/app_colors.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = switch (location) {
      AppRoutes.home => 0,
      AppRoutes.medicationList => 1,
      AppRoutes.doseHistory => 2,
      AppRoutes.doseStats => 3,
      _ => 0,
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.medicationList);
            case 2:
              context.go(AppRoutes.doseHistory);
            case 3:
              context.go(AppRoutes.doseStats);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication_rounded),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}