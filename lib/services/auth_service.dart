import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  ProfileModel? _currentUser;
  bool _registerNeedsVerification = false;
  static const _avatarPathPrefix = 'profile_avatar_path_';
  static const _oauthRedirectUrl = 'promohunter://login-callback';

  Future<ProfileModel> login({
    required String email,
    required String password,
  }) async {
    _registerNeedsVerification = false;
    final normalizedEmail = email.trim().toLowerCase();
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await _runAuthRequestWithRetry(
          () => client.auth.signInWithPassword(
            email: normalizedEmail,
            password: password,
          ),
        );
        final user = response.user;
        if (user != null) {
          final profile = await getUserProfile(user.id);
          _currentUser = profile ??
              ProfileModel(
                id: user.id,
                name:
                    user.userMetadata?['name'] as String? ?? 'User PromoHunter',
                email: user.email ?? normalizedEmail,
                role: 'user',
              );
          _currentUser = await _attachLocalAvatar(_currentUser!);
          return _currentUser!;
        }
      } on AuthException catch (error) {
        throw Exception(_mapAuthErrorMessage(error.message));
      } catch (error) {
        throw Exception(_mapGenericAuthError(error, fallback: 'Login gagal'));
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: email.contains('admin') ? 'Admin PromoHunter' : 'Demo User',
      email: email,
      role: email.contains('admin') ? 'admin' : 'user',
    );
    _currentUser = await _attachLocalAvatar(_currentUser!);
    return _currentUser!;
  }

  Future<ProfileModel> loginWithGoogle() async {
    _registerNeedsVerification = false;
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final launched = await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : _oauthRedirectUrl,
        );
        if (!launched) {
          throw Exception(
              'Login Google dibatalkan atau browser tidak terbuka.');
        }

        final event = await client.auth.onAuthStateChange
            .firstWhere(
          (event) => event.session?.user != null,
        )
            .timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw Exception(
              'Login Google belum selesai. Coba lagi dan pastikan kembali ke aplikasi setelah memilih akun.',
            );
          },
        );
        final user = event.session!.user;
        final profile = await _profileForSupabaseUser(user);
        _currentUser = await _attachLocalAvatar(profile);
        return _currentUser!;
      } on AuthException catch (error) {
        throw Exception(_mapAuthErrorMessage(error.message));
      } catch (error) {
        if (error is Exception) rethrow;
        throw Exception(
          _mapGenericAuthError(error, fallback: 'Login Google gagal'),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = const ProfileModel(
      id: 'demo-google-user',
      name: 'Google User',
      email: 'google.user@example.com',
      role: 'user',
    );
    _currentUser = await _attachLocalAvatar(_currentUser!);
    return _currentUser!;
  }

  Future<ProfileModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _registerNeedsVerification = false;
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final client = _supabaseService.clientOrNull;
    if (client != null) {
      try {
        final response = await _runAuthRequestWithRetry(
          () => client.auth.signUp(
            email: normalizedEmail,
            password: password,
            data: {'name': normalizedName},
          ),
        );
        final user = response.user;
        if (user == null) {
          throw Exception('Registrasi gagal. User tidak berhasil dibuat.');
        }

        final profile = ProfileModel(
          id: user.id,
          name: normalizedName,
          email: normalizedEmail,
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
        throw Exception(
          _mapGenericAuthError(error, fallback: 'Registrasi gagal'),
        );
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentUser = ProfileModel(
      id: 'demo-user',
      name: name,
      email: normalizedEmail,
      role: 'user',
    );
    _currentUser = await _attachLocalAvatar(_currentUser!);
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
        _currentUser = await _attachLocalAvatar(_currentUser!);
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
    _currentUser = await _attachLocalAvatar(_currentUser!);
    return _currentUser;
  }

  Future<ProfileModel> _profileForSupabaseUser(User user) async {
    final client = _supabaseService.clientOrNull;
    final existing = await getUserProfile(user.id);
    if (existing != null) return existing;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['name'] as String?)?.trim().isNotEmpty == true
        ? metadata['name'] as String
        : (metadata['full_name'] as String?)?.trim().isNotEmpty == true
            ? metadata['full_name'] as String
            : 'User PromoHunter';
    final profile = ProfileModel(
      id: user.id,
      name: name,
      email: user.email ?? '',
      role: 'user',
    );
    if (client != null) {
      await _upsertProfile(client: client, profile: profile);
    }
    return profile;
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
          return _attachLocalAvatar(ProfileModel.fromMap(response));
        }
      } catch (_) {
        // Fall back to in-memory state below.
      }
    }
    return _currentUser;
  }

  ProfileModel? getCurrentUser() => _currentUser;
  bool get registerNeedsVerification => _registerNeedsVerification;

  Future<ProfileModel> updateProfile({
    required String name,
    required String email,
    String? avatarPath,
    String? newPassword,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = newPassword?.trim();
    final client = _supabaseService.clientOrNull;

    if (client != null) {
      try {
        await _runAuthRequestWithRetry(
          () => client.auth.updateUser(
            UserAttributes(
              email: normalizedEmail,
              password:
                  normalizedPassword != null && normalizedPassword.isNotEmpty
                      ? normalizedPassword
                      : null,
              data: {'name': normalizedName},
            ),
          ),
        );
        final user = client.auth.currentUser;
        if (user != null) {
          final updated = ProfileModel(
            id: user.id,
            name: normalizedName,
            email: user.email ?? normalizedEmail,
            role: _currentUser?.role ?? 'user',
            avatarPath: avatarPath ?? _currentUser?.avatarPath,
          );
          await _upsertProfile(client: client, profile: updated);
          if (avatarPath != null) {
            await _persistAvatarPath(updated.id, avatarPath);
          }
          _currentUser = await _attachLocalAvatar(updated);
          return _currentUser!;
        }
      } on AuthException catch (error) {
        throw Exception(_mapAuthErrorMessage(error.message));
      } catch (error) {
        throw Exception(
          _mapGenericAuthError(error, fallback: 'Update profil gagal'),
        );
      }
    }

    final updated = (_currentUser ??
            ProfileModel(
              id: 'demo-user',
              name: normalizedName,
              email: normalizedEmail,
              role: 'user',
            ))
        .copyWith(
      name: normalizedName,
      email: normalizedEmail,
      avatarPath: avatarPath ?? _currentUser?.avatarPath,
    );
    if (avatarPath != null) {
      await _persistAvatarPath(updated.id, avatarPath);
    }
    _currentUser = await _attachLocalAvatar(updated);
    return _currentUser!;
  }

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

  Future<ProfileModel> _attachLocalAvatar(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    final avatarPath = prefs.getString('$_avatarPathPrefix${profile.id}');
    return profile.copyWith(avatarPath: avatarPath ?? profile.avatarPath);
  }

  Future<void> _persistAvatarPath(String userId, String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarPathPrefix$userId', avatarPath);
  }

  String _mapAuthErrorMessage(String message) {
    final normalized = message.trim().toLowerCase();
    if (normalized == 'invalid login credentials') {
      return 'Email atau password salah. Untuk akun admin, pastikan akun tersebut sudah terdaftar di Auth Supabase lalu role pada tabel profiles diubah menjadi admin.';
    }
    return message;
  }

  Future<T> _runAuthRequestWithRetry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (error) {
      if (!_isTransientNetworkError(error)) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return request();
    }
  }

  bool _isTransientNetworkError(Object error) {
    if (error is SocketException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('connection reset by peer') ||
        message.contains('connection closed before full header was received') ||
        message.contains('connection terminated during handshake') ||
        message.contains('clientexception');
  }

  String _mapGenericAuthError(Object error, {required String fallback}) {
    if (_isTransientNetworkError(error)) {
      return 'Koneksi ke server auth terputus. Coba ganti jaringan, matikan VPN atau Private DNS, lalu login lagi.';
    }
    return '$fallback: $error';
  }
}
