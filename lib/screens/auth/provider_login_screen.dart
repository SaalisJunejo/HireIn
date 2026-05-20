import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProviderLoginScreen extends ConsumerStatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  ConsumerState<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends ConsumerState<ProviderLoginScreen> {
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
      final status = await ref.read(authProvider.notifier).loginProvider(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (status == 'approved') {
        context.go(AppRoutes.providerHome);
      } else if (status == 'pending') {
        _showPendingDialog();
      } else if (status == 'rejected') {
        _showRejectedDialog('Ghalat CNIC images ya incomplete address info.');
      } else if (status == 'error') {
        final errorMsg = ref.read(authProvider).error ?? 'Ghalat login details';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
    }
  }

  // Pending Modal Dialog
  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.watch_later_outlined, size: 54, color: AppColors.gold),
        title: const Text('Application Review Mein Hai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Aap ki application abhi processing mein hai. Admin jaldi hi verification mukamil kare ga aur aap ka account active ho jaye ga.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.primary),
              onPressed: () => context.pop(),
              child: const Text('Theek Hai'),
            ),
          ),
        ],
      ),
    );
  }

  // Rejected Modal Dialog
  void _showRejectedDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.cancel_outlined, size: 54, color: AppColors.error),
        title: const Text('Application Rejected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Afsos! Aapki registration form request accept nahi hui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                'Wajah: $reason',
                style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
              onPressed: () => context.pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
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
                const Icon(Icons.handyman_outlined, size: 64, color: AppColors.gold),
                const SizedBox(height: 24),
                const Text(
                  'Hunar Mand Partner!',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apne partner account mein login kar ke orders hasil karein.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                
                const SizedBox(height: 12),
                // Helper Demo Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo Tips:\n• Register an account to view PENDING application state.\n• Login using "+9231234561" to log in with an APPROVED account.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
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
                    if (!RegExp(r'^03\d{9}$').hasMatch(value.trim()) && !value.startsWith('+92')) {
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
                      return 'Password enter karein';
                    }
                    return null;
                  },
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
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Partner account nahi hai? ', style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.pushReplacement(AppRoutes.providerRegister),
                      child: const Text(
                        'Join Karein',
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
