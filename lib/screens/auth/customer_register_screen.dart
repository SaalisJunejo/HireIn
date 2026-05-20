import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class CustomerRegisterScreen extends ConsumerStatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  ConsumerState<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends ConsumerState<CustomerRegisterScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();

  int _currentStep = 1; // 1: Phone Input, 2: OTP Verify, 3: Profile Setup
  String _mockOtp = '';
  bool _phoneError = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Generates and shows Mock OTP
  void _sendMockOtp() {
    if (!_phoneFormKey.currentState!.validate()) return;
    
    // Generate random 4-digit OTP
    final random = Random();
    _mockOtp = '${random.nextInt(9000) + 1000}';

    setState(() {
      _currentStep = 2;
    });
  }

  // Auto-verify OTP entry
  void _verifyOtp(String code) {
    if (code == _mockOtp) {
      setState(() {
        _currentStep = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ghalat OTP Code! Dubara koshish karein.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_profileFormKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).registerCustomer(
            name: _nameController.text.trim().isEmpty ? 'Guest User' : _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (success) {
        context.go(AppRoutes.customerHome);
      } else {
        final errorMsg = ref.read(authProvider).error ?? 'Registration failed. Try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() {
                _currentStep--;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: const Text('Customer Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mock OTP Debug Banner
            if (_currentStep == 2 && _mockOtp.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xffFFF2CC),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report, color: Color(0xffD68F00), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'MOCK OTP: $_mockOtp',
                        style: const TextStyle(
                          color: Color(0xff7F6000),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
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
                child: _buildStepContent(authState.isLoading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isLoading) {
    switch (_currentStep) {
      case 1:
        return _buildPhoneInputStep(isLoading);
      case 2:
        return _buildOtpVerificationStep(isLoading);
      case 3:
        return _buildProfileSetupStep(isLoading);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Phone Entry Screen
  Widget _buildPhoneInputStep(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        key: const ValueKey('phone_step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apna Phone Number Likhein',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hum aapko verify karne ke liye ek mock OTP code bhejein ge.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Mobile Number',
              hintText: '03XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_android, color: AppColors.gold),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number likhna lazmi hai';
              }
              final clean = value.trim();
              if (!RegExp(r'^03\d{9}$').hasMatch(clean)) {
                return 'Ghalat format. Example: 03001234567';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: isLoading ? null : _sendMockOtp,
            child: const Text('OTP Send Karo'),
          ),
        ],
      ),
    );
  }

  // STEP 2: OTP Box Screen
  Widget _buildOtpVerificationStep(bool isLoading) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.gold, width: 2),
      ),
    );

    return Column(
      key: const ValueKey('otp_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Hum ne ${_phoneController.text} par code bhej diya hai.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 40),
        Center(
          child: Pinput(
            length: 4,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
            onCompleted: _verifyOtp,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 40),
        Center(
          child: TextButton(
            onPressed: _sendMockOtp,
            child: const Text(
              'Code dobara bhejein',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: Password & Profile Creation Screen
  Widget _buildProfileSetupStep(bool isLoading) {
    return Form(
      key: _profileFormKey,
      child: Column(
        key: const ValueKey('profile_step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apna Profile Banayein',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Account password set karein aur apna naam likhein.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Full Name (Optional)
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Aap ka Naam (Optional)',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 20),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Password Set Karein',
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password kam az kam 6 characters ka hona chahiye';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.gold),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords aapas mein nahi mil rahe';
              }
              return null;
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: isLoading ? null : _submitRegistration,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                  )
                : const Text('Account Banayein'),
          ),
        ],
      ),
    );
  }
}
