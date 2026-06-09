import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  ProfileModel? _currentUser;
  bool _registerNeedsVerification = false;

  Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    _registerNeedsVerification = false;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = response.user;
        if (user != null) {
          final profile = await getUserProfile(user.id);
          _currentUser = profile ??
              ProfileModel(
                id: user.id,
                name: user.userMetadata?['name'] as String? ?? 'User PromoHunter',
                email: user.email ?? email,
                role: 'user',
              );
          return _currentUser!;
        }
      } on AuthException catch (error) {
        throw Exception(error.message);
      } catch (error) {
        throw Exception('Login gagal: $error');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: email.contains('admin') ? 'Admin PromoHunter' : 'Demo User',
      email: email,
      role: email.contains('admin') ? 'admin' : 'user',
    );
    return _currentUser!;
  }

  Future<ProfileModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _registerNeedsVerification = false;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        final user = response.user;
        if (user == null) {
          throw Exception('Registrasi gagal. User tidak berhasil dibuat.');
        }

        final profile = ProfileModel(
          id: user.id,
          name: name,
          email: email,
          role: 'user',
        );

        final hasSession =
            response.session != null || client.auth.currentSession != null;
        _registerNeedsVerification = !hasSession;
        if (hasSession) {
          await _upsertProfile(
            client: client,
            profile: profile,
          );
          await client.auth.signOut();
        }

        _currentUser = null;
        return profile;
      } on AuthException catch (error) {
        throw Exception(error.message);
      } catch (error) {
        if (error is Exception) rethrow;
        throw Exception('Registrasi gagal: $error');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: name,
      email: email,
      role: 'user',
    );
    return _currentUser!;
  }

  Future<void> logout() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {
        // Keep local logout behavior below.
      }
    }
    _currentUser = null;
  }

  Future<ProfileModel?> restoreSession() async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      final user = client.auth.currentUser;
      if (user != null) {
        _currentUser = await getUserProfile(user.id) ??
            ProfileModel(
              id: user.id,
              name: user.userMetadata?['name'] as String? ?? 'User PromoHunter',
              email: user.email ?? '',
              role: 'user',
            );
        return _currentUser;
      }
    }
    return _currentUser;
  }

  Future<ProfileModel?> refreshCurrentUserProfile() async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return _currentUser;
    final user = client.auth.currentUser;
    if (user == null) return null;

    _currentUser = await getUserProfile(user.id) ??
        ProfileModel(
          id: user.id,
          name: user.userMetadata?['name'] as String? ?? 'User PromoHunter',
          email: user.email ?? '',
          role: 'user',
        );
    return _currentUser;
  }

  Future<ProfileModel?> getUserProfile(String userId) async {
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (response != null) {
          return ProfileModel.fromMap(response);
        }
      } catch (_) {
        // Fall back to in-memory state below.
      }
    }
    return _currentUser;
  }

  ProfileModel? getCurrentUser() => _currentUser;
  bool get registerNeedsVerification => _registerNeedsVerification;

  Future<void> _upsertProfile({
    required SupabaseClient client,
    required ProfileModel profile,
  }) async {
    await client.from('profiles').upsert({
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'role': profile.role,
    });
  }
}
