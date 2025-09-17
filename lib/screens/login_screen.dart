import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() { _email.dispose(); _pw.dispose(); super.dispose(); }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_email.text.trim(), _pw.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('환영합니다, ${auth.userDisplayName}')),
      );
      // AuthGate가 Provider 변화를 감지해서 자동으로 홈으로 전환
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
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
                    onPressed: loading ? null : _login,
                    child: Text(loading ? '로그인 중...' : '로그인'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: loading ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
