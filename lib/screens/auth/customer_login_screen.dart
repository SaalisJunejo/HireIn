import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class CustomerLoginScreen extends ConsumerStatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  ConsumerState<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends ConsumerState<CustomerLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).loginCustomer(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (success) {
        context.go(AppRoutes.customerHome);
      } else {
        final errorMsg = ref.read(authProvider).error ?? 'Ghalat login credentials';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
    }
  }

  // Bottom Sheet reset password recovery flow
  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _ForgotPasswordBottomSheet(),
    );
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.gold),
                const SizedBox(height: 24),
                const Text(
                  'Khush Amdeed!',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apne customer account mein login karein.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 40),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: '03XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_android, color: AppColors.gold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mobile number likhna lazmi hai';
                    }
                    if (!RegExp(r'^03\d{9}$').hasMatch(value.trim())) {
                      return 'Ghalat format. Example: 03001234567';
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
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password likhna lazmi hai';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordSheet,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  onPressed: authState.isLoading ? null : _login,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                        )
                      : const Text('Login Karein'),
                ),
                const SizedBox(height: 24),
                
                // Sign Up Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Account nahi hai? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.pushReplacement(AppRoutes.customerRegister),
                      child: const Text(
                        'Register Karein',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Interactive Bottom Sheet for Forgot Password with mock OTP
class _ForgotPasswordBottomSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordBottomSheet();

  @override
  ConsumerState<_ForgotPasswordBottomSheet> createState() => _ForgotPasswordBottomSheetState();
}

class _ForgotPasswordBottomSheetState extends ConsumerState<_ForgotPasswordBottomSheet> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1; // 1: Phone, 2: OTP, 3: Password Reset
  String _mockOtp = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendMockOtp() {
    if (_phoneController.text.trim().isEmpty || !RegExp(r'^03\d{9}$').hasMatch(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid Pakistani phone number likhein'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    // Generate random 4 digits
    final random = Random();
    _mockOtp = '${random.nextInt(9000) + 1000}';
    
    setState(() {
      _step = 2;
    });
  }

  void _verifyOtp(String code) {
    if (code == _mockOtp) {
      setState(() {
        _step = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghalat OTP Code'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(authProvider.notifier).resetPassword(
            _phoneController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password successfully tabdeel ho gaya! Login karein.'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOffset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + keyboardOffset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner for Mock OTP
          if (_step == 2 && _mockOtp.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: const Color(0xffFFF2CC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report, color: Color(0xffD68F00), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'MOCK OTP: $_mockOtp',
                    style: const TextStyle(color: Color(0xff7F6000), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          
          _buildResetStep(),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password Reset',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apna registered mobile number likhein jahan OTP send kiya jaye.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_android, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: _sendMockOtp,
              child: const Text('Reset OTP Bhejein'),
            ),
          ],
        );
      case 2:
        final defaultPinTheme = PinTheme(
          width: 50,
          height: 50,
          textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
        );

        return Column(
          children: [
            const Text(
              'Code Likhein',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Hum ne ${_phoneController.text} par mock OTP bhej diya hai.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Pinput(
              length: 4,
              defaultPinTheme: defaultPinTheme,
              onCompleted: _verifyOtp,
              autofocus: true,
            ),
            const SizedBox(height: 24),
          ],
        );
      case 3:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Naya Password Set Karein',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Naya Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be min 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirm Naya Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.primary))
                    : const Text('Password Reset Karein'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
