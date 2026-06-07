import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';
import 'package:hms_app/providers/user_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      await supabase.auth.signInWithPassword(email: email, password: password);

      // 1. Check if the widget is still here after the Supabase login attempt
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 2. Wait for the profile to be fetched
      await userProvider.fetchUserProfile();

      // 3. Since there was another async gap (await), we need one more check!
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/room-map');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Icon and App Title Section ─────────────────────
                Icon(Icons.hotel_rounded, size: 64, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'HMS App',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Hệ thống quản lý khách sạn',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Login Form Section ─────────────────────────────
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 48),

                // Footer Section
                Text(
                  'Bản quyền © 2026 HMS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
