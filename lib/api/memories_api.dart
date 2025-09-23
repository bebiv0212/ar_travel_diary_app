import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/token_storage.dart';

class Memory {
  final String id;
  Memory(this.id);
  factory Memory.fromJson(Map<String, dynamic> j) => Memory(j['id'].toString());
}

class MemoriesApi {
  final http.Client _client;
  MemoriesApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.read();
    if (token == null) throw Exception('인증 필요: 토큰이 없습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// ✅ latitude/longitude를 선택값(double?)으로 변경
  Future<Memory> create({
    required String groupId,
    required String text,
    double? latitude,
    double? longitude,
    String? anchor,
    List<String>? tags,
    bool favorite = false,
    String visibility = 'private',
    DateTime? date,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/memories');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'groupId': groupId,
      'text': text,
      'favorite': favorite,
      'visibility': visibility,
      if (anchor != null) 'anchor': anchor,
      if (tags != null) 'tags': tags,
      if (date != null) 'date': date.toIso8601String(),
      // ✅ 좌표가 둘 다 있을 때만 전송
      if (latitude != null && longitude != null) 'latitude': latitude,
      if (latitude != null && longitude != null) 'longitude': longitude,
    };

    final res = await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('메모 생성 실패: ${res.statusCode} ${res.body}');
    }
    return Memory.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
