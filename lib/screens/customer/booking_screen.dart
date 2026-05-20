import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/provider_model.dart';
import '../../models/booking_model.dart';
import '../../core/utils/helpers.dart';

enum CheckoutStep { timeSlotSelection, paymentScreen, confirmationScreen }

class BookingScreen extends ConsumerStatefulWidget {
  final ProviderModel provider;
  final bool isUrgent;
  final double userLat;
  final double userLng;
  final String userArea;

  const BookingScreen({
    super.key,
    required this.provider,
    required this.isUrgent,
    required this.userLat,
    required this.userLng,
    required this.userArea,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  CheckoutStep _currentStep = CheckoutStep.timeSlotSelection;
  bool _isToday = true;
  String? _selectedSlot;
  bool _isProcessingLock = false;
  bool _isProcessingPayment = false;
  String _generatedBookingId = '';
  
  // Easypaisa/Jazzcash phone pre-filled
  final TextEditingController _phoneController = TextEditingController();

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
          cos(lat1 * p) * cos(lat2 * p) * 
          (1 - cos((lng2 - lng1) * p))/2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Pricing calculations
  double get distance {
    final double pLat = widget.isUrgent ? widget.provider.currentLat : widget.provider.lat;
    final double pLng = widget.isUrgent ? widget.provider.currentLng : widget.provider.lng;
    return _calculateDistance(pLat, pLng, widget.userLat, widget.userLng);
  }

  double get baseFee => widget.provider.baseRatePkr.toDouble() > 200.0 ? 200.0 : widget.provider.baseRatePkr.toDouble();
  double get travelFee => max(50.0, (distance * widget.provider.pkrPerKm).roundToDouble());
  double get surcharge => widget.isUrgent ? 100.0 : 0.0;
  double get platformFee {
    final subtotal = baseFee + travelFee + surcharge;
    return (subtotal / 9.0).roundToDouble();
  }
  double get totalFee => baseFee + travelFee + platformFee + surcharge;

  // Time Slots Definitions
  final List<String> _timeSlots = [
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];

  // Mock Booked status (randomized on init for realistic feeling)
  final Set<String> _todayBookedSlots = {};
  final Set<String> _tomorrowBookedSlots = {};

  @override
  void initState() {
    super.initState();
    // Pre-populate mobile from authenticated user if available
    final user = ref.read(authProvider).currentUser;
    if (user != null) {
      _phoneController.text = user.phone;
    }

    // Mark random slot as booked for realism
    final rand = Random();
    _todayBookedSlots.add(_timeSlots[rand.nextInt(_timeSlots.length)]);
    _tomorrowBookedSlots.add(_timeSlots[rand.nextInt(_timeSlots.length)]);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _hasTriggeredConflict = false;

  // SCREEN 1 -> 2: Lock Booking
  Future<void> _lockAndProceed() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingLock = true;
    });

    // Simulate Agent 6 (LockBooking) Cloud Function negotiation & verification
    await Future.delayed(const Duration(milliseconds: 1500));

    // SCENARIO 3: Double Booking Conflict Demo
    if (!_hasTriggeredConflict) {
      setState(() {
        _isProcessingLock = false;
        _hasTriggeredConflict = true; // pass on next attempt
      });
      _showConflictDialog();
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessingLock = false;
        _currentStep = CheckoutStep.paymentScreen;
      });
    }
  }

  void _showConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final altSlots = _timeSlots.where((s) => s != _selectedSlot && !_todayBookedSlots.contains(s)).take(3).toList();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('⚠️ Yeh slot abhi kisi ne book kar liya!', style: TextStyle(color: Colors.white, fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yeh slot kisi aur customer ne last 10 seconds mein lock kar liya hai. Neechay diye gaye slots mein se koi select karein:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              ...altSlots.map((slot) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedSlot = slot;
                    });
                    Navigator.of(ctx).pop();
                    _lockAndProceed(); // Retry locking with new slot
                  },
                  child: Text(slot, style: const TextStyle(color: AppColors.gold)),
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  // SCREEN 2 -> 3: Process Payment
  Future<void> _processMockPayment() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valid mobile number likhein.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Simulate 2-second Easypaisa transaction pipeline
      await Future.delayed(const Duration(seconds: 2));

      final user = ref.read(authProvider).currentUser;
      if (user == null) return;

      // Generate random BK-XXXX
      final randomNum = 1000 + Random().nextInt(9000);
      _generatedBookingId = 'BK-$randomNum';

      // Commit actual booking record directly to Firestore with 'booked' and 'paid'
      final scheduledDateTime = DateTime.now().add(
        Duration(days: _isToday ? 0 : 1, hours: 2),
      );

      final newBooking = BookingModel(
        bookingId: _generatedBookingId,
        customerId: user.id,
        providerId: widget.provider.id,
        service: widget.provider.category,
        customerLat: widget.userLat,
        customerLng: widget.userLng,
        customerAreaName: widget.userArea,
        scheduledAt: scheduledDateTime,
        status: 'booked',
        isUrgent: widget.isUrgent,
        pricingBreakdown: {
          'baseFee': baseFee,
          'travelFee': travelFee,
          'urgentSurcharge': surcharge,
          'platformFee': platformFee,
          'total': totalFee,
        },
        distanceKm: distance,
        paymentStatus: 'paid', // Mark as paid!
        createdAt: DateTime.now(),
        customerBadges: const ['Top Rated Customer'],
        agentLogs: {
          'BookingAgent': 'Locked scheduled slot: $_selectedSlot. Transaction approved via mock payment provider.',
        },
      );

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.createBooking(newBooking);

      HapticFeedback.mediumImpact();

      if (mounted) {
        setState(() {
          _currentStep = CheckoutStep.confirmationScreen;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking write failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case CheckoutStep.timeSlotSelection:
        return 'Select Time Slot';
      case CheckoutStep.paymentScreen:
        return 'Easypaisa / JazzCash Checkout';
      case CheckoutStep.confirmationScreen:
        return 'Order Confirmed';
    }
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case CheckoutStep.timeSlotSelection:
        return _buildTimeSlotSelector();
      case CheckoutStep.paymentScreen:
        return _buildPaymentScreen();
      case CheckoutStep.confirmationScreen:
        return _buildConfirmationScreen();
    }
  }

  // --- SCREEN 1: TIME SLOT SELECTOR ---
  Widget _buildTimeSlotSelector() {
    final bookedSet = _isToday ? _todayBookedSlots : _tomorrowBookedSlots;

    return SingleChildScrollView(
      key: const ValueKey('timeslot_selection'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Provider Mini Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gold.withOpacity(0.12),
                  child: Text(
                    widget.provider.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.provider.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('${widget.provider.category} • ⭐ ${widget.provider.rating}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  'PKR ${widget.provider.baseRatePkr > 200 ? 200 : widget.provider.baseRatePkr}',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Waqt chuniye date selector
          const Text('Waqt chuniye (Select Date & Time)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          // Today & Tomorrow Tab options
          Row(
            children: [
              Expanded(child: _buildDateTab('Today', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildDateTab('Tomorrow', false)),
            ],
          ),
          const SizedBox(height: 20),

          // Time chips Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _timeSlots.map((slot) {
              final isBooked = bookedSet.contains(slot);
              final isSelected = _selectedSlot == slot;
              
              Color chipColor = Colors.green.withOpacity(0.1);
              Color textColor = Colors.green;
              BorderSide border = BorderSide(color: Colors.green.withOpacity(0.4));

              if (isBooked) {
                chipColor = Colors.white.withOpacity(0.03);
                textColor = Colors.white24;
                border = const BorderSide(color: Colors.white10);
              } else if (isSelected) {
                chipColor = AppColors.gold;
                textColor = AppColors.primary;
                border = const BorderSide(color: AppColors.gold);
              }

              return InkWell(
                onTap: isBooked ? null : () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.fromBorderSide(border),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Price Breakdown
          const Text('Price Breakdown', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buildPriceRow('Base Visit Fee', baseFee),
                _buildPriceRow('Travel Allowance', travelFee),
                if (widget.isUrgent) _buildPriceRow('Urgent Surcharge', surcharge, isSurcharge: true),
                _buildPriceRow('Platform Charges', platformFee),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total PKR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'PKR ${totalFee.toStringAsFixed(0)}',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 36),

          // Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.secondary,
            ),
            onPressed: _isProcessingLock ? null : _lockAndProceed,
            child: _isProcessingLock 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Locking Appointment...', style: TextStyle(color: AppColors.primary)),
                    ],
                  )
                : const Text('Payment Karo'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab(String label, bool today) {
    final active = _isToday == today;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isToday = today;
          _selectedSlot = null; // reset selected
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.gold : Colors.white.withOpacity(0.05)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primary : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, {bool isSurcharge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            'PKR ${price.toStringAsFixed(0)}',
            style: TextStyle(
              color: isSurcharge ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 2: MOCK PAYMENT SCREEN (Easypaisa Style) ---
  Widget _buildPaymentScreen() {
    return Container(
      key: const ValueKey('payment_screen'),
      color: const Color(0xff004D40), // Easypaisa iconic dark teal-green
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo header mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'easypaisa',
                style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
                child: const Text('Secured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'Mobile Account Number',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              hintText: '03XX-XXXXXXX',
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: const Icon(Icons.phone_android, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Payable Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'PKR ${totalFee.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          
          const Spacer(),

          // Pay Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: Colors.greenAccent,
              foregroundColor: const Color(0xff004D40),
            ),
            onPressed: _isProcessingPayment ? null : _processMockPayment,
            child: _isProcessingPayment
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xff004D40), strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Processing payment...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                : Text(
                    'Pay PKR ${totalFee.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _currentStep = CheckoutStep.timeSlotSelection;
                });
              },
              child: const Text('Cancel Payment', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: BOOKING CONFIRMATION ---
  Widget _buildConfirmationScreen() {
    return SingleChildScrollView(
      key: const ValueKey('confirmation_screen'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Large checkmark pulse animation
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 50),
          ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),

          const SizedBox(height: 24),
          const Text(
            'Booking Ho Gayi!',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aapka order kamyabi se locked aur payment done hai.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Booking ID card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('Booking ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                Text(
                  _generatedBookingId,
                  style: const TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Provider info summary
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withOpacity(0.12),
              child: Text(
                widget.provider.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(widget.provider.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('${widget.provider.category} • Slot: $_selectedSlot', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          const SizedBox(height: 12),

          // Price Expansion breakdown
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Itemized Price Breakdown', style: TextStyle(color: AppColors.gold, fontSize: 13)),
              tilePadding: EdgeInsets.zero,
              children: [
                _buildPriceRow('Base Visit Fee', baseFee),
                _buildPriceRow('Travel Allowance', travelFee),
                if (widget.isUrgent) _buildPriceRow('Urgent Surcharge', surcharge, isSurcharge: true),
                _buildPriceRow('Platform Charges', platformFee),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          // Dynamic Stepper route buttons
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.secondary),
            onPressed: () {
              // Navigate to Active Job screen and pass the generated Booking ID!
              context.go(AppRoutes.customerHome + '/active-job', extra: _generatedBookingId);
            },
            child: const Text('Active Job Dekho'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: Colors.white10),
              foregroundColor: Colors.white70,
            ),
            onPressed: () => context.go(AppRoutes.customerHome),
            child: const Text('Home Jao'),
          ),
        ],
      ),
    );
  }
}
