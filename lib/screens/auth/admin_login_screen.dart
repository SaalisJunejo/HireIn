import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: Email/Pass Login, 2: Mock 2FA Verification
  String _mock2FaCode = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle Credentials Verification
  Future<void> _verifyCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    final String email = _emailController.text.trim().toLowerCase();
    final String password = _passwordController.text;

    if (email == 'admin@hirein.com' && password == 'Admin@1234') {
      // Credentials correct! Generate mock 6-digit 2FA code
      final random = Random();
      _mock2FaCode = '${100000 + random.nextInt(900000)}';
      
      setState(() {
        _step = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghalat Admin email ya password! Double check karein.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _verify2Fa(String pin) async {
    if (pin == _mock2FaCode) {
      try {
        final success = await ref.read(authProvider.notifier).loginAdmin(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (!mounted) return;

        if (success) {
          context.go(AppRoutes.adminHome);
        } else {
          final errorMsg = ref.read(authProvider).error ?? 'Admin login failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
          );
        }
      } catch (e) {
        print('🚨 SILENT AUTH ERROR: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghalat 2FA Code! Dubara koshish karein.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_step > 1) {
              setState(() {
                _step--;
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 2FA Debug banner
            if (_step == 2 && _mock2FaCode.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xffFFF2CC),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, color: Color(0xffD68F00), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MOCK 2FA CODE: $_mock2FaCode',
                        style: const TextStyle(
                          color: Color(0xff7F6000),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildFormContent(authState.isLoading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isLoading) {
    if (_step == 1) {
      return Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('credentials_form'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.admin_panel_settings_outlined, size: 64, color: AppColors.gold),
            const SizedBox(height: 24),
            const Text(
              'Admin Terminal',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure administrator area. Please enter your terminal keys.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                hintText: 'admin@hirein.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.gold),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email likhna lazmi hai';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Ghalat email format';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Terminal Password',
                hintText: 'Admin@1234',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password likhna lazmi hai';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            
            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              onPressed: _verifyCredentials,
              child: const Text('Admin Keys Verify'),
            ),
          ],
        ),
      );
    } else {
      // 2FA Pin Entry Panel
      final defaultPinTheme = PinTheme(
        width: 48,
        height: 52,
        textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
      );

      final focusedPinTheme = defaultPinTheme.copyWith(
        decoration: defaultPinTheme.decoration!.copyWith(
          border: Border.all(color: AppColors.gold, width: 2),
        ),
      );

      return Column(
        key: const ValueKey('2fa_panel'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.security, size: 64, color: AppColors.gold),
          const SizedBox(height: 24),
          const Text(
            'Two-Factor Authentication',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the 6-digit mock security token shown in the debug banner above.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 40),
          
          Center(
            child: Pinput(
              length: 6,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              onCompleted: _verify2Fa,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 40),
          
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
        ],
      );
    }
  }
}
