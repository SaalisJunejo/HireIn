import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';
import '../../providers/provider_provider.dart';
import '../../core/utils/helpers.dart';
import '../../services/local_database.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ReviewScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Selected positive chips (green)
  final Set<String> _selectedPositiveChips = {};
  
  // Selected negative chips (red)
  final Set<String> _selectedNegativeChips = {};

  final List<String> _positiveChips = [
    "Affordable 💚", 
    "On Time ⏰", 
    "Professional 👍", 
    "Quality Work ⭐", 
    "Friendly 😊"
  ];

  final List<String> _negativeChips = [
    "Expensive 💸", 
    "Late ❌", 
    "Unprofessional 👎", 
    "Poor Quality 😞"
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() {
      _isSubmitting = true;
    });

    final comment = _commentController.text.trim();
    final List<String> positiveBadges = _selectedPositiveChips.toList();
    final List<String> negativeTags = _selectedNegativeChips.toList();

    try {
      // Local Update directly to LocalDatabase
      final bookingData = LocalDatabase.instance.get('bookings', widget.bookingId);
      if (bookingData != null) {
        bookingData['rating'] = _selectedRating;
        bookingData['reviewComment'] = comment;
        bookingData['completedAt'] = DateTime.now().toIso8601String();
        await LocalDatabase.instance.put('bookings', widget.bookingId, bookingData);

        final providerId = bookingData['providerId'] as String;
        final providerData = LocalDatabase.instance.get('providers', providerId);
        
        if (providerData != null) {
          final currentBadges = List<String>.from(providerData['badges'] ?? []);
          final currentNegative = List<String>.from(providerData['negativeTags'] ?? []);
          
          for (var b in positiveBadges) {
            if (!currentBadges.contains(b)) currentBadges.add(b);
          }
          for (var t in negativeTags) {
            if (!currentNegative.contains(t)) currentNegative.add(t);
          }
          
          providerData['badges'] = currentBadges;
          providerData['negativeTags'] = currentNegative;
          
          await LocalDatabase.instance.put('providers', providerId, providerData);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Review Submit Ho Gaya! Shukriya.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.customerHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review submission failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockProviders = ref.read(mockProvidersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Rate Your Service',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Builder(
        builder: (context) {
          final data = LocalDatabase.instance.get('bookings', widget.bookingId);
          
          if (data == null) {
            return const Center(child: Text('Booking details load karne mein masla hua.', style: TextStyle(color: Colors.white)));
          }

          final providerId = data['providerId'] ?? '';
          final service = data['service'] ?? 'AC Technician';

          // Resolve provider
          final provider = mockProviders.firstWhere(
            (p) => p.id == providerId,
            orElse: () => ProviderModel(
              id: providerId,
              name: 'Hamza AC Tech',
              phone: '',
              password: '',
              category: service,
              skillLevel: 'Expert',
              cnicImageUrl: '',
              approvalStatus: 'approved',
              lat: 25.3960,
              lng: 68.3578,
              areaName: 'Qasimabad',
              rating: 4.8,
              reviewCount: 20,
              onTimeScore: 0.95,
              cancellationRate: 0.05,
              riskScore: 0.0,
              badges: const [],
              negativeTags: const [],
              shifts: const [],
              baseRatePkr: 400,
              pkrPerKm: 60,
              urgentSurcharge: 100,
              weeklyEarningsPending: 0.0,
              isOnline: true,
              currentLat: 25.3960,
              currentLng: 68.3578,
              createdAt: DateTime.now(),
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header details
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.gold.withOpacity(0.12),
                        child: Text(
                          provider.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.category,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Stars row
                const Center(
                  child: Text(
                    'Aap ka experience kaisa raha?',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starRating = index + 1;
                    final isSelected = starRating <= _selectedRating;

                    return IconButton(
                      icon: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        color: AppColors.gold,
                        size: 38,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedRating = starRating;
                        });
                      },
                    ).animate(target: isSelected ? 1.0 : 0.0)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms, curve: Curves.easeOutBack);
                  }),
                ),
                const SizedBox(height: 32),

                // Positive badges chip section
                const Text(
                  'Provider kaisa tha? (Select Badges)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _positiveChips.map((chip) {
                    final selected = _selectedPositiveChips.contains(chip);
                    return ChoiceChip(
                      label: Text(
                        chip,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.green,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      side: BorderSide(color: Colors.green.withOpacity(selected ? 1.0 : 0.4)),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPositiveChips.add(chip);
                          } else {
                            _selectedPositiveChips.remove(chip);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Negative chips section
                const Text(
                  'Koi shikayat? (Select Flags)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _negativeChips.map((chip) {
                    final selected = _selectedNegativeChips.contains(chip);
                    return ChoiceChip(
                      label: Text(
                        chip,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.redAccent,
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      side: BorderSide(color: Colors.redAccent.withOpacity(selected ? 1.0 : 0.4)),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedNegativeChips.add(chip);
                          } else {
                            _selectedNegativeChips.remove(chip);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Feedback comments field
                const Text(
                  'Kuch aur kehna chahte hain?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    hintText: 'Apna feedback share karein...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 40),

                // Button submit
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: AppColors.secondary,
                  ),
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Submitting Review...', style: TextStyle(color: AppColors.primary)),
                          ],
                        )
                      : const Text('Review Submit Karo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
