import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  Widget _buildMockMap() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.background,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle grid/dot pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: GridPaper(
                color: AppColors.gold,
                interval: 40.0,
                divisions: 2,
              ),
            ),
          ),

          // Glowing radar scan effect
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withOpacity(0.15), width: 1),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(duration: 3.seconds, begin: Offset(0.2, 0.2), end: Offset(1.2, 1.2), curve: Curves.easeOut)
             .fadeOut(duration: 3.seconds),
          ),
          
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(duration: 3.seconds, delay: 1.seconds, begin: Offset(0.2, 0.2), end: Offset(1.2, 1.2), curve: Curves.easeOut)
             .fadeOut(duration: 3.seconds),
          ),

          // Central pulsing glow
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.15),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 1.5.seconds, begin: Offset(0.8, 0.8), end: Offset(1.3, 1.3), curve: Curves.easeInOut),
          ),

          // Centered Live Location Pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.gold,
                  size: 40,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .slideY(duration: 1.seconds, begin: 0.0, end: -0.15),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Hyder Chowk (G-13)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mock nearby provider pins
          Positioned(
            left: 60,
            top: 70,
            child: _buildMockProviderPin('Ali Ahmed', 'AC Tech'),
          ),
          Positioned(
            right: 80,
            top: 100,
            child: _buildMockProviderPin('Zahid Khan', 'Plumber'),
          ),
          Positioned(
            left: 90,
            bottom: 60,
            child: _buildMockProviderPin('Muhammad Ali', 'Electrician'),
          ),

          // Location simulation badge (Top Left)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .fadeOut(duration: 800.ms),
                  const SizedBox(width: 6),
                  const Text(
                    'Live Location Tracking (Simulation)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockProviderPin(String name, String specialty) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.engineering,
            color: AppColors.primary,
            size: 14,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$name\n($specialty)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bookingsAsync = ref.watch(customerBookingsProvider);
    
    final user = authState.currentUser;
    final userName = user?.name ?? 'Customer';

    // Parse active vs completed bookings
    List<BookingModel> activeBookings = [];
    List<BookingModel> pastBookings = [];

    bookingsAsync.whenData((bookings) {
      activeBookings = bookings.where((b) => b.status != 'completed' && b.status != 'cancelled').toList();
      pastBookings = bookings.where((b) => b.status == 'completed' || b.status == 'cancelled').toList();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar + Safe Area spacing
              _buildTopBar(userName),
              
              // Google Map Panel replaced with Mock Map (~45% height)
              Expanded(
                flex: 45,
                child: _buildMockMap(),
              ),
              
              // Quick Service Chips Scroll
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Humse Kya Chahiye Aaj?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildServiceChipsRow(),

              // Past Bookings Section
              Expanded(
                flex: 30,
                child: bookingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Bookings fetch fails: \$err', style: const TextStyle(color: Colors.red)),
                  ),
                  data: (bookings) {
                    if (pastBookings.isEmpty) {
                      return _buildEmptyBookingsWidget();
                    }
                    return _buildPastBookingsSection(pastBookings);
                  },
                ),
              ),
              
              // Spacing for floating search bar
              const SizedBox(height: 90),
            ],
          ),

          // Pulsing Active Booking Banner (Floating above Map/Chips)
          if (activeBookings.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 180,
              child: _buildActiveBookingBanner(activeBookings.first),
            ),

          // Floating Search Bar & Navigation Panel (Bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchField(),
                _buildBottomNav(user?.mode == 'provider'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildTopBar(String name) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HireIn',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showProfileSheet(context, name);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.gold, size: 14),
              const SizedBox(width: 4),
              Text(
                'Hyderabad, Sindh',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingBanner(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.customerActiveJob, extra: booking.bookingId);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xffFFF2CC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on, color: Color(0xffD68F00), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Active Job: ${booking.service}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Status: ${booking.status.toUpperCase()} • View Tracking",
                    style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.gold, size: 16),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .custom(
         duration: 1500.ms,
         builder: (context, value, child) => Container(
           decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(14),
             boxShadow: [
               BoxShadow(
                 color: AppColors.gold.withOpacity(value * 0.25),
                 blurRadius: 8 + value * 8,
                 spreadRadius: value * 2,
               ),
             ],
           ),
           child: child,
         ),
       ),
    );
  }

  Widget _buildServiceChipsRow() {
    final services = [
      {'label': 'AC Technician', 'icon': Icons.ac_unit},
      {'label': 'Plumber', 'icon': Icons.water_drop},
      {'label': 'Electrician', 'icon': Icons.electrical_services},
      {'label': 'Carpenter', 'icon': Icons.handyman},
      {'label': 'Mechanic', 'icon': Icons.build},
      {'label': 'Painter', 'icon': Icons.format_paint},
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              avatar: Icon(service['icon'] as IconData, color: AppColors.gold, size: 16),
              label: Text(
                service['label'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                context.push(AppRoutes.customerRequest, extra: service['label'] as String);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPastBookingsSection(List<BookingModel> pastBookings) {
    final previewList = pastBookings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pichli Bookings',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sari bookings preview loaded below!')),
                  );
                },
                child: const Text(
                  'Sab Dekho',
                  style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: previewList.length,
            itemBuilder: (context, index) {
              final booking = previewList[index];
              return _buildPastBookingCard(booking);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPastBookingCard(BookingModel booking) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  booking.service == 'AC Technician' ? Icons.ac_unit : Icons.settings_suggest,
                  color: AppColors.gold,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.service,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.bookingId,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total: ${booking.pricingBreakdown['total'] ?? 0} PKR",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status == 'completed' 
                      ? AppColors.success.withOpacity(0.2)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status.toUpperCase(),
                  style: TextStyle(
                    color: booking.status == 'completed' ? AppColors.success : Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBookingsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.15), size: 40),
          const SizedBox(height: 8),
          Text(
            'Koi pichli bookings nahi hain.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.customerRequest),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Kya chahiye aaj? (AC, Plumber...)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.gold),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool showSwitchToProvider) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true, onTap: () {}),
          _buildNavItem(Icons.book_online, 'Bookings', false, onTap: () {
            context.push(AppRoutes.customerBookingHistory);
          }),
          _buildNavItem(Icons.smart_toy_outlined, 'Agent Logs', false, onTap: () {
            context.push(AppRoutes.agentLogs);
          }),
          if (showSwitchToProvider)
            _buildNavItem(Icons.sync_alt, 'Switch Mode', false, onTap: () {
              ref.read(authProvider.notifier).logout(); // Easy swap for mockup evaluation
              context.go(AppRoutes.splash);
            }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\$label screen preview selected')),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.gold : Colors.white.withOpacity(0.4), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.gold : Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.splash);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOGS / INTERACTIVE OVERLAYS ---

  void _triggerServiceRequestInput(String prefilledService) {
    final searchController = TextEditingController(text: prefilledService);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'AI Service Matchmaker',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Describe what you need in plain English or Roman Urdu, e.g. "AC repair urgent chahiye Qasimabad me"',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Describe your service requirements...',
                  prefixIcon: Icon(Icons.bolt, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.secondary,
                ),
                onPressed: () {
                  final text = searchController.text.trim();
                  Navigator.pop(context);
                  if (text.isNotEmpty) {
                    _startAiQueryProcessing(text);
                  }
                },
                child: const Text('Find Smart Match'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startAiQueryProcessing(String query) async {
    // Start Riverpod AI Search
    final notifier = ref.read(aiAgentQueryStateProvider.notifier);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: Card(
            color: AppColors.surface,
            margin: EdgeInsets.all(24),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.gold),
                  SizedBox(height: 20),
                  Text(
                    'AI Matchmaker Engine Running...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Extracting intent & pricing bids...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Trigger Riverpod provider
    await notifier.searchServices(query);
    
    if (mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      _showAiResultDialog();
    }
  }

  void _showAiResultDialog() {
    final searchState = ref.read(aiAgentQueryStateProvider);

    searchState.when(
      data: (result) {
        if (result == null) return;
        
        if (result.rankedProviders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Koi matching providers nahi mile.')),
          );
          return;
        }
        final winner = result.rankedProviders.first;
        final thoughtProcess = result.thoughtProcess;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.gold),
                  SizedBox(width: 8),
                  Text('Perfect Match Found!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${winner.category} • ${winner.skillLevel.toUpperCase()} LEVEL',
                    style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    thoughtProcess,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                    onPressed: () {
                      Navigator.pop(context);
                      _bookMatchedProvider(winner);
                    },
                    child: const Text('Book Now'),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () {},
      error: (e, s) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error resolving AI match: $e"), backgroundColor: AppColors.error),
        );
      },
    );
  }

  Future<void> _bookMatchedProvider(ProviderModel provider) async {
    final authState = ref.read(authProvider);
    final user = authState.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );

    try {
      await ref.read(bookingOperationsProvider).bookNewService(
        provider: provider,
        customerId: user.id,
        service: provider.category,
        lat: _currentPosition?.latitude ?? 25.3960,
        lng: _currentPosition?.longitude ?? 68.3578,
        area: provider.areaName,
        price: provider.baseRatePkr.toDouble(),
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss booking loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking BK-XXXX created successfully! En route initiated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showBookingDetailModal(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking Detail: ${booking.bookingId}",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text("Service: ${booking.service}", style: const TextStyle(color: Colors.white70)),
              Text("Location Area: ${booking.customerAreaName}", style: const TextStyle(color: Colors.white70)),
              Text("Pricing: ${booking.pricingBreakdown['total'] ?? 0} PKR", style: const TextStyle(color: Colors.white70)),
              Text("Status: ${booking.status.toUpperCase()}", style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Teek Hai'),
              ),
            ],
          ),
        );
      },
    );
  }
}
