import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class StorageService {
  StorageService([SupabaseService? supabaseService])
      : _supabaseService = supabaseService ?? const SupabaseService();

  final SupabaseService _supabaseService;
  static const String bucketName = 'promo-images';

  Future<String?> uploadPromoImage(XFile file) async {
    final client = _supabaseService.clientOrNull;
    if (client == null) return null;

    final bytes = await file.readAsBytes();
    final extension = _fileExtension(file.name);
    final path =
        'promos/${DateTime.now().millisecondsSinceEpoch}_${_safeFileName(file.name)}';

    await client.storage.from(bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: _contentTypeForExtension(extension),
          ),
        );

    return client.storage.from(bucketName).getPublicUrl(path);
  }

  Future<Uint8List> readBytes(XFile file) => file.readAsBytes();

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _fileExtension(String value) {
    final index = value.lastIndexOf('.');
    if (index < 0 || index == value.length - 1) return 'jpg';
    return value.substring(index + 1).toLowerCase();
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}
