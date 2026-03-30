import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';

class SupabaseClientService {
  SupabaseClientService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  static bool get isAuthenticated => currentUser != null;
}