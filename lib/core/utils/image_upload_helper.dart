import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ImageUploadHelper {
  static const int maxBytes = 5 * 1024 * 1024;

  static const Set<String> allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
  };

  static String extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  static void validate(File image) {
    if (!image.existsSync()) {
      throw Exception('File gambar tidak ditemukan. Pilih ulang gambar.');
    }
    final len = image.lengthSync();
    if (len <= 0) {
      throw Exception('File gambar kosong. Pilih ulang gambar.');
    }
    if (len > maxBytes) {
      throw Exception('Ukuran gambar maksimal 5MB.');
    }
    final ext = extensionOf(image.path);
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
        'Format gambar tidak didukung${ext.isEmpty ? '' : ' (.$ext)'}. Gunakan JPG, PNG, atau WEBP.',
      );
    }
  }

  static MediaType mediaTypeFor(String path) {
    final mimeStr = lookupMimeType(path) ?? '';
    if (mimeStr.startsWith('image/')) {
      return MediaType.parse(mimeStr);
    }
    final ext = extensionOf(path);
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static String filenameOf(String path) {
    final name = path.split('/').last;
    return name.isEmpty ? 'upload.jpg' : name;
  }
}
