import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Resultado da captura/seleção de uma imagem.
class ArchbaseImage {
  ArchbaseImage({
    required this.bytes,
    required this.filename,
    this.path,
    this.sizeBytes,
    this.width,
    this.height,
  });

  final Uint8List bytes;
  final String filename;
  final String? path;
  final int? sizeBytes;
  final int? width;
  final int? height;
}

/// Captura/seleciona imagens da câmera ou galeria, com compressão opcional.
class ArchbaseImageService {
  ArchbaseImageService({
    ImagePicker? picker,
    this.maxBytes = 5 * 1024 * 1024,
    this.compressQuality = 80,
    this.maxDimension = 1600,
  }) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final int maxBytes;
  final int compressQuality;
  final int maxDimension;

  Future<ArchbaseImage?> pickFromCamera({
    bool compress = true,
    bool front = false,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
      imageQuality: compress ? compressQuality : 100,
      maxWidth: compress ? maxDimension.toDouble() : null,
    );
    return _materialize(file, compress: compress);
  }

  Future<ArchbaseImage?> pickFromGallery({bool compress = true}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: compress ? compressQuality : 100,
      maxWidth: compress ? maxDimension.toDouble() : null,
    );
    return _materialize(file, compress: compress);
  }

  Future<List<ArchbaseImage>> pickMultipleFromGallery({
    bool compress = true,
  }) async {
    final files = await _picker.pickMultiImage(
      imageQuality: compress ? compressQuality : 100,
      maxWidth: compress ? maxDimension.toDouble() : null,
    );
    final results = <ArchbaseImage>[];
    for (final file in files) {
      final img = await _materialize(file, compress: compress);
      if (img != null) results.add(img);
    }
    return results;
  }

  Future<ArchbaseImage?> _materialize(XFile? file,
      {required bool compress}) async {
    if (file == null) return null;
    Uint8List bytes = await file.readAsBytes();

    if (compress && bytes.length > maxBytes) {
      bytes = await compressBytes(bytes);
    }

    return ArchbaseImage(
      bytes: bytes,
      filename: file.name,
      path: file.path,
      sizeBytes: bytes.length,
    );
  }

  /// Comprime arquivo em disco devolvendo o caminho do compactado.
  Future<File?> compressFile(
    File file, {
    int? quality,
    int? maxDimension,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final target =
        '${tempDir.path}/cmp_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: quality ?? compressQuality,
      minWidth: maxDimension ?? this.maxDimension,
      minHeight: maxDimension ?? this.maxDimension,
    );
    return result == null ? null : File(result.path);
  }

  Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int? quality,
    int? maxDimension,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality ?? compressQuality,
        minWidth: maxDimension ?? this.maxDimension,
        minHeight: maxDimension ?? this.maxDimension,
      );
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('[archbase][image] compressão falhou: $e');
      return bytes;
    }
  }
}
