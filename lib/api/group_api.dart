import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/token_storage.dart';

class Group {
  final String id;        // Mongo ObjectId (24 hex)
  final String name;
  final String? color;

  Group({required this.id, required this.name, this.color});

  factory Group.fromJson(Map<String, dynamic> j) => Group(
    id: ((j['_id'] ?? j['id'])?.toString() ?? '').trim(), // ✅ _id 우선
    name: (j['name'] as String?)?.trim() ?? '',
    color: j['color'] as String?,
  );
}

String colorToHex6(Color c) {
  final argb = c.toARGB32(); // 0xAARRGGBB
  final rgb = argb & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}


class GroupApi {
  final http.Client _client;
  GroupApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.read();
    if (token == null) throw Exception('인증 필요: 토큰이 없습니다.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// POST /api/groups
  Future<Group> create({required String name, Color? color}) async {
    final uri = Uri.parse('$kBaseUrl/api/groups');
    final headers = await _authHeaders();
    final body = <String, dynamic>{'name': name};
    if (color != null) body['color'] = colorToHex6(color);

    if (kDebugMode) {
      debugPrint('[GroupApi] POST $uri body=${jsonEncode(body)}');
    }

    final res = await _client.post(uri, headers: headers, body: jsonEncode(body));
    if (kDebugMode) {
      debugPrint('[GroupApi] status=${res.statusCode} body=${res.body}');
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('그룹 생성 실패: ${res.statusCode} ${res.body}');
    }
    return Group.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// GET /api/groups
  Future<List<Group>> listMyGroups() async {
    final uri = Uri.parse('$kBaseUrl/api/groups');
    final headers = await _authHeaders();

    if (kDebugMode) debugPrint('[GroupApi] GET $uri');

    final res = await _client.get(uri, headers: headers);
    if (kDebugMode) {
      debugPrint('[GroupApi] status=${res.statusCode} len=${res.body.length}');
    }
    if (res.statusCode != 200) {
      throw Exception('그룹 목록 실패: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('응답 형식 오류: List가 아님');
    }
  }
  /// name, color 중 하나만 변경해도 OK
  Future<Group> update({
    required String id,
    String? name,
    Color? color,
  }) async {
    if (name == null && color == null) {
      throw ArgumentError('update: name 또는 color 중 하나는 제공해야 합니다.');
    }

    Map<String, dynamic> _makeBody() {
      final m = <String, dynamic>{};
      if (name != null) m['name'] = name;
      if (color != null) m['color'] = colorToHex6(color); // #RRGGBB (알파 제외)
      return m;
    }

    Future<Group> _handleResponse(http.Response res) async {
      if (kDebugMode) {
        debugPrint('[GroupApi] status=${res.statusCode} body=${res.body}');
      }
      if (res.statusCode == 200) {
        // 바디가 객체인 정상 케이스
        if (res.body.isNotEmpty) {
          return Group.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        }
        // 200인데 바디가 비어있는 특이 서버
        return Group(id: id, name: name ?? '', color: color != null ? colorToHex6(color) : null);
      }
      if (res.statusCode == 204) {
        // No Content도 성공 처리
        return Group(id: id, name: name ?? '', color: color != null ? colorToHex6(color) : null);
      }
      throw Exception('그룹 수정 실패: ${res.statusCode} ${res.body}');
    }

    final uri = Uri.parse('$kBaseUrl/api/groups/$id');
    final headers = await _authHeaders();
    final bodyStr = jsonEncode(_makeBody());

    // 1) PUT 먼저
    if (kDebugMode) debugPrint('[GroupApi] PUT  $uri body=$bodyStr');
    final putRes = await _client.put(uri, headers: headers, body: bodyStr);
    if (putRes.statusCode == 200 || putRes.statusCode == 204) {
      return _handleResponse(putRes);
    }

    // 2) PUT이 거절되면 PATCH로 폴백
    if (kDebugMode) debugPrint('[GroupApi] PATCH $uri body=$bodyStr');
    final patchRes = await _client.patch(uri, headers: headers, body: bodyStr);
    return _handleResponse(patchRes);
  }

  /// DELETE /api/groups/:id
  Future<void> delete(String id) async {
    final uri = Uri.parse('$kBaseUrl/api/groups/$id');
    final headers = await _authHeaders();

    if (kDebugMode) debugPrint('[GroupApi] DELETE $uri');

    final res = await _client.delete(uri, headers: headers);
    if (kDebugMode) debugPrint('[GroupApi] status=${res.statusCode} body=${res.body}');

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('그룹 삭제 실패: ${res.statusCode} ${res.body}');
    }
  }
}
