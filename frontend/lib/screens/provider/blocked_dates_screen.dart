import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';

class BlockedDatesScreen extends StatefulWidget {
  const BlockedDatesScreen({super.key});

  @override
  State<BlockedDatesScreen> createState() => _BlockedDatesScreenState();
}

class _BlockedDatesScreenState extends State<BlockedDatesScreen> {
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final List<Map<String, dynamic>> _blockedSlots = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedSlots();
  }

  Future<void> _loadBlockedSlots() async {
    setState(() => _isLoading = true);
    try {
      final pp = Provider.of<ProviderProvider>(context, listen: false);
      if (pp.currentProvider == null) await pp.getMyProviderProfile();
      final providerId = pp.currentProvider!.id;

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('provider_blocked_slots')
          .select()
          .eq('provider_id', providerId)
          .gte('end_at', DateTime.now().toIso8601String())
          .order('start_at', ascending: true);

      setState(() {
        _blockedSlots.clear();
        _blockedSlots.addAll(List<Map<String, dynamic>>.from(response));
      });
    } catch (e) {
      debugPrint('Error loading blocked slots: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addBlockedSlot(DateTime date) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navySurface,
        title: Text('Block Date', style: GoogleFonts.inter(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark ${DateFormat('MMM dd, yyyy').format(date)} as unavailable?',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reason (e.g. Holiday)',
                labelStyle: TextStyle(color: AppTheme.textHint),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.dividerColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Block Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final pp = Provider.of<ProviderProvider>(context, listen: false);
        final providerId = pp.currentProvider!.id;
        final supabase = Supabase.instance.client;

        // Block the whole day from 00:00 to 23:59
        final start = DateTime(date.year, date.month, date.day, 0, 0);
        final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

        await supabase.from('provider_blocked_slots').insert({
          'provider_id': providerId,
          'start_at': start.toIso8601String(),
          'end_at': end.toIso8601String(),
          'reason': reasonController.text.trim().isEmpty
              ? 'Unavailable'
              : reasonController.text.trim(),
        });

        await _loadBlockedSlots();
      } catch (e) {
        debugPrint('Error blocking date: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBlockedSlot(String id) async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('provider_blocked_slots').delete().eq('id', id);
      await _loadBlockedSlots();
    } catch (e) {
      debugPrint('Error deleting blocked slot: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: Text('Holidays & Time Off',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.navySurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white70),
                outsideTextStyle: TextStyle(color: AppTheme.textHint),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.bold),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: Colors.white),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _addBlockedSlot(selectedDay);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text('Scheduled Time Off',
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _blockedSlots.isEmpty
                ? Center(
                    child: Text('No holidays planned yet',
                        style: GoogleFonts.inter(color: AppTheme.textHint)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _blockedSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _blockedSlots[index];
                      final start = DateTime.parse(slot['start_at']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.navySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.event_busy_rounded,
                                  color: AppTheme.errorColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, MMM dd').format(start),
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    slot['reason'] ?? 'Unavailable',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteBlockedSlot(slot['id']),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppTheme.textSecondary, size: 20),
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
