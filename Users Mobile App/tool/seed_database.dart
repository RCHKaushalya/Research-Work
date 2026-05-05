import '../lib/services/seed_data_service.dart';

Future<void> main() async {
  final alreadySeeded = await SeedDataService.isAlreadySeeded();
  if (alreadySeeded) {
    print('Seed skipped: demo data already exists.');
    final demo = SeedDataService.getDemoCredentials();
    print('Demo login -> NIC: ${demo['nic']} PIN: ${demo['pin']}');
    return;
  }

  final success = await SeedDataService.seedAllData();
  if (!success) {
    print('Seed failed.');
    return;
  }

  print('Seed completed successfully.');
  final demo = SeedDataService.getDemoCredentials();
  print('Demo login -> NIC: ${demo['nic']} PIN: ${demo['pin']}');
}
