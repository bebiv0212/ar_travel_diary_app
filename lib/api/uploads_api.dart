import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/config.dart';
import '../core/token_storage.dart';

class UploadPhotoResult {
  final String url;
  final String thumbUrl;
  final int width;
  final int height;
  final int bytes;
  UploadPhotoResult({
    required this.url,
    required this.thumbUrl,
    required this.width,
    required this.height,
    required this.bytes,
  });

  factory UploadPhotoResult.fromJson(Map<String, dynamic> j) => UploadPhotoResult(
    url: j['url'] as String,
    thumbUrl: (j['thumbUrl'] ?? j['thumbnail'] ?? '') as String,
    width: (j['width'] as num).toInt(),
    height: (j['height'] as num).toInt(),
    bytes: (j['bytes'] as num).toInt(),
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

  Future<UploadPhotoResult> uploadPhoto(
      File file, {
        void Function(int sent, int total)? onSendProgress,
      }) async {
    await _attachAuth();

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
        contentType: MediaType('image', 'webp'), // 우리가 webp로 압축했음
      )
    });

    final res = await _dio.post(
      '/api/uploads/photo',
      data: form,
      onSendProgress: onSendProgress, // 진행률 콜백
      options: Options(contentType: 'multipart/form-data'),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('업로드 실패: ${res.statusCode} ${res.data}');
    }
    return UploadPhotoResult.fromJson(res.data as Map<String, dynamic>);
  }
}
