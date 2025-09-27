import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 압축 결과(또는 원본) 이미지를 앱 문서폴더로 복사하여 영구 보관하고
/// 'file:///...' 형태의 문자열을 반환한다.
Future<String> persistLocalPhoto(File src) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'photos',
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }

  final ext = p.extension(src.path).isNotEmpty ? p.extension(src.path) : '.webp';
  final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
  final destPath = p.join(dir.path, fileName);

  await src.copy(destPath);
  return 'file://$destPath';
}
