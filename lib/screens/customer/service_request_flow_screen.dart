import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/provider_model.dart';
import '../../services/agent_service.dart';
import '../../core/utils/helpers.dart';

enum FlowState { input, thinking, results }

class ServiceRequestFlowScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const ServiceRequestFlowScreen({super.key, this.initialQuery});

  @override
  ConsumerState<ServiceRequestFlowScreen> createState() => _ServiceRequestFlowScreenState();
}

class _ServiceRequestFlowScreenState extends ConsumerState<ServiceRequestFlowScreen> with TickerProviderStateMixin {
  FlowState _currentState = FlowState.input;

  // SCREEN 1 Controller & Fields
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  String _selectedArea = 'Qasimabad';
  bool _isUsingGps = false;
  Position? _gpsPosition;

  // Hyderabad Areas for Dropdown
  final List<String> _hyderabadAreas = [
    'Latifabad', 'Qasimabad', 'Hirabad', 'Unit 9', 'Saddar', 
    'Unit 6', 'Unit 7', 'Unit 8', 'Unit 10', 'Unit 11', 'Unit 12', 
    'Hyder Chowk', 'Shahi Bazar'
  ];

  // Placeholder rotation
  final List<String> _placeholders = [
    "AC bilkul kaam nahi kar raha...",
    "Urgent plumber chahiye abhi...",
    "Kal subah electrician chahiye..."
  ];
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  // SCREEN 2 Thinking Controllers & State
  int _statusIndex = 0;
  Timer? _statusTimer;
  double _progressValue = 0.0;
  Timer? _progressTimer;
  bool _clarificationActive = false;
  String _clarificationQuestion = '';
  final TextEditingController _clarificationController = TextEditingController();
  
  final List<String> _statusMessages = [
    "Aapki baat samajh raha hoon...",
    "Nazdeeki providers dhundh raha hoon...",
    "Rating aur distance check kar raha hoon...",
    "Visit fee calculate ho rahi hai...",
    "Best match select ho raha hai..."
  ];

  // SCREEN 3 Results state
  ProviderModel? _topRecommendedProvider;
  List<ProviderModel> _alternativeProviders = [];
  String _aiReasoning = '';
  bool _isUrgentQuery = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPlaceholderRotation();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _inputController.text = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _statusTimer?.cancel();
    _progressTimer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _clarificationController.dispose();
    super.dispose();
  }

  void _startPlaceholderRotation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });
  }

  // GPS Location Trigger
  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isUsingGps = true;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _gpsPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎯 Current Location (GPS) resolved successfully!"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isUsingGps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("GPS coordinates resolve failed: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Call Pipeline
  Future<void> _runSearchPipeline(String query) async {
    setState(() {
      _currentState = FlowState.thinking;
      _clarificationActive = false;
      _errorMessage = null;
      _progressValue = 0.0;
      _statusIndex = 0;
    });

    _isUrgentQuery = query.toLowerCase().contains('urgent') || 
                     query.toLowerCase().contains('abhi') || 
                     query.toLowerCase().contains('emergency');

    // Cycle thinking status messages every 1.5s
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && !_clarificationActive) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        });
      }
    });

    // Smoothly animate progress bar to 100% over ~8s
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted && !_clarificationActive) {
        setState(() {
          _progressValue += 0.01;
          if (_progressValue >= 1.0) {
            _progressValue = 1.0;
            _progressTimer?.cancel();
          }
        });
      }
    });


    _executeCloudOrLocalPipeline(query);
  }

  Future<void> _executeCloudOrLocalPipeline(String query) async {
    final user = ref.read(authProvider).currentUser;
    final lat = _gpsPosition?.latitude ?? 25.3960;
    final lng = _gpsPosition?.longitude ?? 68.3578;

    try {
      final agentService = ref.read(agentServiceProvider);
      final finalResult = await agentService.processServiceQuery(query, lat, lng);

      // Complete progress and render Results Screen
      if (mounted) {
        setState(() {
          _progressValue = 1.0;
          _progressTimer?.cancel();
          _statusTimer?.cancel();
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            if (finalResult!.rankedProviders.isEmpty) {
              _errorMessage = "Koi active providers nahi mile is service ke liye Hyderabad mein.";
            } else {
              _topRecommendedProvider = finalResult.rankedProviders.first;
              _alternativeProviders = finalResult.rankedProviders.skip(1).take(2).toList();
              _aiReasoning = finalResult.thoughtProcess;
              _currentState = FlowState.results;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Kuch masla aa gaya, dobara try karein.";
          _statusTimer?.cancel();
          _progressTimer?.cancel();
        });
      }
    }
  }

  void _submitClarification() {
    final answer = _clarificationController.text.trim();
    if (answer.isEmpty) return;

    setState(() {
      _clarificationActive = false;
      _clarificationController.clear();
    });

    // Re-run search pipeline with expanded context
    final fullQuery = "${_inputController.text} (Clarification: $answer)";
    _executeCloudOrLocalPipeline(fullQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentStateView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_currentState) {
      case FlowState.input:
        return _buildInputScreen();
      case FlowState.thinking:
        return _buildThinkingScreen();
      case FlowState.results:
        return _buildResultsScreen();
    }
  }

  // --- SCREEN 1: INPUT WIDGET ---
  Widget _buildInputScreen() {
    return SingleChildScrollView(
      key: const ValueKey('input_screen'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Naya Service Order',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => context.go(AppRoutes.customerHome),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe what you need in Urdu, Roman Urdu, or English. Our multi-agent AI system will negotiate, discover, and lock in the best technician locally.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Main multiline Textfield
          const Text(
            'Aapko Kya Masla Hai?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              keyboardType: TextInputType.text, // Set standard text
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _placeholders[_placeholderIndex],
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Location Selection Panel
          const Text(
            'Kaam Kis Area Mein Karwana Hai?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedArea,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: _hyderabadAreas.map((area) {
                        return DropdownMenuItem(
                          value: area,
                          child: Text(area),
                        );
                      }).toList(),
                      onChanged: _isUsingGps ? null : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedArea = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                VerticalDivider(color: Colors.white.withOpacity(0.1)),
                TextButton.icon(
                  onPressed: _fetchGpsLocation,
                  icon: Icon(
                    _isUsingGps ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _isUsingGps ? AppColors.success : AppColors.gold,
                    size: 18,
                  ),
                  label: Text(
                    _isUsingGps ? 'GPS Active' : 'Use GPS',
                    style: TextStyle(
                      color: _isUsingGps ? AppColors.success : AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 36),

          // Submit "Dhundo" Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            onPressed: () {
              final query = _inputController.text.trim();
              if (query.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kam az kam 3 characters likhein.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              _runSearchPipeline(query);
            },
            child: const Text(
              'Dhundo (Search)',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .shimmer(delay: 2000.ms, duration: 1200.ms, color: Colors.white.withOpacity(0.35)),
        ],
      ),
    );
  }

  // --- SCREEN 2: THINKING WIDGET ---
  Widget _buildThinkingScreen() {
    if (_errorMessage != null) {
      return _buildErrorStateWidget();
    }

    return Container(
      key: const ValueKey('thinking_screen'),
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_clarificationActive) ...[
            const Spacer(),
            
            // Radar pulse animation
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.1),
                      border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1.5),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(2.2, 2.2), duration: 2000.ms, curve: Curves.easeOut)
                   .fadeOut(duration: 2000.ms),
                   
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withOpacity(0.15),
                      border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.6, 1.6), duration: 1500.ms, curve: Curves.easeOut)
                   .fadeOut(duration: 1500.ms),

                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                      boxShadow: [
                        BoxShadow(color: AppColors.gold, blurRadius: 15, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.bolt, color: AppColors.primary, size: 32),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 64),
            
            // Cycling status messages
            Container(
              height: 48,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _statusMessages[_statusIndex],
                  key: ValueKey(_statusIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Progress Bar at bottom
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('AI Matchmaker Status', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('${(_progressValue * 100).toInt()}%', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: AppColors.gold,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Clarification Active Dialog overlay
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.question_mark, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI Clarification Needed',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _clarificationQuestion,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _clarificationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type your answer here...',
                        prefixIcon: Icon(Icons.edit, color: AppColors.gold),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _currentState = FlowState.input;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                            onPressed: _submitClarification,
                            child: const Text('Jawab Do'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
          ]
        ],
      ),
    );
  }

  Widget _buildErrorStateWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Masla Aa Gaya!',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? "Unknown matching error.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, minimumSize: const Size(200, 48)),
            onPressed: () {
              final query = _inputController.text.trim();
              if (query.isNotEmpty) {
                _runSearchPipeline(query);
              }
            },
            child: const Text('Try Again'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _currentState = FlowState.input;
              });
            },
            child: const Text('Back to input', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: RESULTS SCREEN ---
  Widget _buildResultsScreen() {
    if (_topRecommendedProvider == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, color: AppColors.gold, size: 48),
                const SizedBox(height: 16),
                const Text(
                  '😔 Abhi koi service provider available nahi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hum ne 25km tak dhundha magar is waqt sab providers masroof hain ya offline hain.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Suggestion: Kal subah 9am se providers available hain',
                    style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, minimumSize: const Size(double.infinity, 48)),
                  onPressed: () {
                    setState(() => _currentState = FlowState.input);
                  },
                  child: const Text('Dobara Try Karo'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final top = _topRecommendedProvider!;

    return SingleChildScrollView(
      key: const ValueKey('results_screen'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Match Results',
                style: TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => context.go(AppRoutes.customerHome),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // A. TOP RECOMMENDED CARD
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ribbon Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: AppColors.gold, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '⭐ AI Ka Behtareen Match',
                            style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_isUrgentQuery)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⚡ URGENT',
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name and Rating
                Text(
                  "${top.name} — ⭐ ${top.rating.toStringAsFixed(1)}",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Category & distance
                Row(
                  children: [
                    Text(
                      top.category,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(
                      "${(top.lat - 25.3960).abs().toStringAsFixed(2)} km door", // mock dynamic distance
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visit fee in large bold gold
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estim. Visit Fee',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        Text(
                          "PKR ${top.baseRatePkr > 200 ? 200 : top.baseRatePkr}",
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (_isUrgentQuery)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Estimated ETA', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                          Text(
                            '~15 min mein',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Smart Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillBadge('Top Rated', const Color(0xff2196F3)),
                    _buildPillBadge('Verified', const Color(0xff4CAF50)),
                    _buildPillBadge('Affordable', const Color(0xff009688)),
                    _buildPillBadge('Expert Level', const Color(0xff9C27B0)),
                  ],
                ),
                const SizedBox(height: 16),

                // Expandable reasoning
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: const Text(
                      'AI ne kyun chuna?',
                      style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      Text(
                        _aiReasoning,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Qubool Karo & Book Karo
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.secondary,
                  ),
                  onPressed: () => _navigateToBookingScreen(top),
                  child: const Text('Qubool Karo & Book Karo'),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),

          // B. ALTERNATIVE PROVIDERS
          if (_alternativeProviders.isNotEmpty) ...[
            const Text(
              'Other Good Alternatives',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._alternativeProviders.map((prov) => _buildAlternativeCard(prov)),
          ],

          const SizedBox(height: 24),

          // C. Bottom link
          Center(
            child: TextButton.icon(
              onPressed: () {
                final category = _topRecommendedProvider?.category ?? 'General';
                int baseRate = 500;
                if (category == 'AC Repair') baseRate = 800;
                else if (category == 'Electrician') baseRate = 600;
                else if (category == 'Carpenter') baseRate = 700;
                else if (category == 'Painter') baseRate = 650;
                else if (category == 'Home Maid') baseRate = 400;

                setState(() {
                  _alternativeProviders.addAll([
                    ProviderModel(
                      id: 'PROV-EXTRA-1',
                      name: 'Saad ($category)',
                      phone: '+923000000001',
                      password: '',
                      category: category,
                      lat: (_gpsPosition?.latitude ?? 25.3960) + 0.05,
                      lng: (_gpsPosition?.longitude ?? 68.3578) + 0.05,
                      baseRatePkr: baseRate + 50,
                      rating: 4.5,
                      approvalStatus: 'approved',
                      skillLevel: 'intermediate',
                      areaName: 'Expanded Area',
                      cnicImageUrl: '',
                      reviewCount: 15,
                      onTimeScore: 0.9,
                      cancellationRate: 0.1,
                      riskScore: 0.0,
                      badges: const [],
                      negativeTags: const [],
                      shifts: const [],
                      pkrPerKm: 60,
                      urgentSurcharge: 100,
                      weeklyEarningsPending: 0.0,
                      isOnline: true,
                      currentLat: (_gpsPosition?.latitude ?? 25.3960) + 0.05,
                      currentLng: (_gpsPosition?.longitude ?? 68.3578) + 0.05,
                      createdAt: DateTime.now(),
                    ),
                    ProviderModel(
                      id: 'PROV-EXTRA-2',
                      name: 'Zahid ($category)',
                      phone: '+923000000002',
                      password: '',
                      category: category,
                      lat: (_gpsPosition?.latitude ?? 25.3960) - 0.05,
                      lng: (_gpsPosition?.longitude ?? 68.3578) - 0.05,
                      baseRatePkr: baseRate,
                      rating: 4.7,
                      approvalStatus: 'approved',
                      skillLevel: 'expert',
                      areaName: 'Expanded Area',
                      cnicImageUrl: '',
                      reviewCount: 82,
                      onTimeScore: 0.98,
                      cancellationRate: 0.02,
                      riskScore: 0.0,
                      badges: const ['Verified'],
                      negativeTags: const [],
                      shifts: const [],
                      pkrPerKm: 60,
                      urgentSurcharge: 100,
                      weeklyEarningsPending: 0.0,
                      isOnline: true,
                      currentLat: (_gpsPosition?.latitude ?? 25.3960) - 0.05,
                      currentLng: (_gpsPosition?.longitude ?? 68.3578) - 0.05,
                      createdAt: DateTime.now(),
                    ),
                  ]);
                });
              },
              icon: const Icon(Icons.replay, color: AppColors.gold, size: 18),
              label: const Text(
                'Koi aur provider dhundho? (Expand search radius)',
                style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCard(ProviderModel prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${prov.name} — ⭐ ${prov.rating.toStringAsFixed(1)}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "PKR ${prov.baseRatePkr > 200 ? 200 : prov.baseRatePkr}",
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(prov.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 8),
              Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text(prov.areaName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
              backgroundColor: Colors.white.withOpacity(0.08),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => _navigateToBookingScreen(prov),
            child: const Text('Isko Choose Karo', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _navigateToBookingScreen(ProviderModel provider) {
    // Navigate using context pushing state data
    context.push(
      AppRoutes.customerHome + '/booking', 
      extra: {
        'provider': provider,
        'isUrgent': _isUrgentQuery,
        'userLat': _gpsPosition?.latitude ?? 25.3960,
        'userLng': _gpsPosition?.longitude ?? 68.3578,
        'userArea': _selectedArea,
      },
    );
  }
}
