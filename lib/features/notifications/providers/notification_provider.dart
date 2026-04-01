import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/notification_settings.dart';

class NotificationSettingsNotifier
    extends Notifier<NotificationSettings> {
  static const _keyEnabled = 'notif_enabled';
  static const _keyAdvance = 'notif_advance_minutes';

  @override
  NotificationSettings build() {
    _load();
    return const NotificationSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_keyEnabled) ?? true,
      advanceMinutes: prefs.getInt(_keyAdvance) ?? 0,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }

  Future<void> setAdvanceMinutes(int minutes) async {
    state = state.copyWith(advanceMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAdvance, minutes);
  }
}

final notificationSettingsProvider =
NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);