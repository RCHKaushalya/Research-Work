import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';
import '../services/supabase_service.dart';

/// ChatProvider — migrated from Firestore to Supabase REST + Realtime.
///
/// Tables expected:
///   chats         (id, job_id, participant_ids text[], type, last_message,
///                  last_message_time, title)
///   chat_messages (id uuid, chat_id, sender_id, text, created_at)
class ChatProvider extends ChangeNotifier {
  SupabaseClient get _db => SupabaseService.client;

  // ─── In-memory state (Realtime streams) ────────────────────────────────

  List<Chat> _myChats = [];
  List<Chat> get myChats => List.unmodifiable(_myChats);

  List<ChatMessage> _currentMessages = [];
  List<ChatMessage> get currentMessages => List.unmodifiable(_currentMessages);

  RealtimeChannel? _chatChannel;
  RealtimeChannel? _messageChannel;

  // ─── Chats ─────────────────────────────────────────────────────────────

  /// Load and subscribe to all chats where [myId] is a participant.
  Future<void> subscribeToMyChats(String myId) async {
    final normalizedId = myId.toUpperCase();

    // Initial load
    await _loadMyChats(normalizedId);

    // Realtime subscription
    _chatChannel?.unsubscribe();
    _chatChannel = _db
        .channel('chats:$normalizedId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (payload) async {
            await _loadMyChats(normalizedId);
          },
        )
        .subscribe();
  }

  Future<void> _loadMyChats(String normalizedId) async {
    try {
      // Supabase: filter where participant_ids array contains the NIC
      final response = await _db
          .from('chats')
          .select()
          .contains('participant_ids', [normalizedId])
          .order('last_message_time', ascending: false);

      _myChats = (response as List<dynamic>)
          .map((row) => Chat.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider._loadMyChats error: $e');
    }
  }

  // ─── Messages ──────────────────────────────────────────────────────────

  /// Load and subscribe to messages in [chatId].
  Future<void> subscribeToMessages(String chatId) async {
    await _loadMessages(chatId);

    _messageChannel?.unsubscribe();
    _messageChannel = _db
        .channel('chat_messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async {
            await _loadMessages(chatId);
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages(String chatId) async {
    try {
      final response = await _db
          .from('chat_messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false);

      _currentMessages = (response as List<dynamic>)
          .map((row) =>
              ChatMessage.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('ChatProvider._loadMessages error: $e');
    }
  }

  void unsubscribe() {
    _chatChannel?.unsubscribe();
    _messageChannel?.unsubscribe();
    _chatChannel = null;
    _messageChannel = null;
  }

  // ─── Send message ───────────────────────────────────────────────────────

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text,
  ) async {
    final normalizedSenderId = senderId.toUpperCase();
    if (text.trim().isEmpty) return;

    final now = DateTime.now().toIso8601String();

    await _db.from('chat_messages').insert({
      'chat_id': chatId,
      'sender_id': normalizedSenderId,
      'text': text.trim(),
      'created_at': now,
    });

    await _db.from('chats').update({
      'last_message': text.trim(),
      'last_message_time': now,
    }).eq('id', chatId);
  }

  // ─── Get or create chats ────────────────────────────────────────────────

  Future<String> getOrCreateDirectChat(
    String myId,
    String otherId,
  ) async {
    final participants = [myId.toUpperCase(), otherId.toUpperCase()]..sort();
    final chatId = 'direct_${participants[0]}_${participants[1]}';

    final existing = await _db
        .from('chats')
        .select('id')
        .eq('id', chatId)
        .limit(1);

    if ((existing as List).isEmpty) {
      await _db.from('chats').insert({
        'id': chatId,
        'participant_ids': participants,
        'type': 'direct',
        'last_message_time': DateTime.now().toIso8601String(),
      });
    }
    return chatId;
  }

  Future<String> getOrCreateGroupChat(
    String jobId,
    List<String> participants,
    String jobTitle,
  ) async {
    final normalizedParticipants =
        participants.map((p) => p.toUpperCase()).toList();
    final chatId = 'group_$jobId';

    final existing = await _db
        .from('chats')
        .select('id')
        .eq('id', chatId)
        .limit(1);

    if ((existing as List).isEmpty) {
      await _db.from('chats').insert({
        'id': chatId,
        'job_id': jobId,
        'participant_ids': normalizedParticipants,
        'type': 'group',
        'title': 'Group: $jobTitle',
        'last_message_time': DateTime.now().toIso8601String(),
      });
    } else {
      await _db.from('chats').update({
        'participant_ids': normalizedParticipants,
      }).eq('id', chatId);
    }
    return chatId;
  }
}
