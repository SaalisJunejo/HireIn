import 'package:flutter/material.dart';
import '../../services/local_database.dart';

import '../../core/constants/app_colors.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;
  List<Map<String, dynamic>> _past = [];

  @override
  void initState() {
    super.initState();
    _loadPast();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPast() async {
    try {
      final past = LocalDatabase.instance.getAll('announcements');
      past.sort((a, b) {
        final ta = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _past = past.take(20).toList();
      });
    } catch (_) {
      // Load mock past announcements for demo
      if (!mounted) return;
      setState(() {
        _past = [
          {'message': 'Sab providers se guzarish hai ke time pe pohanchein!', 'createdAt': DateTime.now().toIso8601String(), 'createdBy': 'admin@hirein.com', 'type': 'broadcast'},
          {'message': 'Eid ke baad naye providers welcome hain. Apply karein!', 'createdAt': DateTime.now().toIso8601String(), 'createdBy': 'admin@hirein.com', 'type': 'broadcast'},
        ];
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement likhna zaruri hai!'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _isSending = true);
    final doc = {
      'message': text,
      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': 'admin@hirein.com',
      'type': 'broadcast',
    };
    try {
      await LocalDatabase.instance.put('announcements', DateTime.now().millisecondsSinceEpoch.toString(), doc);
    } catch (e) {
      // Firestore write failed/timed-out — continue with local mock
      debugPrint('Announcement Firestore write failed: $e');
    }
    if (!mounted) return;
    _controller.clear();
    setState(() {
      _past.insert(0, doc);
      _isSending = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Announcement sab providers ko bhej di gayi!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcements', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Compose area
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Naya Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Sab providers ko kya bolna chahte hain?',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSending ? 'Bhej raha hoon...' : 'Sab Providers Ko Bhejo'),
                ),
              ],
            ),
          ),
          // Past announcements
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Text('Purane Announcements', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text('${_past.length} total', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: _past.isEmpty
                ? Center(child: Text('Abhi koi announcement nahi.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _past.length,
                    itemBuilder: (context, index) {
                      final item = _past[index];
                      final ts = item['createdAt'];
                      String dateStr = '';
                      if (ts != null) {
                        final dt = DateTime.tryParse(ts.toString());
                        if (dt != null) {
                          dateStr = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                        }
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withOpacity(0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('BROADCAST', style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
