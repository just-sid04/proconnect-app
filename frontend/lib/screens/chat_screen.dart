import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final senderId = auth.user?.id;
    if (senderId == null) return;

    _msgController.clear();

    try {
      await ChatService.sendMessage(
        bookingId: widget.bookingId,
        senderId: senderId,
        text: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final myId = auth.user?.id;

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppTheme.navyDeep,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withAlpha(40),
              child: Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Active Booking',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService.getMessagesStream(widget.bookingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.primaryColor.withAlpha(60)),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                        Text('Say hi to start the conversation!', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary.withAlpha(150))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == myId;

                    return _ChatBubble(
                      message: msg,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      decoration: BoxDecoration(
        color: AppTheme.navyDeep,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.navySurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe ? AppTheme.primaryGradient : null,
              color: isMe ? null : AppTheme.navySurface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
              border: isMe ? null : Border.all(color: AppTheme.dividerColor),
              boxShadow: isMe ? AppTheme.glowShadow(AppTheme.primaryColor, blur: 10, spread: -2) : null,
            ),
            child: Text(
              message.text,
              style: GoogleFonts.inter(
                color: isMe ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('hh:mm a').format(message.createdAt),
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
