import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthApi {
  final http.Client _client;
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  Future<(String token, User user)> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/auth/register');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, if (name != null) 'name': name}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final token = body['token'] as String;
      final user = User.fromJson(body['user']);
      await TokenStorage.save(token);
      return (token, user);
    } else if (res.statusCode == 409) {
      throw AuthException('이미 사용 중인 이메일입니다. (409)');
    } else {
      throw AuthException('회원가입 실패: ${res.statusCode} ${res.body}');
    }
  }

  Future<(String token, User user)> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/auth/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final token = body['token'] as String;
      final user = User.fromJson(body['user']);
      await TokenStorage.save(token);
      return (token, user);
    } else if (res.statusCode == 401) {
      throw AuthException('이메일 또는 비밀번호가 올바르지 않습니다. (401)');
    } else {
      throw AuthException('로그인 실패: ${res.statusCode} ${res.body}');
    }
  }

  Future<User> me() async {
    final token = await TokenStorage.read();
    if (token == null) throw AuthException('로그인이 필요합니다.');

    final uri = Uri.parse('$kBaseUrl/api/auth/me');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return User.fromJson(body);
    } else if (res.statusCode == 401) {
      throw AuthException('인증 만료 또는 잘못된 토큰입니다. (401)');
    } else {
      throw AuthException('내 정보 조회 실패: ${res.statusCode} ${res.body}');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
