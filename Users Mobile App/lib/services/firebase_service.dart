import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // --- Auth & User Management ---

  static Future<UserCredential> signIn(String nic, String pin) async {
    final email = '${nic.toUpperCase()}@workforce.lk';
    return await auth.signInWithEmailAndPassword(email: email, password: pin);
  }

  static Future<UserCredential> register(String nic, String pin) async {
    final email = '${nic.toUpperCase()}@workforce.lk';
    return await auth.createUserWithEmailAndPassword(email: email, password: pin);
  }

  static Future<void> signOut() async {
    await auth.signOut();
  }

  static User? get currentUser => auth.currentUser;

  // --- Profile Operations ---

  static Future<void> saveUserProfile(String nic, Map<String, dynamic> data) async {
    await db.collection('users').doc(nic.toUpperCase()).set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile(String nic) async {
    final doc = await db.collection('users').doc(nic.toUpperCase()).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  static Future<String?> uploadProfilePhoto(String nic, String filePath) async {
    try {
      final file = File(filePath);
      final ref = storage.ref().child('profiles/${nic.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      
      // Update the user profile with the new URL
      await db.collection('users').doc(nic.toUpperCase()).update({
        'profile_photo_url': url,
      });
      return url;
    } catch (e) {
      print('Photo upload error: $e');
      return null;
    }
  }

  // --- Jobs Operations ---

  static Stream<QuerySnapshot> getOpenJobsStream(String area) {
    return db.collection('jobs')
        .where('status', isEqualTo: 'open')
        .where('area', isEqualTo: area)
        .snapshots();
  }
  
  static Future<void> applyForJob(String jobId, String nic) async {
    final docId = '${jobId}_${nic.toUpperCase()}';
    final appRef = db.collection('applications').doc(docId);
    
    await db.runTransaction((transaction) async {
      final appDoc = await transaction.get(appRef);
      if (!appDoc.exists) {
        transaction.set(appRef, {
          'job_id': jobId,
          'worker_id': nic.toUpperCase(),
          'applied_at': FieldValue.serverTimestamp(),
        });
        
        final jobRef = db.collection('jobs').doc(jobId);
        transaction.update(jobRef, {
          'applied_worker_ids': FieldValue.arrayUnion([nic.toUpperCase()]),
        });
        
        final userRef = db.collection('users').doc(nic.toUpperCase());
        transaction.update(userRef, {
          'applied_jobs_count': FieldValue.increment(1),
        });
      }
    });
  }

  static Stream<QuerySnapshot> getUserApplications(String nic) {
    return db.collection('applications')
        .where('worker_id', isEqualTo: nic.toUpperCase())
        .snapshots();
  }

  static Future<Map<String, dynamic>?> getJobDetails(String jobId) async {
    final doc = await db.collection('jobs').doc(jobId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id; // ensure ID is included
      return data;
    }
    return null;
  }
}
