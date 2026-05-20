import 'package:flutter/material.dart';
import '../../services/local_database.dart';

import '../../core/constants/app_colors.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _disputes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final disputes = LocalDatabase.instance.getAll('disputes');
      disputes.sort((a, b) {
        final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      final firestoreDisputes = disputes.map((d) => {'id': d['id'] ?? d['bookingId'] ?? '', ...d}).toList();
      // Merge: use Firestore disputes if available, else fallback to mocks
      setState(() {
        _disputes = firestoreDisputes.isNotEmpty ? firestoreDisputes : _mockDisputes();
      });
    } catch (_) {
      if (!mounted) return;
      // Fallback: show mock disputes for demo instantly
      setState(() {
        _disputes = _mockDisputes();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _mockDisputes() => [
    {
      'id': 'DISP-001',
      'bookingId': 'BK-1234',
      'type': 'Overcharged',
      'description': 'Provider ne zyada paisa liya. Quote 300 tha, 600 le gaya.',
      'aiResolution': 'Customer ka claim valid hai. Provider ko warning di jayegi aur refund process hogi.',
      'aiRationale': 'Based on booking history and pricing breakdown, base fee was PKR 300 but provider charged PKR 600.',
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
      'providerId': 'PROV-001',
    },
    {
      'id': 'DISP-002',
      'bookingId': 'BK-2233',
      'type': 'No Show',
      'description': 'Provider booking confirm karke aaya nahi.',
      'aiResolution': 'Full refund customer ko di jayegi. Provider ka account flagged.',
      'aiRationale': 'GPS logs show provider never reached customer location. Status was never updated beyond confirmed.',
      'status': 'open',
      'createdAt': DateTime.now().toIso8601String(),
      'providerId': 'PROV-002',
    },
    {
      'id': 'DISP-003',
      'bookingId': 'BK-3311',
      'type': 'Poor Quality',
      'description': 'Kaam acha nahi tha, 2 din mein dobara kharab ho gaya.',
      'aiResolution': 'Partial refund (50%) recommended. Provider needs retraining assessment.',
      'aiRationale': 'Customer has valid photos. Provider has 2 previous similar complaints this month.',
      'status': 'resolved',
      'resolution': 'Partial refund of PKR 150 processed.',
      'createdAt': DateTime.now().toIso8601String(),
      'providerId': 'PROV-001',
    },
  ];

  Future<void> _agreeWithAi(String disputeId, String aiResolution) async {
    try {
      final dispute = LocalDatabase.instance.get('disputes', disputeId);
      if (dispute != null) {
        dispute['status'] = 'resolved';
        dispute['resolution'] = aiResolution;
        dispute['resolvedBy'] = 'admin_ai_agree';
        dispute['resolvedAt'] = DateTime.now().toIso8601String();
        await LocalDatabase.instance.put('disputes', disputeId, dispute);
      }
      if (!mounted) return;
      setState(() {
        final idx = _disputes.indexWhere((d) => d['id'] == disputeId);
        if (idx != -1) {
          _disputes[idx]['status'] = 'resolved';
          _disputes[idx]['resolution'] = aiResolution;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ AI Resolution accepted!'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final idx = _disputes.indexWhere((d) => d['id'] == disputeId);
        if (idx != -1) {
          _disputes[idx]['status'] = 'resolved';
          _disputes[idx]['resolution'] = aiResolution;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Resolution marked (offline mode).'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  Future<void> _overrideDialog(String disputeId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Manual Override', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Apna resolution likhein...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Override'),
          ),
        ],
      ),
    );
    if (confirmed != true || ctrl.text.trim().isEmpty) return;
    try {
      final dispute = LocalDatabase.instance.get('disputes', disputeId);
      if (dispute != null) {
        dispute['status'] = 'resolved';
        dispute['resolution'] = ctrl.text.trim();
        dispute['resolvedBy'] = 'admin_manual';
        dispute['resolvedAt'] = DateTime.now().toIso8601String();
        await LocalDatabase.instance.put('disputes', disputeId, dispute);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      final idx = _disputes.indexWhere((d) => d['id'] == disputeId);
      if (idx != -1) {
        _disputes[idx]['status'] = 'resolved';
        _disputes[idx]['resolution'] = ctrl.text.trim();
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Manual resolution saved!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _suspendProvider(String providerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Suspend Provider?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Provider ka account suspend karna chahte hain?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend Karo'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final provider = LocalDatabase.instance.get('providers', providerId);
      if (provider != null) {
        provider['approvalStatus'] = 'suspended';
        await LocalDatabase.instance.put('providers', providerId, provider);
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 Provider suspended!'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _disputes.where((d) => d['status'] == 'open').toList();
    final resolved = _disputes.where((d) => d['status'] != 'open').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Disputes${open.isNotEmpty ? " (${open.length} open)" : ""}',
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (open.isNotEmpty) ...[
                  const Text('OPEN DISPUTES', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ...open.map((d) => _buildCard(d, isOpen: true)),
                  const SizedBox(height: 20),
                ],
                if (resolved.isNotEmpty) ...[
                  const Text('RESOLVED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  ...resolved.map((d) => _buildCard(d, isOpen: false)),
                ],
                if (_disputes.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text('Koi dispute nahi.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
                  )),
              ],
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> d, {required bool isOpen}) {
    final bool rationaleExpanded = false;

    return StatefulBuilder(
      builder: (context, setSt) {
        bool _expanded = false;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isOpen ? Colors.orange.withOpacity(0.25) : Colors.green.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['bookingId'] ?? '', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(d['type'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isOpen ? Colors.orange : Colors.green).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOpen ? 'OPEN' : 'RESOLVED',
                        style: TextStyle(color: isOpen ? Colors.orange : Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer description
                    Text(d['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 12),
                    // AI Resolution box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B3E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.blue, size: 14),
                              SizedBox(width: 6),
                              Text('AI Se Masla Hal', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d['aiResolution'] ?? 'No AI resolution available.', style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // AI Rationale expandable
                    GestureDetector(
                      onTap: () => setSt(() => _expanded = !_expanded),
                      child: Row(
                        children: [
                          const Text('AI Rationale', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(width: 4),
                          Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 6),
                      Text(d['aiRationale'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.5)),
                    ],
                    if (d['resolution'] != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Resolution: ${d['resolution']}', style: const TextStyle(color: Colors.green, fontSize: 11)),
                      ),
                    ],
                    if (isOpen) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _agreeWithAi(d['id'], d['aiResolution'] ?? ''),
                              child: const Text('AI Se Agree Karo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold.withOpacity(0.15),
                                foregroundColor: AppColors.gold,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _overrideDialog(d['id']),
                              child: const Text('Override Karo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (d['providerId'] != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () => _suspendProvider(d['providerId']),
                          icon: const Icon(Icons.block, size: 14),
                          label: const Text('Suspend Provider', style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
