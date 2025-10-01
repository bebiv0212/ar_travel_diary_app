import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import '../core/config.dart';
import '../core/token_storage.dart';

class UploadPhotoResult {
  final String url;
  final String? thumbUrl;   // ✅ null 가능
  final int? width;         // ✅ null 가능
  final int? height;        // ✅ null 가능
  final int? bytes;         // ✅ null 가능
  final String? mime;       // 서버가 넣어주면 받기
  final String? ext;        // 서버가 넣어주면 받기

  UploadPhotoResult({
    required this.url,
    this.thumbUrl,
    this.width,
    this.height,
    this.bytes,
    this.mime,
    this.ext,
  });

  factory UploadPhotoResult.fromJson(Map<String, dynamic> j) => UploadPhotoResult(
    url: (j['url'] ?? '') as String,
    thumbUrl: j['thumbUrl'] as String?,
    width: (j['width'] is num) ? (j['width'] as num).toInt() : null,
    height: (j['height'] is num) ? (j['height'] as num).toInt() : null,
    bytes: (j['bytes'] is num) ? (j['bytes'] as num).toInt() : null,
    mime: j['mime'] as String?,
    ext: j['ext'] as String?,
  );
}

class UploadsApi {
  late final Dio _dio;
  UploadsApi({Dio? dio}) {
    _dio = dio ??
        Dio(BaseOptions(
          baseUrl: kBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(minutes: 2),
          headers: {'Accept': 'application/json'},
        ));
  }

  Future<void> _attachAuth() async {
    final token = await TokenStorage.read();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // ✅ 파일 경로에서 MIME 추론
  MediaType _mediaTypeFromPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.heic':
        return MediaType('image', 'heic');
      case '.heif':
        return MediaType('image', 'heif');
      default:
        return MediaType('image', 'jpeg'); // 폴백
    }
  }

  Future<UploadPhotoResult> uploadPhoto(
      File file, {
        void Function(int sent, int total)? onSendProgress,
      }) async {
    await _attachAuth();

    final mt = _mediaTypeFromPath(file.path); // ✅ 동적 MIME
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
        contentType: mt,
      )
    });

    final res = await _dio.post(
      '/api/uploads/photo',
      data: form,
      onSendProgress: onSendProgress,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('업로드 실패: ${res.statusCode} ${res.data}');
    }
    return UploadPhotoResult.fromJson(res.data as Map<String, dynamic>);
  }
}
