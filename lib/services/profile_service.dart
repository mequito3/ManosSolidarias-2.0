import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    return fetchProfileByUserId(user.id);
  }

  Future<UserProfile?> ensureCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final existing = await fetchProfileByUserId(user.id);
    if (existing != null) {
      return existing;
    }

    final metadata = user.userMetadata ?? {};
    String resolve(dynamic value) {
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return '';
    }

    final displayName = <String?>[
      resolve(metadata['display_name']),
      resolve(metadata['full_name']),
      resolve(metadata['name']),
      resolve(metadata['user_name']),
      user.email != null ? resolve(user.email!.split('@').first) : null,
      'Miembro Solidario',
    ].firstWhere(
      (value) => value != null && value.isNotEmpty,
      orElse: () => 'Miembro Solidario',
    )!;
    final avatarUrl = metadata['avatar_url'] as String?;

    final provisional = UserProfile(
      userId: user.id,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: null,
      phone: null,
      city: null,
      address: null,
      documentType: null,
      documentNumber: null,
      bankHolder: null,
      bankName: null,
      bankAccountType: null,
      bankAccountNumber: null,
      donationQrUrl: null,
      isAdmin: false,
      isProfileComplete: false,
    );

    return upsertProfile(provisional);
  }

  Future<UserProfile?> fetchProfileByUserId(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final payload = profile.toUpsertPayload();

    final response = await _client
        .from('profiles')
        .upsert(payload)
        .select()
        .maybeSingle();

    if (response == null) {
      throw ProfileServiceException('No pudimos guardar el perfil.');
    }

    return UserProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) {
    return _uploadProfileAsset(
      bucket: 'perfiles',
      pathPrefix: 'users/$userId/avatars',
      data: data,
      contentType: contentType,
      fileExtension: fileExtension,
    );
  }

  Future<String> uploadDonationQr({
    required String userId,
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) {
    return _uploadProfileAsset(
      bucket: 'perfiles',
      pathPrefix: 'users/$userId/qr',
      data: data,
      contentType: contentType,
      fileExtension: fileExtension,
    );
  }

  Future<String> _uploadProfileAsset({
    required String bucket,
    required String pathPrefix,
    required Uint8List data,
    required String contentType,
    required String fileExtension,
  }) async {
    final storage = _client.storage.from(bucket);
    var sanitizedExt = fileExtension.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitizedExt.isEmpty) {
      sanitizedExt = 'jpg';
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '$pathPrefix/$timestamp.$sanitizedExt';

    try {
      await storage.uploadBinary(
        objectPath,
        data,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      return storage.getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw ProfileServiceException(error.message);
    } catch (_) {
      throw ProfileServiceException('No pudimos subir la imagen.');
    }
  }
}

class ProfileServiceException implements Exception {
  ProfileServiceException(this.message);

  final String message;

  @override
  String toString() => 'ProfileServiceException: $message';
}
