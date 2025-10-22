// lib/widgets/bottom_sheet_widgets/photo_utils.dart
import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/token_storage.dart'; // ⬅️ 토큰 읽기

bool _isHttp(String s) =>
    s.toLowerCase().startsWith('http://') || s.toLowerCase().startsWith('https://');

bool _looksLikeLocalPath(String s) {
  final l = s.toLowerCase();
  return l.startsWith('file://') ||
      l.startsWith('/storage/') ||
      l.startsWith('/sdcard')   ||
      l.startsWith('/mnt/')     ||
      l.startsWith('/data/');
}

String _joinBase(String base, String path) {
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final p = path.startsWith('/') ? path : '/$path';
  return '$b$p';
}

String _absUrl(String s) => _joinBase(kBaseUrl, s);

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image),
  );
}

/// 서버 이미지가 인증 필요할 수 있으니 Authorization 헤더를 붙여서 로드
class _AuthNetImage extends StatelessWidget {
  const _AuthNetImage(this.url, {required this.fit});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: TokenStorage.read(), // ⬅️ 비동기로 토큰 로드
      builder: (context, snap) {
        // 토큰 기다리는 동안 잠깐 회색
        if (snap.connectionState != ConnectionState.done) {
          return const _PhotoPlaceholder();
        }
        final token = snap.data;
        final headers = (token != null && token.isNotEmpty)
            ? {'Authorization': 'Bearer $token'}
            : null;

        // 디버그: 실제 요청 URL
        debugPrint('🖼️ network img => $url  headers=${headers!=null}');
        return Image.network(
          url,
          fit: fit,
          headers: headers, // ⬅️ 핵심
          errorBuilder: (_, err, __) {
            debugPrint('❌ image load error: $err  url=$url');
            return const _PhotoPlaceholder();
          },
        );
      },
    );
  }
}

Widget buildPhotoThumb(String raw, {BoxFit fit = BoxFit.cover}) {
  final s = raw.trim();
  if (s.isEmpty) return const _PhotoPlaceholder();

  // 1) 로컬 파일
  if (_looksLikeLocalPath(s)) {
    final path = s.startsWith('file://') ? Uri.parse(s).toFilePath() : s;
    debugPrint('🖼️ file img => $path');
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
    );
  }

  // 2) 네트워크(상대/절대)
  final url = _isHttp(s) ? s : _absUrl(s);

  // 인증이 필요하든 아니든 헤더 가능 버전으로 통일
  return _AuthNetImage(url, fit: fit);
}
