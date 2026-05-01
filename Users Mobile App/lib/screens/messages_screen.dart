import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lp.translate('messageTab')),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            tabs: [
              Tab(text: lp.translate('alerts')),
              Tab(text: lp.translate('communities')),
              Tab(text: lp.translate('searchTab')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.read<AlertsProvider>().markAllAsRead(),
              child: Text(lp.translate('markAllRead')),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAlertsList(context, lp),
            _buildCommunitiesList(lp, user),
            const SearchScreen(), // Search is now inside Messages
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(BuildContext context, LocalizationProvider lp) {
    final alertsProvider = context.watch<AlertsProvider>();
    final notifications = alertsProvider.notifications;

    if (notifications.isEmpty) {
      return Center(child: Text(lp.translate('noJobsFound')));
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return ListTile(
          leading: const Icon(Icons.notifications, color: Colors.blue),
          title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
          subtitle: Text(notification.body),
          onTap: () => context.read<AlertsProvider>().markAsRead(notification.id),
        );
      },
    );
  }

  Widget _buildCommunitiesList(LocalizationProvider lp, dynamic user) {
    final categoryIds = user?.jobCategoryIds ?? [];
    if (categoryIds.isEmpty) return Center(child: Text(lp.translate('selectJobCategory')));

    return ListView.builder(
      itemCount: categoryIds.length,
      itemBuilder: (context, index) {
        final catId = categoryIds[index];
        final option = RegistrationCatalog.getOptionById(catId);
        final label = option?.labelFor(lp.currentLocale.languageCode) ?? catId;

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: Text(option?.icon ?? '👥', style: const TextStyle(fontSize: 20)),
          ),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Join the $label community'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(title: label))),
        );
      },
    );
  }
}
