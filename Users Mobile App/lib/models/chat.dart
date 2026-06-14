// Chat model — migrated from Firestore to Supabase.
// Data is stored in the `chats` and `chat_messages` tables.

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'chat_id': chatId,
    'sender_id': senderId,
    'text': text,
    'created_at': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: (data['id'] ?? '').toString(),
      chatId: (data['chat_id'] ?? '').toString(),
      senderId: (data['sender_id'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      timestamp: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Chat {
  final String id;
  final String? jobId;
  final List<String> participantIds;
  final String type; // 'direct' or 'group'
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? title;

  Chat({
    required this.id,
    this.jobId,
    required this.participantIds,
    required this.type,
    this.lastMessage,
    this.lastMessageTime,
    this.title,
  });

  factory Chat.fromMap(Map<String, dynamic> data) {
    List<String> participants = [];
    final raw = data['participant_ids'];
    if (raw is List) {
      participants = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.isNotEmpty) {
      // Stored as comma-separated fallback
      participants = raw.split(',').map((e) => e.trim()).toList();
    }

    return Chat(
      id: (data['id'] ?? '').toString(),
      jobId: data['job_id']?.toString(),
      participantIds: participants,
      type: (data['type'] ?? 'direct').toString(),
      lastMessage: data['last_message']?.toString(),
      lastMessageTime: data['last_message_time'] != null
          ? DateTime.tryParse(data['last_message_time'].toString())
          : null,
      title: data['title']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    if (jobId != null) 'job_id': jobId,
    'participant_ids': participantIds,
    'type': type,
    if (lastMessage != null) 'last_message': lastMessage,
    if (lastMessageTime != null)
      'last_message_time': lastMessageTime!.toIso8601String(),
    if (title != null) 'title': title,
  };
}
