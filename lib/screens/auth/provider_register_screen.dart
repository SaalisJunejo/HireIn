import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProviderRegisterScreen extends ConsumerStatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  ConsumerState<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends ConsumerState<ProviderRegisterScreen> {
  int _currentStep = 1; // Steps: 1 (Phone), 2 (OTP), 3 (Name & Pass), 4 (Category), 5 (Address & CNIC), 6 (Success)
  
  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();

  final _phoneFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();

  String _mockOtp = '';
  String _selectedCategory = '';
  Uint8List? _cnicImageBytes;
  String? _cnicImageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Generate Mock OTP
  void _sendMockOtp() {
    if (!_phoneFormKey.currentState!.validate()) return;
    final random = Random();
    _mockOtp = '${random.nextInt(9000) + 1000}';
    setState(() {
      _currentStep = 2;
    });
  }

  // Verify OTP
  void _verifyOtp(String code) {
    if (code == _mockOtp) {
      setState(() {
        _currentStep = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghalat OTP. Dubara koshish karein.'), backgroundColor: AppColors.error),
      );
    }
  }

  // Pick CNIC Image (Web-compatible using bytes)
  Future<void> _pickCnic(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _cnicImageBytes = bytes;
          _cnicImageName = image.name;
        });
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CNIC scan nahi ho sakti: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // Step Navigations
  void _submitProfile() {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() {
      _currentStep = 4;
    });
  }

  void _selectCategoryAndNext(String category) {
    setState(() {
      _selectedCategory = category;
      _currentStep = 5;
    });
  }

  Future<void> _submitApplication() async {
    if (!_addressFormKey.currentState!.validate()) return;

    try {
      final success = await ref.read(authProvider.notifier).registerProvider(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            category: _selectedCategory,
            address: _addressController.text.trim(),
            cnicImagePath: _cnicImageName ?? 'mock_cnic_uploaded.jpg',
          );

      if (!mounted) return;

      if (success) {
        setState(() {
          _currentStep = 6;
        });
      } else {
        final errorMsg = ref.read(authProvider).error ?? 'Application submission failed.';
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
        leading: _currentStep < 6
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (_currentStep > 1) {
                    setState(() {
                      _currentStep--;
                    });
                  } else {
                    context.pop();
                  }
                },
              )
            : null,
        title: Text(
          _currentStep == 6 ? 'Congratulations!' : 'Provider Registration',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // OTP Banner
            if (_currentStep == 2 && _mockOtp.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0xffFFF2CC),
                child: Center(
                  child: Text(
                    'MOCK OTP: $_mockOtp',
                    style: const TextStyle(color: Color(0xff7F6000), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                  ),
                ),
              ),

            // Stepper Indicator (Hide on success page)
            if (_currentStep < 6) _buildStepProgressIndicator(),

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

  // Stepper UI Indicator
  static const List<String> _stepLabels = ['Phone', 'OTP', 'Profile', 'Skill', 'CNIC'];

  Widget _buildStepProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (index) {
          final stepNum = index + 1;
          final bool isDone = _currentStep > stepNum;
          final bool isCurrent = _currentStep == stepNum;
          
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? Colors.green
                            : (isCurrent ? AppColors.gold : Colors.white.withOpacity(0.1)),
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : Text(
                                '$stepNum',
                                style: TextStyle(
                                  color: isCurrent || isDone ? AppColors.primary : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[index],
                      style: TextStyle(
                        color: isDone ? Colors.green : (isCurrent ? AppColors.gold : Colors.white38),
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      color: _currentStep > stepNum ? Colors.green : Colors.white.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          );
        }),
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
      case 4:
        return _buildCategorySelectionStep();
      case 5:
        return _buildAddressCnicStep(isLoading);
      case 6:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Phone number
  Widget _buildPhoneInputStep(bool isLoading) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apna Kam Shuru Karein', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Apna active mobile number enter karein jahan SMS OTP mock bheja ja sake.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
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
              if (value == null || value.trim().isEmpty) return 'Mobile number likhna lazmi hai';
              if (!RegExp(r'^03\d{9}$').hasMatch(value.trim())) return 'Ghalat format. Example: 03001234567';
              return null;
            },
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: _sendMockOtp,
            child: const Text('OTP Send Karo'),
          ),
        ],
      ),
    );
  }

  // STEP 2: OTP boxes
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('OTP Verification', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Verify karein, hum ne ${_phoneController.text} par mock code bheja hai.', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 40),
        Center(
          child: Pinput(
            length: 4,
            defaultPinTheme: defaultPinTheme,
            onCompleted: _verifyOtp,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // STEP 3: Password + Name
  Widget _buildProfileSetupStep(bool isLoading) {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Setup', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Apna Poora Naam',
              prefixIcon: Icon(Icons.person, color: AppColors.gold),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Naam likhna lazmi hai' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Password Set Karein',
              prefixIcon: Icon(Icons.lock, color: AppColors.gold),
            ),
            validator: (value) => value == null || value.length < 6 ? 'Password kam az kam 6 characters ka hona chahiye' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock, color: AppColors.gold),
            ),
            validator: (value) => value != _passwordController.text ? 'Passwords match nahi horahay' : null,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: _submitProfile,
            child: const Text('Agla Step'),
          ),
        ],
      ),
    );
  }

  // STEP 4: Category grid
  Widget _buildCategorySelectionStep() {
    final List<Map<String, dynamic>> categoryCards = [
      {'name': 'AC Technician', 'icon': Icons.ac_unit},
      {'name': 'Plumber', 'icon': Icons.water_drop},
      {'name': 'Electrician', 'icon': Icons.electrical_services},
      {'name': 'Carpenter', 'icon': Icons.handyman},
      {'name': 'Mechanic', 'icon': Icons.construction},
      {'name': 'Painter', 'icon': Icons.format_paint},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Apni Skill Select Karein', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Aap kis category mein expert hain?', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categoryCards.length,
          itemBuilder: (context, index) {
            final card = categoryCards[index];
            final String name = card['name'];
            final IconData icon = card['icon'];
            
            return GestureDetector(
              onTap: () => _selectCategoryAndNext(name),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 40, color: AppColors.gold),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 5: Address and CNIC image upload
  Widget _buildAddressCnicStep(bool isLoading) {
    return Form(
      key: _addressFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skills & Verification', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Address Input
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Apna Mukamil Address',
              prefixIcon: Icon(Icons.location_on, color: AppColors.gold),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Address enter karna lazmi hai' : null,
          ),
          const SizedBox(height: 32),
          
          // CNIC scanner mock
          const Text('CNIC Scanning / Image Upload', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Apne CNIC card ki picture upload karein (Front side).', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.surface,
                builder: (context) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt, color: AppColors.gold),
                        title: const Text('Camera se capture karein', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          context.pop();
                          _pickCnic(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library, color: AppColors.gold),
                        title: const Text('Gallery se select karein', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          context.pop();
                          _pickCnic(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1, style: BorderStyle.solid),
              ),
              child: _cnicImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_cnicImageBytes!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 50, color: AppColors.gold),
                        SizedBox(height: 12),
                        Text('Photo Attach Karein (Camera / Gallery)', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
            onPressed: isLoading ? null : _submitApplication,
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.primary))
                : const Text('Application Submit Karein'),
          ),
        ],
      ),
    );
  }

  // STEP 6: Success Page — shows "Pending" state clearly
  Widget _buildSuccessStep() {
    return Column(
      key: const ValueKey('success_step'),
      children: [
        const SizedBox(height: 20),
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.15),
          ),
          child: const Icon(Icons.hourglass_top_rounded, size: 56, color: Colors.orange),
        ),
        const SizedBox(height: 24),
        const Text(
          'Application Submit Ho Gayi!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '⏳ STATUS: PENDING APPROVAL',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Admin jaldi hi aapki details verify karay ga. Verification complete honay par aap ko notify kiya jay ga.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Meharbani — Aap yahan ruk kar wait karein ya phir baad mein login karein.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          onPressed: () => context.go(AppRoutes.splash),
          child: const Text('Welcome Screen par Jayein'),
        ),
      ],
    );
  }
}
