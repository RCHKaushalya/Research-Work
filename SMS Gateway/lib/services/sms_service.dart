import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:telephony/telephony.dart';
import 'package:flutter/foundation.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
onBackgroundMessage(SmsMessage message) async {
  // This runs in a separate isolate
  debugPrint("Background SMS received: ${message.body}");
}

class SmsService extends ChangeNotifier {
  final Telephony telephony = Telephony.instance;
  
  // Update this to your live backend URL
  final String backendUrl = "https://informal-worker.onrender.com"; 
  
  bool _isRunning = false;
  final List<String> _logs = [];
  int _sentCount = 0;
  int _receivedCount = 0;

  bool get isRunning => _isRunning;
  List<String> get logs => _logs;
  int get sentCount => _sentCount;
  int get receivedCount => _receivedCount;

  Timer? _pollingTimer;

  void addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    _logs.insert(0, "[$timestamp] $message");
    if (_logs.length > 100) _logs.removeLast();
    notifyListeners();
  }

  Future<void> start() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) {
      addLog("Permissions denied. Cannot start gateway.");
      return;
    }

    _isRunning = true;
    _startPolling();
    _setupIncomingListener();
    addLog("Gateway started");
    notifyListeners();
  }

  void stop() {
    _isRunning = false;
    _pollingTimer?.cancel();
    addLog("Gateway stopped");
    notifyListeners();
  }

  void _setupIncomingListener() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        addLog("Incoming SMS from ${message.address}");
        _receivedCount++;
        _forwardToBackend(message.address ?? "Unknown", message.body ?? "");
      },
      onBackgroundMessage: onBackgroundMessage,
    );
  }

  Future<void> _forwardToBackend(String from, String body) async {
    try {
      final response = await http.post(
        Uri.parse("$backendUrl/sms/incoming"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone_number": from, "message": body}),
      );
      if (response.statusCode == 200) {
        addLog("Forwarded to backend: Success");
      } else {
        addLog("Forwarded to backend: Failed (${response.statusCode})");
      }
    } catch (e) {
      addLog("Error forwarding to backend: $e");
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_isRunning) _checkPendingSms();
    });
  }

  Future<void> _checkPendingSms() async {
    try {
      final response = await http.get(Uri.parse("$backendUrl/sms/pending"));
      if (response.statusCode == 200) {
        final List<dynamic> messages = jsonDecode(response.body);
        if (messages.isNotEmpty) {
          addLog("Found ${messages.length} pending messages");
          for (var msg in messages) {
            await _sendSms(msg['id'], msg['phone_number'], msg['message']);
          }
        }
      }
    } catch (e) {
      addLog("Polling error: $e");
    }
  }

  Future<void> _sendSms(int id, String to, String body) async {
    try {
      await telephony.sendSms(
        to: to,
        message: body,
        statusListener: (SendStatus status) {
          if (status == SendStatus.SENT) {
            addLog("SMS to $to: Sent successfully");
            _markAsSent(id);
            _sentCount++;
            notifyListeners();
          } else {
            addLog("SMS to $to: Status -> $status");
          }
        },
      );
    } catch (e) {
      addLog("Error sending SMS: $e");
    }
  }

  Future<void> _markAsSent(int id) async {
    try {
      await http.post(Uri.parse("$backendUrl/sms/sent/$id"));
    } catch (e) {
      addLog("Error updating status for msg $id: $e");
    }
  }
}
