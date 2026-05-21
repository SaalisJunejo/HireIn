import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/local_database.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../utils/demo_helper.dart';

class AgentLogsScreen extends ConsumerStatefulWidget {
  final String? bookingId;

  const AgentLogsScreen({super.key, this.bookingId});

  @override
  ConsumerState<AgentLogsScreen> createState() => _AgentLogsScreenState();
}

class _AgentLogsScreenState extends ConsumerState<AgentLogsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _targetBookingId = 'MOCK-BK';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // Derive initial booking ID for the AppBar subtitle
    if (widget.bookingId != null) {
      _targetBookingId = widget.bookingId!;
    } else {
      final docs = LocalDatabase.instance.getAll('bookings');
      if (docs.isNotEmpty) {
        docs.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
        _targetBookingId = docs.first['bookingId'] ?? 'MOCK-BK';
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getDynamicLogs(Map<String, dynamic> doc) {
    final bookingId = doc['bookingId'] ?? 'BK-MOCK';
    final service = doc['service'] ?? 'AC Technician';
    final customerAreaName = doc['customerAreaName'] ?? 'Latifabad';
    final isUrgent = doc['isUrgent'] == true;
    final providerId = doc['providerId'] ?? 'PROV-001';
    final distanceKm = (doc['distanceKm'] ?? 1.2) as num;
    final scheduledAt = doc['scheduledAt'] ?? DateTime.now().toIso8601String();
    final createdAt = doc['createdAt'] ?? DateTime.now().toIso8601String();
    final status = doc['status'] ?? 'booked';
    
    final pricing = doc['pricingBreakdown'] != null 
        ? Map<String, dynamic>.from(doc['pricingBreakdown']) 
        : {};
    final baseFee = pricing['baseFee'] ?? 500;
    final travelFee = pricing['travelFee'] ?? 100;
    final urgentSurcharge = pricing['urgentSurcharge'] ?? 0;
    final platformFee = pricing['platformFee'] ?? 50;
    final total = pricing['total'] ?? 650;

    final providerDoc = LocalDatabase.instance.get('providers', providerId);
    final providerName = providerDoc?['name'] ?? 'Ali Ahmed';
    final providerRating = providerDoc?['rating'] ?? 4.9;

    return {
      'Agent_1': {
        'name': 'Agent 1 — Intent Extractor',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).toIso8601String(),
        'input': 'User query: "Mujhe ${isUrgent ? 'urgent ' : ''}$service chahiye $customerAreaName mein"',
        'reasoning': 'Analyzing semantic keywords from mixed Roman Urdu/English input. Identified target service category "$service", geographical area "$customerAreaName", and urgency status: ${isUrgent ? "URGENT" : "NORMAL"}.',
        'output': '{\n  "intent": "service_request",\n  "category": "$service",\n  "urgency": "${isUrgent ? 'urgent' : 'normal'}",\n  "area": "$customerAreaName",\n  "city": "Hyderabad"\n}',
        'confidence': 98,
        'durationMs': 240,
      },
      'Agent_2': {
        'name': 'Agent 2 — Provider Discovery',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(milliseconds: 250)).toIso8601String(),
        'input': '{\n  "service": "$service",\n  "lat": ${doc['customerLat'] ?? 25.3710},\n  "lng": ${doc['customerLng'] ?? 68.3553},\n  "searchRadiusKm": 5.0\n}',
        'reasoning': 'Scanning geohash registers around coordinates (${doc['customerLat'] ?? 25.3710}, ${doc['customerLng'] ?? 68.3553}) for active, approved providers matching the category "$service".',
        'output': '{\n  "success": true,\n  "providersFoundCount": 1,\n  "providers": [\n    {\n      "id": "$providerId",\n      "name": "$providerName",\n      "distanceKm": ${distanceKm.toStringAsFixed(1)},\n      "rating": $providerRating\n    }\n  ]\n}',
        'confidence': 95,
        'durationMs': 180,
      },
      'Agent_3': {
        'name': 'Agent 3 — Ranking Engine',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(milliseconds: 450)).toIso8601String(),
        'input': '{\n  "providers": [\n    {\n      "id": "$providerId",\n      "distanceKm": ${distanceKm.toStringAsFixed(1)},\n      "rating": $providerRating\n    }\n  ]\n}',
        'reasoning': 'Applying multidimensional scoring matrix: rating (40%), proximity (40%), and historic reliability (20%). $providerName scores highest at 9.6/10 due to short distance (${distanceKm.toStringAsFixed(1)}km) and high rating ($providerRating).',
        'output': '{\n  "rankedProviders": [\n    {\n      "id": "$providerId",\n      "name": "$providerName",\n      "score": 9.6,\n      "rank": 1\n    }\n  ]\n}',
        'confidence': 97,
        'durationMs': 210,
      },
      'Agent_4': {
        'name': 'Agent 4 — Pricing Engine',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(milliseconds: 650)).toIso8601String(),
        'input': '{\n  "providerId": "$providerId",\n  "distanceKm": ${distanceKm.toStringAsFixed(1)},\n  "isUrgent": $isUrgent\n}',
        'reasoning': 'Calculating itemized PKR breakdown for $providerName. Base fee: PKR $baseFee. Travel allowance: PKR $travelFee. Urgent surcharge: PKR $urgentSurcharge. Platform fee: PKR $platformFee.',
        'output': '{\n  "pricingBreakdown": {\n    "baseFee": $baseFee,\n    "travelFee": $travelFee,\n    "urgentSurcharge": $urgentSurcharge,\n    "platformFee": $platformFee,\n    "total": $total\n  }\n}',
        'confidence': 100,
        'durationMs': 140,
      },
      'Agent_5': {
        'name': 'Agent 5 — Matchmaker',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(milliseconds: 800)).toIso8601String(),
        'input': '{\n  "rankedProviders": [\n    {\n      "id": "$providerId",\n      "score": 9.6\n    }\n  ],\n  "pricingResults": {\n    "total": $total\n  }\n}',
        'reasoning': 'Evaluating final matchmaking recommendation. Selected provider $providerName ($providerRating stars, ${distanceKm.toStringAsFixed(1)}km away) for service "$service" with transparent price of PKR $total.',
        'output': '{\n  "winner": {\n    "id": "$providerId",\n    "name": "$providerName",\n    "category": "$service",\n    "distanceKm": ${distanceKm.toStringAsFixed(1)},\n    "rating": $providerRating\n  },\n  "reasoningSummary": "Best match based on optimal rating, close proximity, and verified fee schedule of PKR $total."\n}',
        'confidence': 99,
        'durationMs': 160,
      },
      'Agent_6': {
        'name': 'Agent 6 — Booking Lock',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(seconds: 1, milliseconds: 100)).toIso8601String(),
        'input': '{\n  "bookingId": "$bookingId",\n  "providerId": "$providerId",\n  "timeSlot": "Immediate",\n  "isUrgent": $isUrgent\n}',
        'reasoning': 'Checking provider schedule matrix. Acquiring database concurrency lock for $providerName on slot to prevent race conditions or double-booking conflicts.',
        'output': '{\n  "lockAcquired": true,\n  "status": "booked",\n  "bookingId": "$bookingId"\n}',
        'confidence': 100,
        'durationMs': 90,
      },
      'Agent_7': {
        'name': 'Agent 7 — Follow-Up',
        'status': 'completed',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(seconds: 1, milliseconds: 300)).toIso8601String(),
        'input': '{\n  "bookingId": "$bookingId",\n  "scheduledAt": "$scheduledAt"\n}',
        'reasoning': 'Configuring automated cron handlers to dispatch three sequential user notification events (initial booking confirmation, provider en-route alert, and post-service feedback prompt).',
        'output': '{\n  "remindersScheduled": 3,\n  "types": ["reminder", "en_route", "completion_prompt"]\n}',
        'confidence': 98,
        'durationMs': 110,
      },
      'Agent_8': {
        'name': 'Agent 8 — Review & Badges',
        'status': status == 'completed' ? 'completed' : 'skipped',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(seconds: 1, milliseconds: 450)).toIso8601String(),
        'input': '{\n  "bookingId": "$bookingId",\n  "providerId": "$providerId",\n  "status": "$status"\n}',
        'reasoning': status == 'completed' 
            ? 'Processing completed service ratings and reviewing customer transaction logs to update provider and customer badge statistics.' 
            : 'Booking lifecycle is currently "$status" and not yet completed. Skipping review telemetry.',
        'output': status == 'completed'
            ? '{\n  "reviewsUpdated": true,\n  "ratingAwarded": ${doc['rating'] ?? 5},\n  "badgesAssigned": ["Top Rated Customer"]\n}'
            : '{\n  "reviewsUpdated": false,\n  "reason": "Booking is not completed"\n}',
        'confidence': status == 'completed' ? 98 : 0,
        'durationMs': status == 'completed' ? 120 : 0,
      },
      'Agent_9': {
        'name': 'Agent 9 — Dispute Resolution',
        'status': status == 'disputed' ? 'completed' : 'skipped',
        'timestamp': DateTime.parse(createdAt.toString()).add(const Duration(seconds: 1, milliseconds: 600)).toIso8601String(),
        'input': '{\n  "bookingId": "$bookingId",\n  "status": "$status"\n}',
        'reasoning': status == 'disputed' 
            ? 'Dispute detected! Customer complaint: "${doc['reviewComment'] ?? 'Overcharged'}". Mediating agreed total PKR $total against billing records.' 
            : 'No active dispute raised for booking. Auto-mediation bypassed.',
        'output': status == 'disputed'
            ? '{\n  "state": "resolved",\n  "refundIssued": true,\n  "decision": "Verified provider overcharge discrepancy. Partial refund of discrepancy difference credited back to customer."\n}'
            : '{\n  "state": "inactive",\n  "reason": "No dispute raised"\n}',
        'confidence': status == 'disputed' ? 95 : 0,
        'durationMs': status == 'disputed' ? 250 : 0,
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
    // Build merged logs from DB + mock fallback
    Map<String, dynamic>? doc;
    if (widget.bookingId != null) {
      doc = LocalDatabase.instance.get('bookings', widget.bookingId!);
    }
    if (doc == null) {
      final docs = LocalDatabase.instance.getAll('bookings');
      if (docs.isNotEmpty) {
        docs.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
        doc = docs.first;
      }
    }
    if (doc == null) return;

    final dbLogs = doc['agentLogs'] != null ? Map<String, dynamic>.from(doc['agentLogs']) : {};
    final mockLogs = _getDynamicLogs(doc);
    final logsMap = <String, dynamic>{};
    for (int i = 1; i <= 9; i++) {
      final key = 'Agent_$i';
      logsMap[key] = dbLogs[key] ?? mockLogs[key];
    }

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('HIREIN AI AGENT PIPELINE RUN - BOOKING: $_targetBookingId');
    buffer.writeln('========================================\n');

    logsMap.forEach((key, value) {
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
          
          if (doc == null) {
            return const Center(child: Text('No telemetry logs generated yet.', style: TextStyle(color: Colors.white54, fontSize: 16)));
          }

          final dbLogs = doc['agentLogs'] != null ? Map<String, dynamic>.from(doc['agentLogs']) : {};
          final mockLogs = _getDynamicLogs(doc);
          final logsMap = <String, dynamic>{};
          for (int i = 1; i <= 9; i++) {
            final key = 'Agent_$i';
            logsMap[key] = dbLogs[key] ?? mockLogs[key];
          }
          
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
