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
  final rgb = c.value & 0x00FFFFFF;
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
}
