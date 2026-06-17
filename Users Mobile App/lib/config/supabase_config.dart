class SupabaseConfig {
  static const String url = 'https://pkzdexdkgjjejctsgnbz.supabase.co';
  static const String anonKey =
      'sb_publishable_m6X8NGNqr0JFKSH5VcV1rw_rtiCKaXt';

  static const String smsGatewayUrl = String.fromEnvironment(
    'SMS_GATEWAY_URL',
    defaultValue: 'https://app.sms-gateway.app/services/send.php',
  );
  static const String smsGatewayApiKey = String.fromEnvironment(
    'SMS_GATEWAY_API_KEY',
    defaultValue: '',
  );
  static const String smsGatewayDevices = String.fromEnvironment(
    'SMS_GATEWAY_DEVICES',
    defaultValue: '10959|1',
  );
}
