class Message {
  final String id;
  final String bookingId;
  final String senderId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'sender_id': senderId,
      'text': text,
    };
  }
}
