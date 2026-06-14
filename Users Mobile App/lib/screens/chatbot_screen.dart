import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/chatbot_provider.dart';
import '../providers/localization_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _conversationInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_conversationInitialized) return;
    _conversationInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final languageCode = context.read<LocalizationProvider>().currentLocale.languageCode;
      context.read<ChatbotProvider>().initializeConversation(
        context.read<AuthProvider>().currentUser,
        languageCode,
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    final chatbot = context.watch<ChatbotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('chatbotTab')),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.translate('chatbotGreeting'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lp.translate('chatbotHint'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SuggestionChip(
                          label: lp.translate('chatbotJobs'),
                          onTap: () => _sendSuggestion(
                            context,
                            lp.translate('chatbotJobs'),
                          ),
                        ),
                        _SuggestionChip(
                          label: lp.translate('chatbotSkills'),
                          onTap: () => _sendSuggestion(
                            context,
                            lp.translate('chatbotSkills'),
                          ),
                        ),
                        _SuggestionChip(
                          label: lp.translate('chatbotRegister'),
                          onTap: () => _sendSuggestion(
                            context,
                            lp.translate('chatbotRegister'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chatbot.messages.length,
                itemBuilder: (context, index) {
                  final message = chatbot.messages[index];
                  return _MessageBubble(message: message);
                },
              ),
            ),
            _buildComposer(context, chatbot, auth.currentUser),
          ],
        ),
      ),
    );
  }

  void _sendSuggestion(BuildContext context, String text) {
    _messageController.text = text;
    _sendMessage(context);
  }

  Future<void> _sendMessage(BuildContext context) async {
    final chatbot = context.read<ChatbotProvider>();
    final auth = context.read<AuthProvider>();
    final lp = context.read<LocalizationProvider>();
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await chatbot.sendMessage(
      text,
      auth.currentUser,
      lp.currentLocale.languageCode,
    );
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildComposer(
    BuildContext context,
    ChatbotProvider chatbot,
    dynamic user,
  ) {
    final lp = context.read<LocalizationProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: lp.translate('chatbotPlaceholder'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: chatbot.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: chatbot.isSending ? null : () => _sendMessage(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatbotMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade700 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: Colors.blue.shade800,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: Colors.blue.shade100),
    );
  }
}
