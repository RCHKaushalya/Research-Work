import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../providers/alerts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import '../providers/chat_provider.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    
    return DefaultTabController(
      length: 4,
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
              Tab(text: lp.translate('chats')),
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
            _buildChatList(context, auth),
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
          subtitle: Text(lp.translate('communities')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
            chatId: 'community_$catId', 
            title: label
          ))),
        );
      },
    );
  }
  Widget _buildChatList(BuildContext context, AuthProvider auth) {
    final chatProvider = context.watch<ChatProvider>();
    final lp = context.read<LocalizationProvider>();
    final myId = auth.currentUser!.nic;

    // Subscribe whenever this widget is built with a logged-in user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatProvider.subscribeToMyChats(myId);
    });

    final chats = chatProvider.myChats;

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(lp.translate('noChatsFound'), style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: chat.type == 'group' ? Colors.orange.shade100 : Colors.blue.shade100,
            child: Icon(chat.type == 'group' ? Icons.group : Icons.person, 
                       color: chat.type == 'group' ? Colors.orange : Colors.blue),
          ),
          title: Text(chat.type == 'group' ? lp.translate('groupChat') : lp.translate('privateChat')),
          subtitle: Text(chat.lastMessage ?? lp.translate('startChat'), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: chat.lastMessageTime != null 
              ? Text('${chat.lastMessageTime!.hour}:${chat.lastMessageTime!.minute.toString().padLeft(2, '0')}', 
                     style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
              chatId: chat.id, 
              title: chat.type == 'group' ? lp.translate('groupChat') : lp.translate('privateChat')
            )));
          },
        );
      },
    );
  }
}
