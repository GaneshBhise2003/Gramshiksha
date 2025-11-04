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
      // Note: This will sign out current user temporarily
      // You may want to use Admin SDK for production
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create user document
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

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'password': password,
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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create user document
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

      return {
        'success': true,
        'uid': uid,
        'email': email,
        'password': password,
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
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        return user.role;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get User Data
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
}
