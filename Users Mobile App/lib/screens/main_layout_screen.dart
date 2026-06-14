import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen.dart';
import 'jobs_screen.dart';
import 'messages_screen.dart';
import 'chatbot_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../providers/alerts_provider.dart';
import '../providers/localization_provider.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({Key? key}) : super(key: key);

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    JobsScreen(),
    MessagesScreen(), // Contains Search as a sub-tab
    ChatbotScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final alertsProvider = context.watch<AlertsProvider>();
    final unreadCount = alertsProvider.unreadCount;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: lp.translate('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline),
            activeIcon: const Icon(Icons.work),
            label: lp.translate('jobTab'),
          ),
          BottomNavigationBarItem(
            icon: unreadCount > 0
                ? Badge(
                    label: Text(unreadCount.toString()),
                    child: const Icon(Icons.message_outlined),
                  )
                : const Icon(Icons.message_outlined),
            activeIcon: const Icon(Icons.message),
            label: lp.translate('messageTab'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy_outlined),
            activeIcon: const Icon(Icons.smart_toy),
            label: lp.translate('chatbotTab'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: lp.translate('profileTab'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: lp.translate('settingsTab'),
          ),
        ],
      ),
    );
  }
}
