import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/theme.dart';
import '../chat_screen.dart';

class MessagesListScreen extends StatelessWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BookingProvider>(context);
    final cp = Provider.of<ChatProvider?>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isProvider = auth.user?.role == 'provider';

    // Get bookings that are active or completed (where chat is relevant)
    final bookingsWithChat = bp.bookings.where((b) => 
      !b.isCancelled && (b.isAccepted || b.isInProgress || b.isCompleted)
    ).toList();

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.navyDeep,
        elevation: 0,
      ),
      body: bookingsWithChat.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: bookingsWithChat.length,
              itemBuilder: (context, index) {
                final booking = bookingsWithChat[index];
                final otherName = isProvider 
                    ? (booking.customer?.name ?? 'Customer')
                    : (booking.provider?.displayName ?? 'Provider');
                final unreadCount = cp?.unreadCounts[booking.id] ?? 0;

                return _ConversationTile(
                  bookingId: booking.id,
                  otherName: otherName,
                  unreadCount: unreadCount,
                  bookingStatus: booking.statusDisplay ?? '',
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppTheme.primaryColor.withAlpha(40)),
          const SizedBox(height: 20),
          Text('No conversations yet', style: GoogleFonts.inter(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Start a booking to chat with someone!', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String bookingId;
  final String otherName;
  final int unreadCount;
  final String bookingStatus;

  const _ConversationTile({
    required this.bookingId,
    required this.otherName,
    required this.unreadCount,
    required this.bookingStatus,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(bookingId: bookingId, otherUserName: otherName),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.primaryColor.withAlpha(40),
        child: Text(
          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherName,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            bookingStatus,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Tap to chat about this booking',
          style: GoogleFonts.inter(
            color: unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      trailing: unreadCount > 0
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.dividerColor),
    );
  }
}
