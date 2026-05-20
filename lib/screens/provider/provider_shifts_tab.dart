import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/provider_model.dart';
import '../../core/utils/helpers.dart';
import '../../services/local_database.dart';

class ProviderShiftsTab extends ConsumerStatefulWidget {
  const ProviderShiftsTab({super.key});

  @override
  ConsumerState<ProviderShiftsTab> createState() => _ProviderShiftsTabState();
}

class _ProviderShiftsTabState extends ConsumerState<ProviderShiftsTab> {
  late List<DateTime> _next7Days;
  DateTime _selectedDate = DateTime.now();
  
  // Local shifts map state: { '2026-05-18': [ {'start': '09:00', 'end': '12:00'} ] }
  Map<String, List<Map<String, String>>> _localShifts = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateNext7Days();
    _loadExistingShifts();
  }

  void _generateNext7Days() {
    final now = DateTime.now();
    _next7Days = List.generate(7, (index) => now.add(Duration(days: index)));
    _selectedDate = _next7Days.first;
  }

  void _loadExistingShifts() {
    final authState = ref.read(authProvider);
    final provider = authState.currentProvider;
    if (provider == null) return;

    final Map<String, List<Map<String, String>>> parsed = {};
    for (var shift in provider.shifts) {
      final dateStr = shift['date'] as String?;
      if (dateStr == null) continue;

      final List<Map<String, String>> ranges = [];
      final list = shift['ranges'] as List?;
      if (list != null) {
        for (var item in list) {
          if (item is Map) {
            ranges.add({
              'start': item['start']?.toString() ?? '',
              'end': item['end']?.toString() ?? '',
            });
          }
        }
      }
      parsed[dateStr] = ranges;
    }
    setState(() {
      _localShifts = parsed;
    });
  }

  String _getDateKey(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  Future<void> _addTimeRange() async {
    // Wrap in a bright theme so OK/Cancel buttons are visible
    final TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'STARTING TIME CHUNIYE',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (start == null) return;

    if (!mounted) return;

    final TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour + 3, minute: start.minute),
      helpText: 'ENDING TIME CHUNIYE',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (end == null) return;

    final String dateKey = _getDateKey(_selectedDate);
    final String startStr = "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
    final String endStr = "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";

    setState(() {
      final list = _localShifts[dateKey] ?? [];
      list.add({'start': startStr, 'end': endStr});
      _localShifts[dateKey] = list;
    });
  }

  void _removeTimeRange(int index) {
    final String dateKey = _getDateKey(_selectedDate);
    setState(() {
      final list = _localShifts[dateKey] ?? [];
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
      }
      if (list.isEmpty) {
        _localShifts.remove(dateKey);
      } else {
        _localShifts[dateKey] = list;
      }
    });
  }

  Future<void> _saveShifts() async {
    final authState = ref.read(authProvider);
    final provider = authState.currentProvider;
    if (provider == null) return;

    setState(() {
      _isSaving = true;
    });

    // Format shifts for firestore
    final List<Map<String, dynamic>> shiftsList = [];
    _localShifts.forEach((dateKey, ranges) {
      shiftsList.add({
        'date': dateKey,
        'ranges': ranges,
      });
    });

    try {
      final pData = LocalDatabase.instance.get('providers', provider.id);
      if (pData != null) {
        pData['shifts'] = shiftsList;
        await LocalDatabase.instance.put('providers', provider.id, pData);
      }
    } catch (e) {
      Helpers.log('ProviderShifts', 'Local save failed: $e');
    }

    // Always update local provider model regardless of Firestore outcome
    try {
      final updatedProvider = provider.copyWith(shifts: shiftsList);
      ref.read(authProvider.notifier).updateProviderProfile(updatedProvider);
    } catch (_) {}

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Shifts successfully updated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateKey = _getDateKey(_selectedDate);
    final activeRanges = _localShifts[selectedDateKey] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apni Shifts Set Karo (Agle 7 Din)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),

          // Next 7 Days Horizontal Calendar Strip
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _next7Days.length,
              itemBuilder: (context, index) {
                final day = _next7Days[index];
                final isSelected = _getDateKey(day) == selectedDateKey;
                final weekdayStr = _getWeekdayShort(day.weekday);
                final hasRanges = _localShifts.containsKey(_getDateKey(day));

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.gold : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasRanges && !isSelected ? AppColors.gold.withOpacity(0.4) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayStr,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // Active Selected Date Details Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFullDate(_selectedDate),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold.withOpacity(0.12),
                  foregroundColor: AppColors.gold,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Range', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: _addTimeRange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Slots list view inside card
          Expanded(
            child: activeRanges.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 48, color: Colors.white.withOpacity(0.08)),
                        const SizedBox(height: 12),
                        const Text(
                          'Is din koi shift nahi chuni gai',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: activeRanges.length,
                    itemBuilder: (context, index) {
                      final range = activeRanges[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.gold, size: 18),
                                const SizedBox(width: 12),
                                Text(
                                  "${range['start']} ➔ ${range['end']}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _removeTimeRange(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.secondary,
            ),
            onPressed: _isSaving ? null : _saveShifts,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
                : const Text('Save Karo'),
          ),
        ],
      ),
    );
  }

  String _getWeekdayShort(int day) {
    switch (day) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      default:
        return 'SUN';
    }
  }

  String _formatFullDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${_getWeekdayShort(dt.weekday)}, ${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }
}
