import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../utils/theme.dart';
import '../customer/booking_details_screen.dart';
import '../chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final np = Provider.of<NotificationProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.navySurface,
        elevation: 0,
        actions: [
          if (np.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () => np.markAllAsRead(),
              child: Text('Mark all as read', 
                style: GoogleFonts.inter(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: np.loadNotifications,
        color: AppTheme.primaryColor,
        child: np.isLoading && np.notifications.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : np.notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: np.notifications.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final n = np.notifications[index];
                      return _NotificationTile(notification: n);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.textHint.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No notifications yet', 
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Stay tuned for updates on your bookings!', 
            style: GoogleFonts.inter(color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final np = Provider.of<NotificationProvider>(context, listen: false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: notification.isRead ? AppTheme.navySurface.withOpacity(0.5) : AppTheme.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        onTap: () {
          np.markAsRead(notification.id);
          _handleTap(context, notification);
        },
        contentPadding: const EdgeInsets.all(12),
        leading: _buildIcon(),
        title: Text(
          notification.title,
          style: GoogleFonts.inter(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            fontSize: 15,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(notification.createdAt),
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ),
        trailing: !notification.isRead 
          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle))
          : null,
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.booking:
        icon = Icons.calendar_today_rounded;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.payment:
        icon = Icons.account_balance_wallet_rounded;
        color = AppTheme.successColor;
        break;
      case NotificationType.chat:
        icon = Icons.chat_bubble_outline_rounded;
        color = AppTheme.accentColor;
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        color = AppTheme.secondaryColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleTap(BuildContext context, AppNotification n) {
    final screen = n.data['screen'];
    final bookingId = n.data['booking_id'];

    if (screen == 'booking_details' && bookingId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: bookingId)));
    } else if (screen == 'chat' && bookingId != null) {
      final otherName = n.data['other_user_name'] ?? 'User';
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(bookingId: bookingId, otherUserName: otherName)));
    }
  }
}
