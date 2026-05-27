import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseService {
  const SupabaseService();

  bool get isReady => SupabaseConfig.isConfigured;

  SupabaseClient? get clientOrNull {
    if (!isReady) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}

