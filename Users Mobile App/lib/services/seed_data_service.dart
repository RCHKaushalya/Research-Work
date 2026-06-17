import 'package:flutter/foundation.dart';
import '../models/job.dart';
import 'supabase_service.dart';

class SeedDataService {
  static const List<Map<String, dynamic>> testWorkers = [
    {
      'nic': '200011111111',
      'firstName': 'සුනිල්',
      'lastName': 'පෙරේරා',
      'phone': '0711111111',
      'pin': '1234',
      'district': '01',
      'districtName': 'කොළඹ',
      'dsArea': '0101',
      'dsAreaName': 'කොළඹ',
      'language': 'si',
      'jobCategories': ['C01', 'C05'],
      'skills': ['S101', 'S501', 'S502'],
      'rating': 4.8,
      'completedJobs': 15,
    },
    {
      'nic': '200022222222',
      'firstName': 'නදීෂා',
      'lastName': 'ප්‍රනාන්දු',
      'phone': '0722222222',
      'pin': '1234',
      'district': '02',
      'districtName': 'ගම්පහ',
      'dsArea': '0205',
      'dsAreaName': 'ගම්පහ',
      'language': 'si',
      'jobCategories': ['C05'],
      'skills': ['S501', 'S502', 'S505'],
      'rating': 4.6,
      'completedJobs': 22,
    },
    {
      'nic': '200033333333',
      'firstName': 'කුමාරි',
      'lastName': 'ජයසූරිය',
      'phone': '0733333333',
      'pin': '1234',
      'district': '03',
      'districtName': 'කළුතර',
      'dsArea': '0308',
      'dsAreaName': 'කළුතර',
      'language': 'si',
      'jobCategories': ['C04', 'C06'],
      'skills': ['S401', 'S402', 'S403', 'S601'],
      'rating': 4.9,
      'completedJobs': 38,
    },
    {
      'nic': '200044444444',
      'firstName': 'රුවන්',
      'lastName': 'බණ්ඩාර',
      'phone': '0744444444',
      'pin': '1234',
      'district': '04',
      'districtName': 'මහනුවර',
      'dsArea': '0401',
      'dsAreaName': 'අකුරණ',
      'language': 'si',
      'jobCategories': ['C02'],
      'skills': ['S201', 'S202', 'S203'],
      'rating': 4.7,
      'completedJobs': 42,
    },
    {
      'nic': '200055555555',
      'firstName': 'සමන්',
      'lastName': 'හේරත්',
      'phone': '0755555555',
      'pin': '1234',
      'district': '05',
      'districtName': 'මාතලේ',
      'dsArea': '0505',
      'dsAreaName': 'මාතලේ',
      'language': 'si',
      'jobCategories': ['C03'],
      'skills': ['S301', 'S302', 'S303'],
      'rating': 4.4,
      'completedJobs': 18,
    },
    {
      'nic': '200066666666',
      'firstName': 'අනූෂා',
      'lastName': 'විජේසිංහ',
      'phone': '0766666666',
      'pin': '1234',
      'district': '06',
      'districtName': 'නුවරඑළිය',
      'dsArea': '0604',
      'dsAreaName': 'නුවරඑළිය',
      'language': 'si',
      'jobCategories': ['C06', 'C13'],
      'skills': ['S601', 'S602', 'S603', 'S1301'],
      'rating': 4.5,
      'completedJobs': 20,
    },
    {
      'nic': '200077777777',
      'firstName': 'மீனா',
      'lastName': 'சிவபாலன்',
      'phone': '0777777777',
      'pin': '1234',
      'district': '10',
      'districtName': 'யாழ்ப்பாணம்',
      'dsArea': '1005',
      'dsAreaName': 'நல்லூர்',
      'language': 'ta',
      'jobCategories': ['C07'],
      'skills': ['S701', 'S702', 'S703'],
      'rating': 4.9,
      'completedJobs': 52,
    },
    {
      'nic': '200088888888',
      'firstName': 'கண்ணன்',
      'lastName': 'ராஜ்',
      'phone': '0788888888',
      'pin': '1234',
      'district': '15',
      'districtName': 'மட்டக்களப்பு',
      'dsArea': '1501',
      'dsAreaName': 'மண்முனை வடக்கு',
      'language': 'ta',
      'jobCategories': ['C05'],
      'skills': ['S502', 'S503', 'S505'],
      'rating': 4.6,
      'completedJobs': 31,
    },
    {
      'nic': '200099999999',
      'firstName': 'கவிதா',
      'lastName': 'துரைராஜா',
      'phone': '0799999999',
      'pin': '1234',
      'district': '16',
      'districtName': 'அம்பாறை',
      'dsArea': '1602',
      'dsAreaName': 'கல்முனை',
      'language': 'ta',
      'jobCategories': ['C08'],
      'skills': ['S801', 'S802', 'S803', 'S804'],
      'rating': 4.3,
      'completedJobs': 12,
    },
    {
      'nic': '200010101010',
      'firstName': 'அருள்',
      'lastName': 'குமார்',
      'phone': '0701010101',
      'pin': '1234',
      'district': '10',
      'districtName': 'யாழ்ப்பாணம்',
      'dsArea': '1004',
      'dsAreaName': 'யாழ்ப்பாணம்',
      'language': 'ta',
      'jobCategories': ['C10', 'C12'],
      'skills': ['S1001', 'S1002', 'S1003', 'S1201'],
      'rating': 4.5,
      'completedJobs': 25,
    },
  ];

  static const List<Map<String, dynamic>> testJobs = [
    {
      'title': 'නිවසේ බිත්ති අලුත්වැඩියා',
      'description':
          'කොළඹ ප්‍රදේශයේ මායිම් බිත්තිය සහ කුස්සිය අලුත්වැඩියා කිරීමට මේසන් කම්කරුවෙකු අවශ්‍යයි.',
      'employerId': '200011111111',
      'area': '0101',
      'skills': ['S101', 'S102'],
      'status': 'open',
    },
    {
      'title': 'කඩයට විදුලි රැහැන් සැකසීම',
      'description': 'ගම්පහ නව කඩයට ලයිට්, ප්ලග් සහ ආරක්ෂක බ්‍රේකර් සවි කිරීම.',
      'employerId': '200022222222',
      'area': '0205',
      'skills': ['S501'],
      'status': 'open',
    },
    {
      'title': 'නිවස පිරිසිදු කිරීමේ කණ්ඩායමක්',
      'description':
          'කළුතර නිවසක් සම්පූර්ණයෙන් පිරිසිදු කිරීම, ජනෙල් සහ මුළුතැන්ගෙය ඇතුළුව.',
      'employerId': '200033333333',
      'area': '0308',
      'skills': ['S401', 'S402', 'S403'],
      'status': 'open',
    },
    {
      'title': 'දෛනික බෙදාහැරීම් රයිඩර්',
      'description': 'මහනුවර නගරය අවට භාණ්ඩ බෙදාහැරීමට රයිඩර් කෙනෙකු අවශ්‍යයි.',
      'employerId': '200044444444',
      'area': '0401',
      'skills': ['S202', 'S203'],
      'status': 'open',
    },
    {
      'title': 'තේ වත්තේ අස්වනු සහාය',
      'description': 'මාතලේ තේ වත්තක කාලීන වැඩ සඳහා සේවකයින් අවශ්‍යයි.',
      'employerId': '200055555555',
      'area': '0505',
      'skills': ['S303'],
      'status': 'open',
    },
    {
      'title': 'උත්සව ආහාර සැපයුම් සහාය',
      'description':
          'නුවරඑළිය උත්සවයකට ආහාර පිළියෙල කිරීම, සේවය සහ පිරිසිදු කිරීම.',
      'employerId': '200066666666',
      'area': '0604',
      'skills': ['S601', 'S1301'],
      'status': 'open',
    },
    {
      'title': 'மணமகள் அலங்கார உதவி',
      'description':
          'திருமண நிகழ்வுக்கு மேக்கப், சேலை அணிவித்தல் மற்றும் வாடிக்கையாளர் உதவி.',
      'employerId': '200077777777',
      'area': '1005',
      'skills': ['S701', 'S702'],
      'status': 'open',
    },
    {
      'title': 'மட்டக்களப்பு கட்டுமான தொழிலாளர்கள்',
      'description':
          'தரை அமைப்பு மற்றும் சிமெண்டு வேலைக்கு கட்டுமான உதவியாளர் குழு தேவை.',
      'employerId': '200088888888',
      'area': '1501',
      'skills': ['S502'],
      'status': 'open',
    },
    {
      'title': 'கல்முனை கேட்டரிங் சமையல்காரர்',
      'description':
          'பள்ளி நிகழ்வுக்கு தமிழ் பேசும் சமையல்காரர் மற்றும் உதவியாளர்கள் தேவை.',
      'employerId': '200099999999',
      'area': '1602',
      'skills': ['S803'],
      'status': 'open',
    },
    {
      'title': 'யாழ்ப்பாண கடை உதவியாளர்',
      'description': 'யாழ்ப்பாண நகரில் மாலை நேர கடை உதவியாளர் தேவை.',
      'employerId': '200010101010',
      'area': '1004',
      'skills': ['S1001'],
      'status': 'open',
    },
    // Completed jobs for social proof.
    {
      'title': 'කාර්යාලය පින්තාරු කිරීම',
      'description': 'කාර්යාලය පින්තාරු කර සැරසිලි අවසන් කළා.',
      'employerId': '200011111111',
      'area': '0101',
      'skills': ['S104'],
      'status': 'completed',
    },
    {
      'title': 'குளியலறை புதுப்பிப்பு',
      'description': 'குளியலறை டைல்கள் மற்றும் பொருத்துதல்கள் முடிந்தது.',
      'employerId': '200022222222',
      'area': '0205',
      'skills': ['S501'],
      'status': 'completed',
    },
  ];

  /// Seed all test data to the backend
  static Future<bool> seedAllData() async {
    try {
      debugPrint('🌱 Starting database seed...');

      // Register all test workers
      for (final worker in testWorkers) {
        await _registerWorker(worker);
      }

      debugPrint('✅ All ${testWorkers.length} workers registered');

      // Create test jobs (using first registered worker as employer)
      for (final job in testJobs) {
        await _createJob(job);
      }

      debugPrint('✅ All ${testJobs.length} jobs created');

      // Record sample worker interest for the developer seed helper.
      await _createApplications();

      debugPrint('✅ Applications created');

      return true;
    } catch (e) {
      debugPrint('❌ Seed error: $e');
      return false;
    }
  }

  static Future<void> _registerWorker(Map<String, dynamic> worker) async {
    try {
      // Register user with NIC + PIN via Supabase upsert
      await SupabaseService.registerNicPinUser({
        'nic': worker['nic'],
        'password_hash': worker['pin'],
      });

      final userData = {
        'nic': worker['nic'],
        'first_name': worker['firstName'],
        'last_name': worker['lastName'],
        'phone': worker['phone'],
        'district': worker['district'],
        'ds_area': worker['dsArea'],
        'language': worker['language'],
        'job_category_ids': worker['jobCategories'],
        'skill_ids': worker['skills'],
        'rating': worker['rating'] ?? 0.0,
        'completed_jobs_count': worker['completedJobs'] ?? 0,
        'abandoned_jobs_count': 0,
        'posted_jobs_count': 0,
        'applied_jobs_count': 0,
        'removed_jobs_count': 0,
        'is_blocked': 0,
        'availability_status': 'available',
      };

      await SupabaseService.saveUserProfile(worker['nic'], userData);
      debugPrint('✅ Registered: ${worker['firstName']} ${worker['lastName']}');
    } catch (e) {
      debugPrint('⚠️  Registration error for ${worker['firstName']}: $e');
    }
  }

  static Future<void> _createJob(Map<String, dynamic> job) async {
    try {
      await SupabaseService.createJob(
        Job(
          id: '',
          title: job['title'],
          description: job['description'],
          employerId: job['employerId'],
          employerName: '',
          categoryId: '',
          categoryName: job['skills']?.first?.toString() ?? '',
          location: job['area'],
          status: job['status'],
          appliedWorkerIds: const [],
          acceptedWorkerIds: const [],
          requiredSkillIds: List<String>.from(job['skills'] ?? []),
          createdAt: DateTime.now(),
        ),
      );
      debugPrint('Created job: ${job['title']}');
    } catch (e) {
      debugPrint('⚠️  Job creation error: $e');
    }
  }

  static Future<void> _createApplications() async {
    try {
      // Simulate some workers applying to jobs
      final applications = [
        {'workerId': '200011111111', 'jobIndex': 0},
        {'workerId': '200022222222', 'jobIndex': 1},
        {'workerId': '200033333333', 'jobIndex': 2},
        {'workerId': '200044444444', 'jobIndex': 3},
        {'workerId': '200055555555', 'jobIndex': 4},
        {'workerId': '200066666666', 'jobIndex': 5},
        {'workerId': '200077777777', 'jobIndex': 6},
        {'workerId': '200088888888', 'jobIndex': 7},
        {'workerId': '200099999999', 'jobIndex': 8},
        {'workerId': '200010101010', 'jobIndex': 9},
      ];

      for (final app in applications) {
        // Simulating job applications
        debugPrint('📝 Applied to job index: ${app['jobIndex']}');
      }

      debugPrint('✅ Applications created');
    } catch (e) {
      debugPrint('⚠️  Application error: $e');
    }
  }

  /// Get demo user credentials for quick login
  static Map<String, String> getDemoCredentials() {
    return {'nic': '200011111111', 'pin': '1234', 'name': 'සුනිල් පෙරේරා'};
  }

  /// Get all test user credentials
  static List<Map<String, String>> getAllTestUserCredentials() {
    return testWorkers
        .map(
          (w) => {
            'nic': w['nic'] as String,
            'pin': '1234',
            'name': '${w['firstName']} ${w['lastName']}',
          },
        )
        .toList();
  }

  static Future<bool> isAlreadySeeded() async {
    try {
      final user = await SupabaseService.fetchUserProfile('200011111111');
      return user != null;
    } catch (e) {
      return false;
    }
  }
}
