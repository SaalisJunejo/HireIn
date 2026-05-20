import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_database.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../utils/demo_helper.dart';

class AgentLogsScreen extends ConsumerStatefulWidget {
  final String? bookingId;

  const AgentLogsScreen({super.key, this.bookingId});

  @override
  ConsumerState<AgentLogsScreen> createState() => _AgentLogsScreenState();
}

class _AgentLogsScreenState extends ConsumerState<AgentLogsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _logs;
  String _targetBookingId = 'MOCK-BK';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    // If a bookingId is provided, try to fetch its agentLogs from Firestore
    if (widget.bookingId != null) {
      try {
        final doc = LocalDatabase.instance.get('bookings', widget.bookingId!);
        if (doc != null && doc['agentLogs'] != null) {
          if (mounted) {
            setState(() {
              _logs = Map<String, dynamic>.from(doc['agentLogs']);
              _targetBookingId = widget.bookingId!;
              _isLoading = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

    // Fallback: search for the most recent completed booking
    try {
      final docs = LocalDatabase.instance.getAll('bookings')
        ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      if (docs.isNotEmpty && docs.first['agentLogs'] != null) {
        if (mounted) {
          setState(() {
            _logs = Map<String, dynamic>.from(docs.first['agentLogs']);
            _targetBookingId = docs.first['bookingId'];
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Ultimate Fallback: No logs available
    if (mounted) {
      setState(() {
        _logs = null;
        _targetBookingId = widget.bookingId ?? 'N/A';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getMockLogs() {
    return {
      'Agent_1': {
        'name': 'Agent 1 — Intent Extractor',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'input': 'User query: "Mujhe urgent AC technician chahiye Latifabad mein"',
        'reasoning': 'Analyzing semantic keywords from mixed Roman Urdu/English input. Identified high-urgency token "urgent", service category target "AC technician", and geographical area "Latifabad" which maps directly to Latifabad sub-districts in Hyderabad, Sindh.',
        'output': '{\n  "intent": "service_request",\n  "category": "AC Technician",\n  "urgency": "urgent",\n  "area": "Latifabad",\n  "city": "Hyderabad"\n}',
        'confidence': 98,
        'durationMs': 240,
      },
      'Agent_2': {
        'name': 'Agent 2 — Geospatial Router',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'input': '{\n  "area": "Latifabad",\n  "city": "Hyderabad"\n}',
        'reasoning': 'Resolving spatial boundaries for Latifabad, Hyderabad. Geocoding coordinates resolved to lat: 25.3710, lng: 68.3553. Establishing 5.0 km geofence search radius to index nearby active partner coordinates.',
        'output': '{\n  "resolvedLat": 25.3710,\n  "resolvedLng": 68.3553,\n  "searchRadiusKm": 5.0,\n  "geohash": "tsg6u8"\n}',
        'confidence': 95,
        'durationMs': 180,
      },
      'Agent_3': {
        'name': 'Agent 3 — Discovery Engine',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        'input': '{\n  "category": "AC Technician",\n  "lat": 25.3710,\n  "lng": 68.3553,\n  "radius": 5.0\n}',
        'reasoning': 'Querying active provider registry. Scanning for online and approved partners matching "AC Technician" within the 5.0 km Latifabad geofence coordinates. Filtered out 2 suspended or inactive providers.',
        'output': '{\n  "candidatesCount": 2,\n  "matchingProviders": [\n    {\n      "id": "PROV-001",\n      "name": "Ali Ahmed",\n      "distanceKm": 1.2,\n      "rating": 4.9,\n      "approvalStatus": "approved"\n    },\n    {\n      "id": "PROV-002",\n      "name": "Yasir AC Expert",\n      "distanceKm": 3.4,\n      "rating": 4.6,\n      "approvalStatus": "approved"\n    }\n  ]\n}',
        'confidence': 100,
        'durationMs': 310,
      },
      'Agent_4': {
        'name': 'Agent 4 — Pricing & Bid Optimizer',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        'input': '{\n  "providers": ["PROV-001", "PROV-002"],\n  "isUrgent": true\n}',
        'reasoning': 'Running pricing optimization. Base rates PKR 500 loaded. Distance-based travel surcharges applied (PROV-001: PKR 100, PROV-002: PKR 150). Urgency fee premium (1.2x multiplier) added since search intent is "urgent". Calculating 10% platform cuts.',
        'output': '{\n  "calculations": {\n    "PROV-001": {\n      "baseFeePkr": 500,\n      "travelFeePkr": 100,\n      "urgentSurchargePkr": 100,\n      "platformFeePkr": 70,\n      "totalPkr": 770\n    },\n    "PROV-002": {\n      "baseFeePkr": 480,\n      "travelFeePkr": 150,\n      "urgentSurchargePkr": 100,\n      "platformFeePkr": 73,\n      "totalPkr": 803\n    }\n  }\n}',
        'confidence': 92,
        'durationMs': 140,
      },
      'Agent_5': {
        'name': 'Agent 5 — Availability Scheduler',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        'input': '{\n  "providers": ["PROV-001", "PROV-002"],\n  "date": "2026-05-18"\n}',
        'reasoning': 'Scanning providers active shifts calendars and booked slots list for today. PROV-001 (Ali Ahmed) shifts cover 9am-12pm and 3pm-7pm (active currently). No conflicts found for both candidates.',
        'output': '{\n  "availabilityMatrix": {\n    "PROV-001": {\n      "isShiftActive": true,\n      "hasConflicts": false,\n      "nextFreeSlot": "Immediate"\n    },\n    "PROV-002": {\n      "isShiftActive": true,\n      "hasConflicts": false,\n      "nextFreeSlot": "Immediate"\n    }\n  }\n}',
        'confidence': 97,
        'durationMs': 160,
      },
      'Agent_6': {
        'name': 'Agent 6 — Ranking & Matching Model',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        'input': '{\n  "candidates": ["PROV-001", "PROV-002"],\n  "distances": {"PROV-001": 1.2, "PROV-002": 3.4},\n  "ratings": {"PROV-001": 4.9, "PROV-002": 4.6},\n  "prices": {"PROV-001": 770, "PROV-002": 803}\n}',
        'reasoning': 'Applying ranking scores: proximity (40%), rating (30%), pricing (20%), on-time record (10%). Ali Ahmed (PROV-001) scores highest (9.4/10) due to extremely close range (1.2km) and superior customer feedback scores.',
        'output': '{\n  "scoresList": [\n    {\n      "providerId": "PROV-001",\n      "score": 9.4,\n      "rank": 1\n    },\n    {\n      "providerId": "PROV-002",\n      "score": 8.1,\n      "rank": 2\n    }\n  ]\n}',
        'confidence': 96,
        'durationMs': 210,
      },
      'Agent_7': {
        'name': 'Agent 7 — Booking & Lock Handler',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        'input': '{\n  "matchedProvider": "PROV-001",\n  "customerId": "CUST-99"\n}',
        'reasoning': 'Acquiring high-speed transactional lock state in Firestore matching provider Ali Ahmed to protect schedule block against double-booking race conditions during final payment processing.',
        'output': '{\n  "lockAcquired": true,\n  "providerLockState": "secured",\n  "expirationTime": "2026-05-18T09:37:50Z"\n}',
        'confidence': 100,
        'durationMs': 90,
      },
      'Agent_8': {
        'name': 'Agent 8 — Dispatch & Notification Agent',
        'status': 'completed',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        'input': '{\n  "bookingId": "BK-1234",\n  "providerId": "PROV-001"\n}',
        'reasoning': 'Packaging job tokens, target client coordinates, and billing grids. Routing push alerts to Ali Ahmed\'s device endpoint. Simulated live Bykea drift tracker initialized.',
        'output': '{\n  "dispatchStatus": "success",\n  "pushDelivered": true,\n  "partnerAcknowledgePending": true\n}',
        'confidence': 98,
        'durationMs': 110,
      },
      'Agent_9': {
        'name': 'Agent 9 — AI Dispute Resolver',
        'status': 'skipped',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
        'input': '{\n  "bookingId": "BK-1234",\n  "status": "completed"\n}',
        'reasoning': 'Lifecycle review: Job completed successfully without user complaint filings. Conflict resolver skipped.',
        'output': '{\n  "state": "inactive",\n  "reason": "No dispute raised"\n}',
        'confidence': 0,
        'durationMs': 0,
      },
    };
  }

  void _copyTabLog(Map<String, dynamic> log) {
    final text = 'Agent: ${log['name']}\n'
        'Status: ${log['status']?.toString().toUpperCase()}\n'
        'Time: ${log['timestamp']}\n'
        'Confidence: ${log['confidence']}%\n'
        'Duration: ${log['durationMs']}ms\n\n'
        '--- INPUT ---\n${log['input']}\n\n'
        '--- REASONING ---\n${log['reasoning']}\n\n'
        '--- OUTPUT ---\n${log['output']}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${log['name']} log copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareAllLogs() {
    if (_logs == null) return;
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('HIREIN AI AGENT PIPELINE RUN - BOOKING: $_targetBookingId');
    buffer.writeln('========================================\n');

    _logs!.forEach((key, value) {
      final log = Map<String, dynamic>.from(value);
      buffer.writeln('----------------------------------------');
      buffer.writeln('Agent: ${log['name']}');
      buffer.writeln('Status: ${log['status']?.toString().toUpperCase()}');
      buffer.writeln('Execution Time: ${log['durationMs']}ms');
      buffer.writeln('Confidence: ${log['confidence']}%');
      buffer.writeln('----------------------------------------');
      buffer.writeln('INPUT:\n${log['input']}');
      buffer.writeln('REASONING:\n${log['reasoning']}');
      buffer.writeln('OUTPUT:\n${log['output']}');
      buffer.writeln('\n');
    });

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Full 9-Agent Pipeline Log exported & copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D0D1A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Agent Pipeline',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Target Booking: $_targetBookingId',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        backgroundColor: const Color(0xff0D0D1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white24, size: 16),
            onPressed: () => _showTestScenariosSheet(context),
            tooltip: 'Test Scenarios Demo',
          ),
          TextButton.icon(
            onPressed: _shareAllLogs,
            icon: const Icon(Icons.share, color: AppColors.gold, size: 16),
            label: const Text('Export All', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: LocalDatabase.instance.watch('bookings'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError || !snapshot.hasData) {
             return const Center(child: Text('No telemetry logs generated yet.', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }
          
          final docs = snapshot.data!;
          Map<String, dynamic>? doc;

          if (widget.bookingId != null) {
            final matching = docs.where((d) => d['bookingId'] == widget.bookingId).toList();
            if (matching.isNotEmpty) doc = matching.first;
          } else if (docs.isNotEmpty) {
            final sorted = List<Map<String, dynamic>>.from(docs)
              ..sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
            doc = sorted.first;
          }
          
          if (doc == null || doc['agentLogs'] == null) {
            return const Center(child: Text('No telemetry logs generated yet.', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }

          final logsMap = Map<String, dynamic>.from(doc['agentLogs']);
          
          return Column(
              children: [
                // Top scrolling tabs list
                Container(
                  color: const Color(0xff121224),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Agent 1'),
                      Tab(text: 'Agent 2'),
                      Tab(text: 'Agent 3'),
                      Tab(text: 'Agent 4'),
                      Tab(text: 'Agent 5'),
                      Tab(text: 'Agent 6'),
                      Tab(text: 'Agent 7'),
                      Tab(text: 'Agent 8'),
                      Tab(text: 'Agent 9'),
                    ],
                  ),
                ),
                // Tab bodies
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(9, (index) {
                      final key = 'Agent_${index + 1}';
                      final data = logsMap[key];
                      if (data == null) {
                        return const Center(child: Text('Log missing', style: TextStyle(color: Colors.white24)));
                      }
                      final log = Map<String, dynamic>.from(data);
                      return _buildAgentTabContent(log);
                    }),
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  Widget _buildAgentTabContent(Map<String, dynamic> log) {
    final status = log['status']?.toString() ?? 'skipped';
    final bool isSkipped = status == 'skipped';
    final bool isError = status == 'error';
    
    Color statusColor = Colors.green;
    if (isSkipped) statusColor = Colors.grey;
    if (isError) statusColor = AppColors.error;

    final double conf = (log['confidence'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['name'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Executed: ${log['durationMs']}ms',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Confidence Grid (if applicable)
          if (conf > 0) ...[
            const Text('CONFIDENCE SCORE', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: conf / 100.0,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    color: Colors.green,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${conf.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Input Block
          _sectionHeader('1. INPUT DATA'),
          _terminalBox(log['input'] ?? ''),
          const SizedBox(height: 20),

          // Reasoning Card
          _sectionHeader('2. GEMINI REASONING'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xff18182E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              log['reasoning'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Output Block
          _sectionHeader('3. JSON OUTPUT'),
          _terminalBox(log['output'] ?? ''),
          const SizedBox(height: 28),

          // Action Copy
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.secondary.withOpacity(0.12),
              foregroundColor: AppColors.gold,
              elevation: 0,
              side: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            onPressed: () => _copyTabLog(log),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Agent Log', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showTestScenariosSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Test Demo Scenarios', style: TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Trigger these 5 mandatory scenarios manually:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              _buildTestButton(ctx, '1. No Provider Available', () {
                Navigator.pop(ctx);
                DemoHelper.triggerScenario(context, ref, 1);
              }),
              _buildTestButton(ctx, '2. Ambiguous Input', () {
                Navigator.pop(ctx);
                DemoHelper.triggerScenario(context, ref, 2);
              }),
              _buildTestButton(ctx, '3. Double Booking Conflict', () {
                Navigator.pop(ctx);
                DemoHelper.triggerScenario(context, ref, 3);
              }),
              _buildTestButton(ctx, '4. Provider Cancels After Booking', () {
                Navigator.pop(ctx);
                DemoHelper.triggerScenario(context, ref, 4);
              }),
              _buildTestButton(ctx, '5. Price Dispute', () {
                Navigator.pop(ctx);
                DemoHelper.triggerScenario(context, ref, 5);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestButton(BuildContext ctx, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: AppColors.secondary,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.8),
      ),
    );
  }

  Widget _terminalBox(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff06060C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
      ),
      child: Text(
        content,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'Courier',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
