import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/lib/base_service.dart';

class StorageService extends BaseService {
  StorageService() : super('storage-service');

  Future<Map<String, dynamic>> createUploadUrl(
    String? token,
    String path, {
    String contentType = 'application/octet-stream',
  }) {
    return post<Map<String, dynamic>>('/v1/upload-url', {
      'bucket': 'ryvo-storage',
      'path': path,
      'content_type': contentType,
    }, token: token);
  }

  Future<String> uploadBytes(
    String? token,
    Uint8List bytes,
    String storagePath, {
    String contentType = 'application/octet-stream',
  }) async {
    if (apiClientTestMode) {
      throw Exception('API disabled in test mode');
    }
    final res = await createUploadUrl(token, storagePath, contentType: contentType);
    final signedUrl = res['signedUrl']?.toString() ?? res['signed_url']?.toString() ?? '';
    final path = res['path']?.toString() ?? storagePath;
    if (signedUrl.isEmpty) throw Exception('Upload URL unavailable');

    final headers = <String, String>{'Content-Type': contentType};
    final uploadToken = res['token']?.toString();
    if (uploadToken != null && uploadToken.isNotEmpty) {
      headers['x-upsert'] = 'true';
    }

    final put = await http
        .put(Uri.parse(signedUrl), headers: headers, body: bytes)
        .timeout(const Duration(seconds: 60));
    if (put.statusCode >= 400) {
      throw Exception('Upload failed (${put.statusCode})');
    }
    return path;
  }

  Future<String> uploadFile(
    String? token,
    Uint8List bytes,
    String storagePath,
    String fileName,
  ) async {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'bin';
    final contentType = _contentTypeForExt(ext);
    return uploadBytes(token, bytes, storagePath, contentType: contentType);
  }

  String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}

final storageService = StorageService();
