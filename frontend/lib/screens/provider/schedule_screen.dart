import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  bool _isLoading = true;
  final List<Map<String, dynamic>> _schedule = [];
  final List<String> _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final pp = Provider.of<ProviderProvider>(context, listen: false);
      if (pp.currentProvider == null) await pp.getMyProviderProfile();
      final providerId = pp.currentProvider!.id;

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('provider_schedules')
          .select()
          .eq('provider_id', providerId)
          .order('day_of_week', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      // Initialize with all days empty
      _schedule.clear();
      for (int i = 0; i < 7; i++) {
        final existing = data.firstWhere((day) => day['day_of_week'] == i,
            orElse: () => null);
        if (existing != null) {
          _schedule.add({
            'day_of_week': i,
            'is_active': existing['is_active'] ?? true,
            'start_time': existing['start_time'],
            'end_time': existing['end_time'],
            'id': existing['id'],
          });
        } else {
          _schedule.add({
            'day_of_week': i,
            'is_active': false,
            'start_time': '09:00:00',
            'end_time': '18:00:00',
            'id': null,
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      final pp = Provider.of<ProviderProvider>(context, listen: false);
      final providerId = pp.currentProvider!.id;
      final supabase = Supabase.instance.client;

      for (var day in _schedule) {
        if (day['id'] != null || day['is_active'] == true) {
          // If it exists or is now active, upsert it
          await supabase.from('provider_schedules').upsert({
            if (day['id'] != null) 'id': day['id'],
            'provider_id': providerId,
            'day_of_week': day['day_of_week'],
            'start_time': day['start_time'],
            'end_time': day['end_time'],
            'is_active': day['is_active'],
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(int index, bool isStart) async {
    final day = _schedule[index];
    final initialTimeStr = isStart ? day['start_time'] : day['end_time'];
    final parts = initialTimeStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.navySurface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      setState(() {
        if (isStart) {
          _schedule[index]['start_time'] = timeStr;
        } else {
          _schedule[index]['end_time'] = timeStr;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: Text('My Schedule',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _saveSchedule,
              icon: const Icon(Icons.check, color: AppTheme.successColor),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = _schedule[index];
                final isActive = day['is_active'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryColor.withAlpha(100)
                          : AppTheme.dividerColor,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _days[index],
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            activeColor: AppTheme.primaryColor,
                            value: isActive,
                            onChanged: (val) {
                              setState(() => day['is_active'] = val);
                            },
                          ),
                        ],
                      ),
                      if (isActive) ...[
                        const Divider(height: 24, color: AppTheme.dividerColor),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerBox(
                                label: 'Starts at',
                                time: day['start_time'].substring(0, 5),
                                onTap: () => _selectTime(index, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TimePickerBox(
                                label: 'Ends at',
                                time: day['end_time'].substring(0, 5),
                                onTap: () => _selectTime(index, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TimePickerBox extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerBox({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.navyDeep,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
