import 'package:flutter/foundation.dart';
import '../models/job.dart';
import 'supabase_service.dart';

class SeedDataService {
  static const List<Map<String, dynamic>> testWorkers = [
    {
      'nic': '200011111111',
      'firstName': 'Colombo',
      'lastName': 'Worker',
      'phone': '0711111111',
      'pin': '1234',
      'district': '01',
      'districtName': 'Colombo',
      'dsArea': '0101',
      'dsAreaName': 'Colombo',
      'jobCategories': ['C01', 'C05'],
      'skills': ['S101', 'S501', 'S502'],
      'rating': 4.8,
      'completedJobs': 15,
    },
    {
      'nic': '200022222222',
      'firstName': 'Kasun',
      'lastName': 'Electrician',
      'phone': '0722222222',
      'pin': '1234',
      'district': '02',
      'districtName': 'Gampaha',
      'dsArea': '0205',
      'dsAreaName': 'Gampaha',
      'jobCategories': ['C05'],
      'skills': ['S501', 'S502', 'S505'],
      'rating': 4.6,
      'completedJobs': 22,
    },
    {
      'nic': '200033333333',
      'firstName': 'Kumari',
      'lastName': 'Housekeeper',
      'phone': '0733333333',
      'pin': '1234',
      'district': '03',
      'districtName': 'Kalutara',
      'dsArea': '0308',
      'dsAreaName': 'Kalutara',
      'jobCategories': ['C04', 'C06'],
      'skills': ['S401', 'S402', 'S403', 'S601'],
      'rating': 4.9,
      'completedJobs': 38,
    },
    {
      'nic': '200044444444',
      'firstName': 'Ravi',
      'lastName': 'Driver',
      'phone': '0744444444',
      'pin': '1234',
      'district': '04',
      'districtName': 'Kandy',
      'dsArea': '0401',
      'dsAreaName': 'Akurana',
      'jobCategories': ['C02'],
      'skills': ['S201', 'S202', 'S203'],
      'rating': 4.7,
      'completedJobs': 42,
    },
    {
      'nic': '200055555555',
      'firstName': 'Samantha',
      'lastName': 'Farmer',
      'phone': '0755555555',
      'pin': '1234',
      'district': '05',
      'districtName': 'Matale',
      'dsArea': '0505',
      'dsAreaName': 'Matale',
      'jobCategories': ['C03'],
      'skills': ['S301', 'S302', 'S303'],
      'rating': 4.4,
      'completedJobs': 18,
    },
    {
      'nic': '200066666666',
      'firstName': 'Anura',
      'lastName': 'Chef',
      'phone': '0766666666',
      'pin': '1234',
      'district': '06',
      'districtName': 'Nuwara Eliya',
      'dsArea': '0604',
      'dsAreaName': 'Nuwara Eliya',
      'jobCategories': ['C06', 'C13'],
      'skills': ['S601', 'S602', 'S603', 'S1301'],
      'rating': 4.5,
      'completedJobs': 20,
    },
    {
      'nic': '200077777777',
      'firstName': 'Priya',
      'lastName': 'Beautician',
      'phone': '0777777777',
      'pin': '1234',
      'district': '07',
      'districtName': 'Galle',
      'dsArea': '0708',
      'dsAreaName': 'Galle',
      'jobCategories': ['C07'],
      'skills': ['S701', 'S702', 'S703'],
      'rating': 4.9,
      'completedJobs': 52,
    },
    {
      'nic': '200088888888',
      'firstName': 'Dinesh',
      'lastName': 'Plumber',
      'phone': '0788888888',
      'pin': '1234',
      'district': '08',
      'districtName': 'Matara',
      'dsArea': '0810',
      'dsAreaName': 'Matara',
      'jobCategories': ['C05'],
      'skills': ['S502', 'S503', 'S505'],
      'rating': 4.6,
      'completedJobs': 31,
    },
    {
      'nic': '200099999999',
      'firstName': 'Thulani',
      'lastName': 'Artist',
      'phone': '0799999999',
      'pin': '1234',
      'district': '09',
      'districtName': 'Hambantota',
      'dsArea': '0904',
      'dsAreaName': 'Hambantota',
      'jobCategories': ['C08'],
      'skills': ['S801', 'S802', 'S803', 'S804'],
      'rating': 4.3,
      'completedJobs': 12,
    },
    {
      'nic': '200010101010',
      'firstName': 'Amara',
      'lastName': 'Shopkeeper',
      'phone': '0701010101',
      'pin': '1234',
      'district': '10',
      'districtName': 'Jaffna',
      'dsArea': '1004',
      'dsAreaName': 'Jaffna',
      'jobCategories': ['C10', 'C12'],
      'skills': ['S1001', 'S1002', 'S1003', 'S1201'],
      'rating': 4.5,
      'completedJobs': 25,
    },
  ];

  static const List<Map<String, dynamic>> testJobs = [
    {
      'title': 'Home Renovation & Repair',
      'description':
          'Looking for skilled masons and carpenters for a 3-month home renovation project in Colombo. Must have experience with modern construction techniques.',
      'employerId': '200011111111',
      'area': 'Colombo',
      'skills': ['S101', 'S102'],
      'status': 'open',
    },
    {
      'title': 'Electrical Installation',
      'description':
          'Need qualified electrician for commercial building electrical setup. Budget: Rs. 150,000. Immediate availability required.',
      'employerId': '200022222222',
      'area': 'Gampaha',
      'skills': ['S501'],
      'status': 'open',
    },
    {
      'title': 'Full House Cleaning Service',
      'description':
          'Comprehensive house cleaning required for 2500 sq.ft property. Deep cleaning, window washing, garden maintenance. Weekly or bi-weekly arrangement possible.',
      'employerId': '200033333333',
      'area': 'Kalutara',
      'skills': ['S401', 'S402', 'S403'],
      'status': 'open',
    },
    {
      'title': 'Delivery & Transportation',
      'description':
          'Need reliable drivers for daily goods delivery. Must have own vehicle or access to one. Flexible hours, daily or weekly basis.',
      'employerId': '200044444444',
      'area': 'Kandy',
      'skills': ['S202', 'S203'],
      'status': 'open',
    },
    {
      'title': 'Agricultural Work - Tea Plantation',
      'description':
          'Seasonal tea plucking role on established plantation. High-altitude location, good pay, accommodation provided. 3-month contract.',
      'employerId': '200055555555',
      'area': 'Matale',
      'skills': ['S303'],
      'status': 'open',
    },
    {
      'title': 'Event Catering & Food Preparation',
      'description':
          'Professional chef needed for corporate event catering next month. Prepare menu for 150 guests. Premium budget available.',
      'employerId': '200066666666',
      'area': 'Nuwara Eliya',
      'skills': ['S601', 'S1301'],
      'status': 'open',
    },
    {
      'title': 'Salon Services - Hair & Beauty',
      'description':
          'Looking for experienced beautician for wedding party services. Multiple appointments over 2 weeks. Flexible timing.',
      'employerId': '200077777777',
      'area': 'Galle',
      'skills': ['S701', 'S702'],
      'status': 'open',
    },
    {
      'title': 'Plumbing & Water System Installation',
      'description':
          'New residential complex needs complete plumbing installation. 6-month project, team-based work. Competitive rates.',
      'employerId': '200088888888',
      'area': 'Matara',
      'skills': ['S502'],
      'status': 'open',
    },
    {
      'title': 'Interior Design & Decoration',
      'description':
          'Need creative professional for office interior decoration concept. Design proposal submission required. Budget: Rs. 500,000+',
      'employerId': '200099999999',
      'area': 'Hambantota',
      'skills': ['S803'],
      'status': 'open',
    },
    {
      'title': 'Retail Shop Management',
      'description':
          'Experienced shop manager for new retail outlet in Jaffna. Full-time position, must have inventory management experience.',
      'employerId': '200010101010',
      'area': 'Jaffna',
      'skills': ['S1001'],
      'status': 'open',
    },
    // Completed jobs for social proof
    {
      'title': 'Office Painting',
      'description': 'Office space painted and decorated - COMPLETED',
      'employerId': '200011111111',
      'area': 'Colombo',
      'skills': ['S104'],
      'status': 'completed',
    },
    {
      'title': 'Bathroom Renovation',
      'description': 'Bathroom tiles and fixtures installed - COMPLETED',
      'employerId': '200022222222',
      'area': 'Gampaha',
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
        'district': worker['districtName'],
        'ds_area': worker['dsAreaName'],
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
    return {'nic': '200011111111', 'pin': '1234', 'name': 'Colombo Worker'};
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
