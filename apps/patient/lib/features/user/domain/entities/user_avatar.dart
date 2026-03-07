import 'dart:typed_data';

final class UserAvatarMeta {
  const UserAvatarMeta({
    required this.avatarUrl,
    required this.contentType,
    required this.width,
    required this.height,
    required this.sizeBytes,
    required this.updatedAt,
  });

  final String avatarUrl;
  final String contentType;
  final int width;
  final int height;
  final int sizeBytes;
  final DateTime? updatedAt;
}

final class UserAvatarBinary {
  const UserAvatarBinary({
    required this.isNotModified,
    required this.bytes,
    required this.eTag,
    required this.lastModified,
    required this.cacheControl,
  });

  factory UserAvatarBinary.notModified({
    required String? eTag,
    required String? lastModified,
    required String? cacheControl,
  }) {
    return UserAvatarBinary(
      isNotModified: true,
      bytes: null,
      eTag: eTag,
      lastModified: lastModified,
      cacheControl: cacheControl,
    );
  }

  final bool isNotModified;
  final Uint8List? bytes;
  final String? eTag;
  final String? lastModified;
  final String? cacheControl;
}
