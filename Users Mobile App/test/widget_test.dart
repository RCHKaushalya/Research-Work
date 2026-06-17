import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:workforce_app/main.dart';
import 'package:workforce_app/providers/alerts_provider.dart';
import 'package:workforce_app/providers/auth_provider.dart';
import 'package:workforce_app/providers/chat_provider.dart';
import 'package:workforce_app/providers/chatbot_provider.dart';
import 'package:workforce_app/providers/job_provider.dart';
import 'package:workforce_app/providers/localization_provider.dart';

void main() {
  testWidgets('App root builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => JobProvider()),
          ChangeNotifierProvider(create: (_) => AlertsProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => ChatbotProvider()),
        ],
        child: const WorkforceApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
