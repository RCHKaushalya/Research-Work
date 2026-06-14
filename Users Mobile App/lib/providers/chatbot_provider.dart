import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';

class ChatbotMessage {
  ChatbotMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  final bool isUser;
  final String text;
  final DateTime timestamp;
}

class ChatbotProvider extends ChangeNotifier {
  final List<ChatbotMessage> _messages = [];
  bool _isSending = false;

  List<ChatbotMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  void initializeConversation(AppUser? user, String languageCode) {
    if (_messages.isNotEmpty) return;
    _messages.add(
      ChatbotMessage(
        isUser: false,
        text: _buildGreeting(user, languageCode),
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendMessage(
    String text,
    AppUser? user,
    String languageCode,
  ) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(
      ChatbotMessage(isUser: true, text: trimmed, timestamp: DateTime.now()),
    );
    _isSending = true;
    notifyListeners();

    try {
      final reply = await _generateReply(trimmed, user, languageCode);
      _messages.add(
        ChatbotMessage(isUser: false, text: reply, timestamp: DateTime.now()),
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String _buildGreeting(AppUser? user, String languageCode) {
    if (user == null) {
      return _localizedText(
        languageCode: languageCode,
        en: 'Hello. Ask me for job search, registration, skills, or application guidance.',
        si: 'ආයුබෝවන්. රැකියා සෙවීම, ලියාපදිංචිය, කුසලතා, හෝ අයදුම් කිරීම ගැන මගෙන් අහන්න.',
        ta: 'வணக்கம். வேலை தேடல், பதிவு, திறன்கள், அல்லது விண்ணப்ப உதவி பற்றி கேளுங்கள்.',
      );
    }

    final skillSummary = user.skillNames.isNotEmpty
        ? user.skillNames.take(3).join(', ')
        : _localizedText(
            languageCode: languageCode,
            en: 'your current skills',
            si: 'ඔබගේ වත්මන් කුසලතා',
            ta: 'உங்கள் தற்போதைய திறன்கள்',
          );
    final district = user.districtName?.isNotEmpty == true
        ? user.districtName!
        : _localizedText(
            languageCode: languageCode,
            en: 'your area',
            si: 'ඔබගේ ප්‍රදේශය',
            ta: 'உங்கள் பகுதி',
          );

    return _localizedText(
      languageCode: languageCode,
      en: 'Hi ${user.firstName}. I can help you find work, improve $skillSummary, and plan jobs around $district.',
      si: '${user.firstName} ඔබට සුබ පැතුම්. රැකියා සොයා ගැනීමට, $skillSummary වැඩිදියුණු කිරීමට, සහ $district වටා වැඩ සැලසුම් කිරීමට මට උදව් කළ හැකිය.',
      ta: '${user.firstName} வணக்கம். வேலைகளை கண்டுபிடிக்க, $skillSummary மேம்படுத்த, மற்றும் $district சுற்றியுள்ள வேலைகளை திட்டமிட உதவுகிறேன்.',
    );
  }

  Future<String> _generateReply(
    String prompt,
    AppUser? user,
    String languageCode,
  ) async {
    const apiUrl = String.fromEnvironment('CHATBOT_API_URL');
    if (apiUrl.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse(apiUrl),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt': prompt,
                'context': _buildSystemPrompt(user, languageCode),
                'profile': _profileContext(user),
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final payload = jsonDecode(response.body) as Map<String, dynamic>;
          final answer = payload['answer']?.toString().trim();
          if (answer != null && answer.isNotEmpty) {
            return answer;
          }
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('Chatbot API error: $error');
        }
      }
    }

    return _fallbackReply(prompt, user, languageCode);
  }

  String _buildSystemPrompt(AppUser? user, String languageCode) {
    final profile = _profileContext(user);
    return '''
You are a career guidance assistant for informal workers in Sri Lanka.
Speak in the user's preferred language when possible.
Be practical, short, and encouraging.
User profile: $profile
Help with registration, job search, applications, skills, and profile improvement.
''';
  }

  String _localizedText({
    required String languageCode,
    required String en,
    String? si,
    String? ta,
  }) {
    if (languageCode == 'si' && si != null && si.isNotEmpty) return si;
    if (languageCode == 'ta' && ta != null && ta.isNotEmpty) return ta;
    return en;
  }

  Map<String, dynamic> _profileContext(AppUser? user) {
    return {
      'name': user?.fullName ?? '',
      'district': user?.districtName ?? '',
      'skills': user?.skillNames ?? const [],
      'categories': user?.jobCategoryNames ?? const [],
    };
  }

  String _fallbackReply(String prompt, AppUser? user, String languageCode) {
    final lower = prompt.toLowerCase();
    final name =
        user?.firstName ??
        _localizedText(
          languageCode: languageCode,
          en: 'there',
          si: 'ඔබ',
          ta: 'நீங்கள்',
        );
    final district = user?.districtName?.isNotEmpty == true
        ? user!.districtName!
        : _localizedText(
            languageCode: languageCode,
            en: 'your area',
            si: 'ඔබගේ ප්‍රදේශය',
            ta: 'உங்கள் பகுதி',
          );
    final skills = user?.skillNames.isNotEmpty == true
        ? user!.skillNames.take(3).join(', ')
        : _localizedText(
            languageCode: languageCode,
            en: 'your current skills',
            si: 'ඔබගේ වත්මන් කුසලතා',
            ta: 'உங்கள் தற்போதைய திறன்கள்',
          );

    if (lower.contains('register') ||
        lower.contains('signup') ||
        lower.contains('sign up') ||
        lower.contains('ලියාපදිංචි') ||
        lower.contains('பதிவு')) {
      return _localizedText(
        languageCode: languageCode,
        en: 'Hi $name. To register, complete your NIC, phone, location, category, skills, and photo details. Use a strong PIN and make sure your district is correct.',
        si: '$name, ලියාපදිංචි වීමට NIC, දුරකථන අංකය, ස්ථානය, වර්ගය, කුසලතා, සහ ඡායාරූප තොරතුරු පුරවන්න. ශක්තිමත් PIN එකක් භාවිතා කරන්න, දිස්ත්‍රික්කය නිවැරදි බව තහවුරු කරන්න.',
        ta: '$name, பதிவு செய்ய NIC, தொலைபேசி எண், இடம், வகை, திறன்கள், மற்றும் புகைப்பட விவரங்களை நிரப்புங்கள். வலுவான PIN ஐ பயன்படுத்தி, மாவட்டம் சரியாக உள்ளதைக் உறுதிப்படுத்துங்கள்.',
      );
    }
    if (lower.contains('job') ||
        lower.contains('work') ||
        lower.contains('රැකියා') ||
        lower.contains('வேலை')) {
      return _localizedText(
        languageCode: languageCode,
        en: 'Hi $name. Open the Jobs tab, filter by $district, and apply to jobs that match $skills. Keep your profile updated so matching improves.',
        si: '$name, Jobs ටැබ් එක විවෘත කර $district අනුව පෙරහන් කරන්න. $skills ට ගැලපෙන රැකියා වලට අයදුම් කරන්න. ඔබගේ පැතිකඩ යාවත්කාලීනව තබන්න.',
        ta: '$name, Jobs தாவலைத் திறந்து $district மூலம் வடிகட்டுங்கள். $skills உடன் பொருந்தும் வேலைகளுக்கு விண்ணப்பிக்கவும். உங்கள் சுயவிவரத்தை புதுப்பித்து வையுங்கள்.',
      );
    }
    if (lower.contains('skill') ||
        lower.contains('කුසලතා') ||
        lower.contains('திறன்')) {
      return _localizedText(
        languageCode: languageCode,
        en: 'Your current profile already suggests a good base. Focus on the skills that most often appear in jobs near $district, and update your profile after each new skill.',
        si: 'ඔබගේ පැතිකඩට දැනටමත් හොඳ ආරම්භයක් ඇත. $district අවට රැකියා වල බොහෝවිට පෙනෙන කුසලතා මත අවධානය යොමු කරන්න.',
        ta: 'உங்கள் தற்போதைய சுயவிவரம் நல்ல அடிப்படை காட்டுகிறது. $district அருகிலுள்ள வேலைகளில் அதிகம் தேவைப்படும் திறன்களில் கவனம் செலுத்துங்கள்.',
      );
    }
    if (lower.contains('apply') ||
        lower.contains('application') ||
        lower.contains('අයදුම්') ||
        lower.contains('விண்ணப்ப')) {
      return _localizedText(
        languageCode: languageCode,
        en: 'To apply, open a suitable job and tap Apply. Keep your district and skills aligned with the job description to improve approval chances.',
        si: 'අයදුම් කිරීමට සුදුසු රැකියාවක් විවෘත කර Apply ඔබන්න. දිස්ත්‍රික්කය සහ කුසලතා රැකියා විස්තරයට ගැලපෙන ලෙස තබන්න.',
        ta: 'விண்ணப்பிக்க, பொருத்தமான வேலையைத் திறந்து Apply ஐத் தட்டவும். மாவட்டம் மற்றும் திறன்களை வேலை விவரத்துடன் ஒத்துப்போக வைத்தால் வாய்ப்பு அதிகரிக்கும்.',
      );
    }
    return _localizedText(
      languageCode: languageCode,
      en: 'I can help with jobs, registration, applications, and skills. Ask me something specific, such as "what jobs suit me" or "how do I improve my profile".',
      si: 'මට රැකියා, ලියාපදිංචිය, අයදුම් කිරීම, සහ කුසලතා ගැන උදව් කළ හැකිය. "මට ගැලපෙන රැකියා මොනවාද" වැනි ප්‍රශ්නයක් අසන්න.',
      ta: 'வேலைகள், பதிவு, விண்ணப்பங்கள், மற்றும் திறன்கள் குறித்து உதவ முடியும். "எனக்கு பொருந்தும் வேலைகள் என்ன" போன்ற கேள்விகளை கேளுங்கள்.',
    );
  }
}
