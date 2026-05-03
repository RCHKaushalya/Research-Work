import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/sms_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SmsService(),
      child: const SmsGatewayApp(),
    ),
  );
}

class SmsGatewayApp extends StatelessWidget {
  const SmsGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workforce SMS Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final smsService = context.watch<SmsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Gateway'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          Row(
            children: [
              Text(
                smsService.isRunning ? "ON" : "OFF",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: smsService.isRunning,
                onChanged: (value) {
                  if (value) {
                    smsService.start();
                  } else {
                    smsService.stop();
                  }
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          _buildStatusCard(context, smsService),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                if (smsService.logs.isNotEmpty)
                  Text(
                    'Last updated: ${DateTime.now().toString().split(' ').last.split('.').first}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
          
          // Logs List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: smsService.logs.isEmpty 
                ? const Center(child: Text("No activity yet", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: smsService.logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          smsService.logs[index],
                          style: const TextStyle(
                            fontFamily: 'monospace', 
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SmsService smsService) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      smsService.isRunning ? 'GATEWAY ACTIVE' : 'GATEWAY PAUSED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: smsService.isRunning ? Colors.green.shade700 : Colors.orange.shade800,
                        fontSize: 18,
                      ),
                    ),
                    const Text('Listening for commands...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Icon(
                  smsService.isRunning ? Icons.sensors : Icons.sensors_off,
                  color: smsService.isRunning ? Colors.green : Colors.grey,
                  size: 40,
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sent', smsService.sentCount.toString(), Icons.send_rounded, Colors.blue),
                _buildStatItem('Received', smsService.receivedCount.toString(), Icons.mark_email_unread_rounded, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
