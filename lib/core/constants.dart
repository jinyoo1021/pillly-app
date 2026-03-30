class AppConstants {
    AppConstants._();

    // API
    static const String apiBaseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.pilly.app/v1',
    );

    // Supabase
    static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    // Notification
    static const String notificationChannelId = 'pillly_reminder';
    static const String notificationChannelName = 'Medication Reminder';
    static const String iosNotificationCategoryId = 'PILL_REMINDER';

    // Notification action IDs
    static const String actionDone = 'ACTION_DONE';
    static const String actionSkip = 'ACTION_SKIP';

    // Shared preferences keys
    static const String prefKeyOnboardingDone = 'onboarding_done';
    static const String prefKeyFcmToken = 'fcm_token';
}

