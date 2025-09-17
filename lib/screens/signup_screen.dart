import 'package:flutter/material.dart';
import 'package:joljak/screens/profile_screen.dart';
import '../api/auth_api.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _name = TextEditingController();
  final _api = AuthApi();
  bool _loading = false;

  @override
  void dispose() { _email.dispose(); _pw.dispose(); _name.dispose(); super.dispose(); }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final (token, user) = await _api.register(
        email: _email.text.trim(),
        password: _pw.text,
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('가입 완료: ${user.email}')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일', border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: '이름(선택)', border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pw,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '비밀번호', border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48, width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        child: Text(_loading ? '가입 중...' : '회원가입'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
