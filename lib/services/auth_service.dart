import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/admin_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Admin Registration (Self-Registration)
  Future<String?> registerAdmin({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create user document
      UserModel user = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.admin,
        institutionId: null, // Will be set after creating institution
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());

      // Create admin document
      AdminModel admin = AdminModel(
        uid: uid,
        email: email,
        name: name,
        phone: phone,
        institutionId: null, // Will be set after creating institution
        createdAt: DateTime.now(),
      );

      await _firestore.collection('admins').doc(uid).set(admin.toMap());

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Create Teacher Account (by Admin)
  Future<Map<String, dynamic>> createTeacherAccount({
    required String email,
    required String password,
    required String name,
    required String institutionId,
    String? divisionId,
    String? phone,
    String? subject,
  }) async {
    try {
      // Store current admin user details for re-authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No admin user signed in',
        };
      }

      final adminEmail = currentUser.email!;

      // Note: We need to temporarily store admin credentials to re-authenticate
      // This is a limitation of Firebase Auth Client SDK - ideally use Firebase Admin SDK

      // Create new teacher account (this will sign out admin and sign into teacher account)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create user document for teacher
      UserModel user = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.teacher,
        institutionId: institutionId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());

      // Create teacher document
      TeacherModel teacher = TeacherModel(
        uid: uid,
        email: email,
        name: name,
        institutionId: institutionId,
        divisionId: divisionId,
        phone: phone,
        subject: subject,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('teachers').doc(uid).set(teacher.toMap());

      // Sign out from teacher account to prepare for admin re-authentication
      await _auth.signOut();

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'password': password,
        'teacherCreated': true,
        'adminEmail': adminEmail, // Provide admin email for UI messaging
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Teacher creation failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }

  // Create Student Account (by Admin)
  Future<Map<String, dynamic>> createStudentAccount({
    required String email,
    required String password,
    required String name,
    required String rollNumber,
    required String institutionId,
    required String academicYearId,
    required String gradeId,
    required String divisionId,
    String? phone,
    String? parentEmail,
  }) async {
    try {
      // Store current admin user details for re-authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No admin user signed in',
        };
      }

      final adminEmail = currentUser.email!;

      // Note: We need to temporarily store admin credentials to re-authenticate
      // This is a limitation of Firebase Auth Client SDK - ideally use Firebase Admin SDK

      // Create new student account (this will sign out admin and sign into student account)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create user document for student
      UserModel user = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.student,
        institutionId: institutionId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());

      // Create student document
      StudentModel student = StudentModel(
        uid: uid,
        email: email,
        name: name,
        rollNumber: rollNumber,
        institutionId: institutionId,
        academicYearId: academicYearId,
        gradeId: gradeId,
        divisionId: divisionId,
        phone: phone,
        parentEmail: parentEmail,
        createdAt: DateTime.now(),
        isFirstLogin: true,
      );

      await _firestore.collection('students').doc(uid).set(student.toMap());

      // Sign out from student account to prepare for admin re-authentication
      await _auth.signOut();

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'password': password,
        'studentCreated': true,
        'adminEmail': adminEmail, // Provide admin email for UI messaging
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.message ?? 'Student creation failed',
      };
    } catch (e) {
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }

  // Sign In
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Password reset failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Change Password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 'No user logged in';

      // Reauthenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Password change failed';
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // Get User Role
  Future<UserRole?> getUserRole(String uid) async {
    try {
      print('AuthService: Getting user role for uid: $uid');

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      print('AuthService: Document exists: ${doc.exists}');
      print('AuthService: Document has data: ${doc.data() != null}');

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Debug: Print user data to help troubleshoot
        print('AuthService: User data for $uid: $userData');

        UserModel user = UserModel.fromMap(userData);
        print('AuthService: Parsed user role: ${user.role}');

        return user.role;
      } else {
        print('AuthService: User document not found for uid: $uid');
        print('AuthService: Checking other collections for data integrity...');

        // Check if user exists in other collections but missing from users collection
        DocumentSnapshot adminDoc =
            await _firestore.collection('admins').doc(uid).get();
        if (adminDoc.exists) {
          print(
              'AuthService: Found user in admins collection, role should be admin');
          return UserRole.admin;
        }

        DocumentSnapshot teacherDoc =
            await _firestore.collection('teachers').doc(uid).get();
        if (teacherDoc.exists) {
          print(
              'AuthService: Found user in teachers collection, role should be teacher');
          return UserRole.teacher;
        }

        DocumentSnapshot studentDoc =
            await _firestore.collection('students').doc(uid).get();
        if (studentDoc.exists) {
          print(
              'AuthService: Found user in students collection, role should be student');
          return UserRole.student;
        }

        print('AuthService: User not found in any collection');
      }
      return null;
    } catch (e) {
      print('AuthService: Error getting user role: $e');
      return null;
    }
  } // Get User Data

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Admin Data
  Future<AdminModel?> getAdminData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(uid).get();
      if (doc.exists) {
        return AdminModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Teacher Data
  Future<TeacherModel?> getTeacherData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('teachers').doc(uid).get();
      if (doc.exists) {
        return TeacherModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Student Data
  Future<StudentModel?> getStudentData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('students').doc(uid).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update first login status
  Future<void> updateFirstLoginStatus(String uid) async {
    await _firestore.collection('students').doc(uid).update({
      'isFirstLogin': false,
    });
  }

  // Update user institution ID (after admin creates institution)
  Future<void> updateUserInstitution(String uid, String institutionId) async {
    await _firestore.collection('users').doc(uid).update({
      'institutionId': institutionId,
    });

    // Also update in admin collection
    await _firestore.collection('admins').doc(uid).update({
      'institutionId': institutionId,
    });
  }

  // Verify and repair user data if needed
  Future<void> ensureUserDataIntegrity(String uid) async {
    try {
      // Check if user document exists
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print(
            'User document missing for uid: $uid, checking other collections...');

        // Check admin collection
        DocumentSnapshot adminDoc =
            await _firestore.collection('admins').doc(uid).get();
        if (adminDoc.exists) {
          AdminModel admin =
              AdminModel.fromMap(adminDoc.data() as Map<String, dynamic>);
          UserModel user = UserModel(
            uid: admin.uid,
            email: admin.email,
            name: admin.name,
            role: UserRole.admin,
            institutionId: admin.institutionId,
            createdAt: admin.createdAt,
          );
          await _firestore.collection('users').doc(uid).set(user.toMap());
          return;
        }

        // Check teacher collection
        DocumentSnapshot teacherDoc =
            await _firestore.collection('teachers').doc(uid).get();
        if (teacherDoc.exists) {
          TeacherModel teacher =
              TeacherModel.fromMap(teacherDoc.data() as Map<String, dynamic>);
          UserModel user = UserModel(
            uid: teacher.uid,
            email: teacher.email,
            name: teacher.name,
            role: UserRole.teacher,
            institutionId: teacher.institutionId,
            createdAt: teacher.createdAt,
          );
          await _firestore.collection('users').doc(uid).set(user.toMap());
          return;
        }

        // Check student collection
        DocumentSnapshot studentDoc =
            await _firestore.collection('students').doc(uid).get();
        if (studentDoc.exists) {
          StudentModel student =
              StudentModel.fromMap(studentDoc.data() as Map<String, dynamic>);
          UserModel user = UserModel(
            uid: student.uid,
            email: student.email,
            name: student.name,
            role: UserRole.student,
            institutionId: student.institutionId,
            createdAt: student.createdAt,
          );
          await _firestore.collection('users').doc(uid).set(user.toMap());
          return;
        }
      }
    } catch (e) {
      print('Error ensuring user data integrity: $e');
    }
  }
}
