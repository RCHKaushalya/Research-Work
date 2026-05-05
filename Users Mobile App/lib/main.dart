import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/localization_provider.dart';
import 'providers/job_provider.dart';
import 'providers/alerts_provider.dart';
import 'screens/main_layout_screen.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
      ],
      child: const WorkforceApp(),
    ),
  );
}

class WorkforceApp extends StatelessWidget {
  const WorkforceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationProvider, AuthProvider>(
      builder: (context, lp, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Workforce App',
          locale: lp.currentLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('si'), Locale('ta')],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2196F3),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              surfaceTintColor: Colors.white,
            ),
          ),
          home: auth.isInitialized
              ? (auth.isAuthenticated ? const MainLayoutScreen() : const LandingScreen())
              : const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
