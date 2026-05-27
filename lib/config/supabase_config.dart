class SupabaseConfig {
  static const String url = 'https://ujltafrzoeeklcudihgm.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbHRhZnJ6b2Vla2xjdWRpaGdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODU1NDgsImV4cCI6MjA5NTQ2MTU0OH0.Nu2Fur8iPmPsJgQiYUfC48OsW1WW3-oQHXIK1LxN9mY';

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_SUPABASE_URL') &&
      !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
}
