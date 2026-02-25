import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

final class AvatarImageProcessor {
  AvatarImageProcessor({ImageCropper? cropper}) : _cropper = cropper ?? ImageCropper();

  final ImageCropper _cropper;

  Future<File?> processForUpload(XFile pickedFile) async {
    final croppedFile = await _cropper.cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.png,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪头像',
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: '裁剪头像',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    final sourceFile = File(croppedFile.path);
    if (!sourceFile.existsSync()) {
      return null;
    }

    final rawBytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw const _AvatarImageProcessException('无法解析图片，请重新选择');
    }

    final square = _cropSquare(decoded);
    final resized = img.copyResize(
      square,
      width: 1024,
      height: 1024,
      interpolation: img.Interpolation.average,
    );
    final pngBytes = img.encodePng(resized, level: 6);
    if (pngBytes.isEmpty) {
      throw const _AvatarImageProcessException('图片处理失败，请重试');
    }

    final tempFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'mindisle_avatar_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}.png',
    );
    await tempFile.writeAsBytes(pngBytes, flush: true);
    return tempFile;
  }

  img.Image _cropSquare(img.Image source) {
    final side = min(source.width, source.height);
    final offsetX = ((source.width - side) / 2).floor();
    final offsetY = ((source.height - side) / 2).floor();
    return img.copyCrop(source, x: offsetX, y: offsetY, width: side, height: side);
  }
}

final class _AvatarImageProcessException implements Exception {
  const _AvatarImageProcessException(this.message);

  final String message;

  @override
  String toString() => message;
}
