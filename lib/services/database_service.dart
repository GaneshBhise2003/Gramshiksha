//new code
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/institution_model.dart';
import '../models/academic_year_model.dart';
import '../models/grade_model.dart';
import '../models/division_model.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/assignment_model.dart';
import '../models/quiz_model.dart';
import '../models/attendance_model.dart';
import '../models/announcement_model.dart';
import '../models/course_model.dart';
import '../models/assignment_submission_model.dart';
import '../models/quiz_attempt_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== INSTITUTION OPERATIONS =====

  // Create Institution
  Future<String?> createInstitution({
    required String name,
    required InstitutionType type,
    required String address,
    required String code,
    required String adminId,
  }) async {
    try {
      final institutionId = _firestore.collection('institutions').doc().id;
      final institution = InstitutionModel(
        id: institutionId,
        name: name,
        type: type,
        address: address,
        adminId: adminId,
        code: code,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('institutions')
          .doc(institutionId)
          .set(institution.toMap());
      return institutionId;
    } catch (e) {
      return null;
    }
  }

  // Get Institution by ID
  Future<InstitutionModel?> getInstitution(String institutionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('institutions').doc(institutionId).get();
      if (doc.exists) {
        return InstitutionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Institution
  Future<String?> updateInstitution(InstitutionModel institution) async {
    try {
      await _firestore
          .collection('institutions')
          .doc(institution.id)
          .update(institution.toMap());
      return null;
    } catch (e) {
      return 'Error updating institution: $e';
    }
  }

  // ===== ACADEMIC YEAR OPERATIONS =====

  // Create Academic Year
  Future<String?> createAcademicYear(AcademicYearModel academicYear) async {
    try {
      final id = _firestore.collection('academic_years').doc().id;
      final academicYearWithId = AcademicYearModel(
        id: id,
        name: academicYear.name,
        institutionId: academicYear.institutionId,
        startDate: academicYear.startDate,
        endDate: academicYear.endDate,
        isActive: academicYear.isActive,
        isCurrent: academicYear.isCurrent,
        createdAt: DateTime.now(),
      );

      final dataToSave = academicYearWithId.toMap();
      print('Creating academic year with data: $dataToSave');

      await _firestore.collection('academic_years').doc(id).set(dataToSave);

      print('Academic year created successfully with ID: $id');
      return null;
    } catch (e) {
      print('Error creating academic year: $e');
      return 'Error creating academic year: $e';
    }
  }

  // Get Academic Years by Institution
  Future<List<AcademicYearModel>> getAcademicYearsByInstitution(
    String institutionId,
  ) async {
    try {
      print('Fetching academic years for institution: $institutionId');
      final querySnapshot = await _firestore
          .collection('academic_years')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      print('Found ${querySnapshot.docs.length} academic years');

      final academicYears = querySnapshot.docs.map((doc) {
        print('Academic year data: ${doc.data()}');
        return AcademicYearModel.fromMap(doc.data());
      }).toList();

      // Sort by created date manually
      academicYears.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return academicYears;
    } catch (e) {
      print('Error fetching academic years: $e');
      return [];
    }
  }

  // Update Academic Year
  Future<String?> updateAcademicYear(AcademicYearModel academicYear) async {
    try {
      await _firestore
          .collection('academic_years')
          .doc(academicYear.id)
          .update(academicYear.toMap());
      return null;
    } catch (e) {
      return 'Error updating academic year: $e';
    }
  }

  // Set Current Academic Year
  Future<String?> setCurrentAcademicYear(String academicYearId) async {
    try {
      // First, get the institution ID from the academic year
      final academicYearDoc = await _firestore
          .collection('academic_years')
          .doc(academicYearId)
          .get();

      if (!academicYearDoc.exists) {
        return 'Academic year not found';
      }

      final institutionId = academicYearDoc.data()!['institutionId'];

      // Remove current flag from all academic years in this institution
      final batch = _firestore.batch();
      final allAcademicYears = await _firestore
          .collection('academic_years')
          .where('institutionId', isEqualTo: institutionId)
          .get();

      for (final doc in allAcademicYears.docs) {
        batch.update(doc.reference, {'isCurrent': false});
      }

      // Set the selected academic year as current
      batch.update(academicYearDoc.reference, {'isCurrent': true});

      await batch.commit();
      return null;
    } catch (e) {
      return 'Error setting current academic year: $e';
    }
  }

  // Delete Academic Year
  Future<String?> deleteAcademicYear(String academicYearId) async {
    try {
      await _firestore
          .collection('academic_years')
          .doc(academicYearId)
          .delete();
      return null;
    } catch (e) {
      return 'Error deleting academic year: $e';
    }
  }

  // ===== GRADE OPERATIONS =====

  // Create Grade
  Future<String?> createGrade(GradeModel grade) async {
    try {
      final id = _firestore.collection('grades').doc().id;
      final gradeWithId = GradeModel(
        id: id,
        name: grade.name,
        institutionId: grade.institutionId,
        academicYearId: grade.academicYearId,
        levelNumber: grade.levelNumber,
        type: grade.type,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('grades').doc(id).set(gradeWithId.toMap());
      return null;
    } catch (e) {
      return 'Error creating grade: $e';
    }
  }

  // Get Grades by Institution and Academic Year
  Future<List<GradeModel>> getGradesByInstitutionAndAcademicYear(
    String institutionId,
    String academicYearId,
  ) async {
    try {
      print(
        'Fetching grades for institution: $institutionId, academic year: $academicYearId',
      );
      final querySnapshot = await _firestore
          .collection('grades')
          .where('institutionId', isEqualTo: institutionId)
          .where('academicYearId', isEqualTo: academicYearId)
          .get();

      print('Found ${querySnapshot.docs.length} grades');

      final grades = querySnapshot.docs.map((doc) {
        print('Grade data: ${doc.data()}');
        return GradeModel.fromMap(doc.data());
      }).toList();

      // Sort by level number manually
      grades.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

      return grades;
    } catch (e) {
      print('Error fetching grades: $e');
      return [];
    }
  }

  // Get All Grades by Institution
  Future<List<GradeModel>> getGradesByInstitution(String institutionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('institutionId', isEqualTo: institutionId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => GradeModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update Grade
  Future<String?> updateGrade(GradeModel grade) async {
    try {
      await _firestore.collection('grades').doc(grade.id).update(grade.toMap());
      return null;
    } catch (e) {
      return 'Error updating grade: $e';
    }
  }

  // Delete Grade
  Future<String?> deleteGrade(String gradeId) async {
    try {
      await _firestore.collection('grades').doc(gradeId).delete();
      return null;
    } catch (e) {
      return 'Error deleting grade: $e';
    }
  }

  // ===== DIVISION OPERATIONS =====

  // Create Division
  Future<String?> createDivision({
    required String name,
    required String institutionId,
    required String academicYearId,
    required String gradeId,
    String? description,
    int maxStudents = 50,
  }) async {
    try {
      final divisionId = _firestore.collection('divisions').doc().id;
      final division = DivisionModel(
        id: divisionId,
        name: name,
        institutionId: institutionId,
        gradeId: gradeId,
        academicYearId: academicYearId,
        description: description,
        maxStudents: maxStudents,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('divisions')
          .doc(divisionId)
          .set(division.toMap());
      return null;
    } catch (e) {
      return 'Error creating division: $e';
    }
  }

  // Get Divisions by Institution
  Stream<List<DivisionModel>> getDivisionsByInstitution(String institutionId) {
    return _firestore
        .collection('divisions')
        .where('institutionId', isEqualTo: institutionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DivisionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get Division by ID
  Future<DivisionModel?> getDivision(String divisionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (doc.exists) {
        return DivisionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Division
  Future<String?> updateDivision(DivisionModel division) async {
    try {
      await _firestore
          .collection('divisions')
          .doc(division.id)
          .update(division.toMap());
      return null;
    } catch (e) {
      return 'Error updating division: $e';
    }
  }

  // ===== CLASS OPERATIONS =====

  // Create Class - Using divisions as classes
  Future<String?> createClass(ClassModel classModel) async {
    try {
      // Since we're using divisions as classes, we create/update the division
      final divisionData = {
        'name': classModel.name,
        'institutionId': classModel.institutionId,
        'gradeId': classModel.gradeId,
        'academicYearId': classModel.academicYearId,
        'isActive': classModel.isActive,
        'createdAt': Timestamp.fromDate(classModel.createdAt),
        'description': classModel.description,
      };

      await _firestore
          .collection('divisions')
          .doc(classModel.divisionId)
          .set(divisionData, SetOptions(merge: true));

      // Update teacher's divisionId
      await _firestore.collection('teachers').doc(classModel.teacherId).update({
        'divisionId': classModel.divisionId,
      });

      return null;
    } catch (e) {
      return 'Error creating class: $e';
    }
  }

  // Get Classes by Teacher - Using divisions
  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _firestore
        .collection('teachers')
        .doc(teacherId)
        .snapshots()
        .asyncMap((teacherDoc) async {
      if (!teacherDoc.exists) return <ClassModel>[];

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      final divisionId = teacherData['divisionId'] as String?;

      if (divisionId == null || divisionId.isEmpty) return <ClassModel>[];

      // Get the division document
      final divisionDoc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!divisionDoc.exists) return <ClassModel>[];

      final divisionData = divisionDoc.data() as Map<String, dynamic>;

      // Convert division to ClassModel
      return [
        ClassModel(
          id: divisionDoc.id,
          name: divisionData['name'] ?? 'Unknown Division',
          subject: teacherData['subject'] ?? 'General',
          institutionId: divisionData['institutionId'] ?? '',
          divisionId: divisionDoc.id,
          gradeId: divisionData['gradeId'] ?? '',
          academicYearId: divisionData['academicYearId'] ?? '',
          classCode:
              divisionData['name'] ?? 'A', // Use division name as class code
          teacherId: teacherId,
          studentIds: [],
          coTeacherIds: [],
          schedule: null,
          description: divisionData['description'],
          createdAt: (divisionData['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
          isActive: divisionData['isActive'] ?? true,
        ),
      ];
    });
  }

  // Get Class by ID - Using division
  Future<ClassModel?> getClassById(String divisionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      // Get teacher for this division
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('divisionId', isEqualTo: divisionId)
          .limit(1)
          .get();

      String teacherId = '';
      String subject = 'General';
      if (teachersSnapshot.docs.isNotEmpty) {
        final teacherData = teachersSnapshot.docs.first.data();
        teacherId = teachersSnapshot.docs.first.id;
        subject = teacherData['subject'] ?? 'General';
      }

      return ClassModel(
        id: doc.id,
        name: data['name'] ?? 'Unknown Division',
        subject: subject,
        institutionId: data['institutionId'] ?? '',
        divisionId: doc.id,
        gradeId: data['gradeId'] ?? '',
        academicYearId: data['academicYearId'] ?? '',
        classCode: data['name'] ?? 'A',
        teacherId: teacherId,
        studentIds: [],
        coTeacherIds: [],
        schedule: null,
        description: data['description'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      return null;
    }
  }

  // Update Class - Using division
  Future<String?> updateClass(ClassModel classModel) async {
    try {
      await _firestore
          .collection('divisions')
          .doc(classModel.divisionId)
          .update({
        'name': classModel.name,
        'description': classModel.description,
        'isActive': classModel.isActive,
      });
      return null;
    } catch (e) {
      return 'Error updating class: $e';
    }
  }

  // Add Student to Class - Using division
  Future<String?> addStudentToClass(String divisionId, String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'divisionId': divisionId,
      });
      return null;
    } catch (e) {
      return 'Error adding student to class: $e';
    }
  }

  // Remove Student from Class - Using division
  Future<String?> removeStudentFromClass(
    String divisionId,
    String studentId,
  ) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'divisionId': FieldValue.delete(),
      });
      return null;
    } catch (e) {
      return 'Error removing student from class: $e';
    }
  }

  // Get Classes by Division
  Future<List<ClassModel>> getClassesByDivision(String divisionId) async {
    try {
      final divisionDoc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!divisionDoc.exists) return [];

      final data = divisionDoc.data() as Map<String, dynamic>;

      // Get teacher for this division
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('divisionId', isEqualTo: divisionId)
          .limit(1)
          .get();

      String teacherId = '';
      String subject = 'General';
      if (teachersSnapshot.docs.isNotEmpty) {
        final teacherData = teachersSnapshot.docs.first.data();
        teacherId = teachersSnapshot.docs.first.id;
        subject = teacherData['subject'] ?? 'General';
      }

      return [
        ClassModel(
          id: divisionDoc.id,
          name: data['name'] ?? 'Unknown Division',
          subject: subject,
          institutionId: data['institutionId'] ?? '',
          divisionId: divisionDoc.id,
          gradeId: data['gradeId'] ?? '',
          academicYearId: data['academicYearId'] ?? '',
          classCode: data['name'] ?? 'A',
          teacherId: teacherId,
          studentIds: [],
          coTeacherIds: [],
          schedule: null,
          description: data['description'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  // Get Classes for Student - Using division
  Stream<List<ClassModel>> getStudentClassesNew(String studentId) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .snapshots()
        .asyncMap((studentDoc) async {
      if (!studentDoc.exists) return <ClassModel>[];

      final studentData = studentDoc.data() as Map<String, dynamic>;
      final divisionId = studentData['divisionId'] as String?;

      if (divisionId == null || divisionId.isEmpty) return <ClassModel>[];

      final divisionDoc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!divisionDoc.exists) return <ClassModel>[];

      final data = divisionDoc.data() as Map<String, dynamic>;

      // Get teacher for this division
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('divisionId', isEqualTo: divisionId)
          .limit(1)
          .get();

      String teacherId = '';
      String subject = 'General';
      if (teachersSnapshot.docs.isNotEmpty) {
        final teacherData = teachersSnapshot.docs.first.data();
        teacherId = teachersSnapshot.docs.first.id;
        subject = teacherData['subject'] ?? 'General';
      }

      return [
        ClassModel(
          id: divisionDoc.id,
          name: data['name'] ?? 'Unknown Division',
          subject: subject,
          institutionId: data['institutionId'] ?? '',
          divisionId: divisionDoc.id,
          gradeId: data['gradeId'] ?? '',
          academicYearId: data['academicYearId'] ?? '',
          classCode: data['name'] ?? 'A',
          teacherId: teacherId,
          studentIds: [],
          coTeacherIds: [],
          schedule: null,
          description: data['description'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        ),
      ];
    });
  }

  // Get Students for a Teacher - Using division
  Future<List<StudentModel>> getStudentsByTeacher(String teacherId) async {
    try {
      // Get teacher's division
      final teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();
      if (!teacherDoc.exists) return [];

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      final divisionId = teacherData['divisionId'] as String?;

      if (divisionId == null) return [];

      // Get students in the same division
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('divisionId', isEqualTo: divisionId)
          .where('isActive', isEqualTo: true)
          .get();

      return studentsSnapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting students by teacher: $e');
      return [];
    }
  }

  // Get primary class ID for a student - Using division
  Future<String?> getStudentPrimaryClassId(String studentId) async {
    try {
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) return null;

      final studentData = studentDoc.data() as Map<String, dynamic>;
      return studentData['divisionId'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Delete Class - Using division
  Future<String?> deleteClass(String divisionId) async {
    try {
      await _firestore.collection('divisions').doc(divisionId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deleting class: $e';
    }
  }

  // Get Student Classes - Using division
  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .snapshots()
        .asyncMap((studentDoc) async {
      if (!studentDoc.exists) return <ClassModel>[];

      final studentData = studentDoc.data() as Map<String, dynamic>;
      final divisionId = studentData['divisionId'] as String?;

      if (divisionId == null) return <ClassModel>[];

      final divisionDoc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!divisionDoc.exists) return <ClassModel>[];

      final data = divisionDoc.data() as Map<String, dynamic>;

      // Get teacher for this division
      final teachersSnapshot = await _firestore
          .collection('teachers')
          .where('divisionId', isEqualTo: divisionId)
          .limit(1)
          .get();

      String teacherId = '';
      String subject = 'General';
      if (teachersSnapshot.docs.isNotEmpty) {
        final teacherData = teachersSnapshot.docs.first.data();
        teacherId = teachersSnapshot.docs.first.id;
        subject = teacherData['subject'] ?? 'General';
      }

      return [
        ClassModel(
          id: divisionDoc.id,
          name: data['name'] ?? 'Unknown Division',
          subject: subject,
          institutionId: data['institutionId'] ?? '',
          divisionId: divisionDoc.id,
          gradeId: data['gradeId'] ?? '',
          academicYearId: data['academicYearId'] ?? '',
          classCode: data['name'] ?? 'A',
          teacherId: teacherId,
          studentIds: [],
          coTeacherIds: [],
          schedule: null,
          description: data['description'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        ),
      ];
    });
  }

  // ===== STUDENT OPERATIONS =====

  // Get Students by Class - Using division
  Stream<List<StudentModel>> getClassStudents(String divisionId) {
    return _firestore
        .collection('students')
        .where('divisionId', isEqualTo: divisionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get Student by ID
  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update Student
  Future<String?> updateStudent(StudentModel student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.uid)
          .update(student.toMap());
      return null;
    } catch (e) {
      return 'Error updating student: $e';
    }
  }

  // Deactivate Student
  Future<String?> deactivateStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deactivating student: $e';
    }
  }

  // Get All Students in Database
  Stream<List<StudentModel>> getAllStudentsInDatabase() {
    return _firestore.collection('students').orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get All Students for Teacher - Using division
  Stream<List<StudentModel>> getAllStudentsForTeacher(String teacherId) {
    return _firestore
        .collection('teachers')
        .doc(teacherId)
        .snapshots()
        .asyncMap((teacherDoc) async {
      if (!teacherDoc.exists) return <StudentModel>[];

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      final divisionId = teacherData['divisionId'] as String?;

      if (divisionId == null) return <StudentModel>[];

      final studentsSnapshot = await _firestore
          .collection('students')
          .where('divisionId', isEqualTo: divisionId)
          .where('isActive', isEqualTo: true)
          .get();

      return studentsSnapshot.docs
          .map((doc) => StudentModel.fromMap(doc.data()))
          .toList();
    });
  }

  // ===== ASSIGNMENT OPERATIONS =====

  // Create Assignment
  Future<String?> createAssignment(AssignmentModel assignment) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignment.id)
          .set(assignment.toMap());
      return null;
    } catch (e) {
      return 'Error creating assignment: $e';
    }
  }

  // Get Assignments by Class - Using division
  Stream<List<AssignmentModel>> getClassAssignments(String divisionId) {
    return _firestore
        .collection('assignments')
        .where('divisionId', isEqualTo: divisionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AssignmentModel.fromMap(doc.data()))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
        );
  }

  // Submit Assignment
  Future<String?> submitAssignment(AssignmentSubmission submission) async {
    try {
      await _firestore
          .collection('assignment_submissions')
          .doc(submission.id)
          .set(submission.toMap());
      return null;
    } catch (e) {
      return 'Error submitting assignment: $e';
    }
  }

  // Get Assignment Submissions
  Stream<List<AssignmentSubmission>> getAssignmentSubmissions(
    String assignmentId,
  ) {
    return _firestore
        .collection('assignment_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AssignmentSubmission.fromMap(doc.data()))
              .toList(),
        );
  }

  // Grade Assignment
  Future<String?> gradeAssignment(
    String submissionId,
    int marks,
    String feedback,
  ) async {
    try {
      await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .update({
        'marksObtained': marks,
        'feedback': feedback,
        'status': AssignmentStatus.graded.toString().split('.').last,
        'gradedAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      return 'Error grading assignment: $e';
    }
  }

  // ===== QUIZ OPERATIONS =====

  // Create Quiz
  Future<String?> createQuiz(QuizModel quiz) async {
    try {
      await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toMap());
      return null;
    } catch (e) {
      return 'Error creating quiz: $e';
    }
  }

  // Get Quizzes by Class - Using division
  Stream<List<QuizModel>> getClassQuizzes(String divisionId) {
    return _firestore
        .collection('quizzes')
        .where('divisionId', isEqualTo: divisionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Start Quiz Attempt
  Future<String?> startQuizAttempt(QuizAttempt attempt) async {
    try {
      await _firestore
          .collection('quiz_attempts')
          .doc(attempt.id)
          .set(attempt.toMap());
      return null;
    } catch (e) {
      return 'Error starting quiz: $e';
    }
  }

  // Create Quiz Attempt
  Future<String?> createQuizAttempt(QuizAttempt attempt) async {
    try {
      await _firestore
          .collection('quiz_attempts')
          .doc(attempt.id)
          .set(attempt.toMap());
      return null;
    } catch (e) {
      return 'Error creating quiz attempt: $e';
    }
  }

  // Submit Quiz
  Future<String?> submitQuiz(
    String attemptId,
    String studentId,
    String quizId,
    Map<String, String> answers,
    int score,
    int totalMarks,
    DateTime startedAt,
    int timeTaken,
  ) async {
    try {
      await _firestore.collection('quiz_attempts').doc(attemptId).set({
        'id': attemptId,
        'studentId': studentId,
        'quizId': quizId,
        'answers': answers,
        'score': score.toDouble(),
        'totalMarks': totalMarks.toDouble(),
        'startedAt': Timestamp.fromDate(startedAt),
        'completedAt': Timestamp.now(),
        'timeTaken': timeTaken,
        'isCompleted': true,
      });
      return null;
    } catch (e) {
      return 'Error submitting quiz: $e';
    }
  }

  // Get Quiz Attempts
  Stream<List<QuizAttempt>> getQuizAttempts(String quizId) {
    return _firestore
        .collection('quiz_attempts')
        .where('quizId', isEqualTo: quizId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizAttempt.fromMap(doc.data()))
              .toList(),
        );
  }

  // Add this method to your DatabaseService class
  Future<List<AttendanceModel>> getAllAttendanceRecords() async {
    try {
      final querySnapshot = await _firestore
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all attendance records: $e');
      return [];
    }
  }

  // Get Student Quiz Attempts
  // Stream<List<QuizAttemptModel>> getStudentQuizAttempts(
  //   String studentId,
  //   String quizId,
  // ) {
  //   return _firestore
  //       .collection('quiz_attempts')
  //       .where('studentId', isEqualTo: studentId)
  //       .where('quizId', isEqualTo: quizId)
  //       .snapshots()
  //       .map(
  //         (snapshot) => snapshot.docs
  //             .map((doc) => QuizAttemptModel.fromMap(doc.data()))
  //             .toList(),
  //       );
  // }
//by ganesh
  Stream<List<QuizAttemptModel>> getStudentQuizAttempts(String studentId) {
    return _firestore
        .collection('quiz_attempts')
        .where('studentId', isEqualTo: studentId)
        //.orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuizAttemptModel.fromMap(doc.data()))
            .toList());
  }

  // Get all quiz attempts for a student
  Stream<List<QuizAttemptModel>> getStudentAllQuizAttempts(String studentId) {
    return _firestore
        .collection('quiz_attempts')
        .where('studentId', isEqualTo: studentId)
        .where('isCompleted', isEqualTo: true)
        //.orderBy('completedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizAttemptModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // ===== ATTENDANCE OPERATIONS =====

  // Mark Attendance
  Future<String?> markAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.id)
          .set(attendance.toMap());
      return null;
    } catch (e) {
      return 'Error marking attendance: $e';
    }
  }

  // Get Attendance by Class and Date - Using division
  Future<AttendanceModel?> getAttendanceByDate(
    String divisionId,
    DateTime date,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('divisionId', isEqualTo: divisionId)
          .where(
            'date',
            isEqualTo: Timestamp.fromDate(
              DateTime(date.year, date.month, date.day),
            ),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AttendanceModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Student Attendance Records - Using division
  Stream<List<AttendanceModel>> getStudentAttendance(
    String divisionId,
    String studentId,
  ) {
    return _firestore
        .collection('attendance')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceModel.fromMap(doc.data()))
              .where(
                (attendance) =>
                    attendance.studentAttendance.containsKey(studentId),
              )
              .toList(),
        );
  }

  // ===== ANNOUNCEMENT OPERATIONS =====

  // Create Announcement
  Future<String?> createAnnouncement({
    required String teacherId,
    required String title,
    required String description,
    required String divisionId,
    required String institutionId,
  }) async {
    try {
      final announcement = AnnouncementModel(
        id: _firestore.collection('announcements').doc().id,
        teacherId: teacherId,
        classIds: [], // Empty for division-wide announcements
        title: title,
        content: description,
        createdAt: DateTime.now(),
        institutionId: institutionId,
        divisionId: divisionId,
      );

      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .set(announcement.toMap());
      return null;
    } catch (e) {
      return 'Error creating announcement: $e';
    }
  }

  // Get Announcements for Teacher
  Stream<List<AnnouncementModel>> getAnnouncementsForTeacher(String teacherId) {
    return _firestore
        .collection('announcements')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnnouncementModel.fromMap(doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Get Announcements for Student - Using division
  Stream<List<AnnouncementModel>> getAnnouncementsForStudent(
    String divisionId,
  ) {
    return _firestore
        .collection('announcements')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnnouncementModel.fromMap(doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Update Announcement
  Future<String?> updateAnnouncement(AnnouncementModel announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .update(announcement.toMap());
      return null;
    } catch (e) {
      return 'Error updating announcement: $e';
    }
  }

  // Delete Announcement
  Future<String?> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
      return null;
    } catch (e) {
      return 'Error deleting announcement: $e';
    }
  }

  // Get Classes by Teacher - Using division
  Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    try {
      final teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();
      if (!teacherDoc.exists) return [];

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      final divisionId = teacherData['divisionId'] as String?;

      if (divisionId == null) return [];

      final divisionDoc =
          await _firestore.collection('divisions').doc(divisionId).get();
      if (!divisionDoc.exists) return [];

      final data = divisionDoc.data() as Map<String, dynamic>;

      return [
        ClassModel(
          id: divisionDoc.id,
          name: data['name'] ?? 'Unknown Division',
          subject: teacherData['subject'] ?? 'General',
          institutionId: data['institutionId'] ?? '',
          divisionId: divisionDoc.id,
          gradeId: data['gradeId'] ?? '',
          academicYearId: data['academicYearId'] ?? '',
          classCode: data['name'] ?? 'A',
          teacherId: teacherId,
          studentIds: [],
          coTeacherIds: [],
          schedule: null,
          description: data['description'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        ),
      ];
    } catch (e) {
      return [];
    }
  }

  // Get Announcements by Class - Using division
  Stream<List<AnnouncementModel>> getClassAnnouncements(String divisionId) {
    return getAnnouncementsForStudent(divisionId);
  }

  // ===== COURSE OPERATIONS =====

  // Create Course
  Future<String?> createCourse(CourseModel course) async {
    try {
      await _firestore.collection('courses').doc(course.id).set(course.toMap());
      return null;
    } catch (e) {
      return 'Error creating course: $e';
    }
  }

  // Get Courses by Class - Using division
  Stream<List<CourseModel>> getClassCourses(String divisionId) {
    return _firestore
        .collection('courses')
        .where('divisionId', isEqualTo: divisionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourseModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Update Course
  Future<String?> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.id)
          .update(course.toMap());
      return null;
    } catch (e) {
      return 'Error updating course: $e';
    }
  }

  // Get Courses by Teacher - Using division
  Stream<List<CourseModel>> getTeacherCourses(String teacherId) {
    return _firestore
        .collection('teachers')
        .doc(teacherId)
        .snapshots()
        .asyncMap((teacherDoc) async {
      if (!teacherDoc.exists) return <CourseModel>[];

      final teacherData = teacherDoc.data() as Map<String, dynamic>;
      final divisionId = teacherData['divisionId'] as String?;

      if (divisionId == null) return <CourseModel>[];

      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('divisionId', isEqualTo: divisionId)
          .where('isActive', isEqualTo: true)
          .get();

      return coursesSnapshot.docs
          .map((doc) => CourseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Delete Course
  Future<String?> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deleting course: $e';
    }
  }

  // Get Course by ID
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists) {
        return CourseModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ===== ADDITIONAL ADMIN MANAGEMENT METHODS =====

  // Get Teacher by ID
  Future<TeacherModel?> getTeacher(String teacherId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('teachers').doc(teacherId).get();
      if (doc.exists) {
        return TeacherModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get Teachers by Institution
  Future<List<TeacherModel>> getTeachersByInstitution(
    String institutionId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('teachers')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => TeacherModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Update Teacher
  Future<String?> updateTeacher(TeacherModel teacher) async {
    try {
      await _firestore
          .collection('teachers')
          .doc(teacher.uid)
          .update(teacher.toMap());
      return null;
    } catch (e) {
      return 'Error updating teacher: $e';
    }
  }

  // Delete Teacher (Soft delete)
  Future<String?> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deleting teacher: $e';
    }
  }

  // Get Students by Institution
  Future<List<StudentModel>> getStudentsByInstitution(
    String institutionId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Delete Student (Soft delete)
  Future<String?> deleteStudent(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deleting student: $e';
    }
  }

  // Get Divisions by Institution (return Future instead of Stream)
  Future<List<DivisionModel>> getDivisionsByInstitutionFuture(
    String institutionId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('divisions')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => DivisionModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get Divisions by Institution, Academic Year and Grade
  Future<List<DivisionModel>> getDivisionsByInstitutionAndAcademicYearAndGrade(
    String institutionId,
    String academicYearId,
    String gradeId,
  ) async {
    try {
      print(
        'DEBUG: Loading divisions for institution: $institutionId, academicYear: $academicYearId, grade: $gradeId',
      );

      QuerySnapshot snapshot = await _firestore
          .collection('divisions')
          .where('institutionId', isEqualTo: institutionId)
          .where('academicYearId', isEqualTo: academicYearId)
          .where('gradeId', isEqualTo: gradeId)
          .where('isActive', isEqualTo: true)
          .get();

      List<DivisionModel> divisions = snapshot.docs
          .map(
            (doc) => DivisionModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Manual sorting by division name (A, B, C, etc.)
      divisions.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: Found ${divisions.length} divisions');
      for (var division in divisions) {
        print('DEBUG: Division: ${division.name} (ID: ${division.id})');
      }

      return divisions;
    } catch (e) {
      print('DEBUG: Error loading divisions: $e');
      return [];
    }
  }

  // Delete Division (Soft delete)
  Future<String?> deleteDivision(String divisionId) async {
    try {
      await _firestore.collection('divisions').doc(divisionId).update({
        'isActive': false,
      });
      return null;
    } catch (e) {
      return 'Error deleting division: $e';
    }
  }

  // Get Classes by Institution - Using divisions
  Future<List<ClassModel>> getClassesByInstitution(String institutionId) async {
    try {
      final divisionsSnapshot = await _firestore
          .collection('divisions')
          .where('institutionId', isEqualTo: institutionId)
          .where('isActive', isEqualTo: true)
          .get();

      List<ClassModel> classes = [];

      for (var divisionDoc in divisionsSnapshot.docs) {
        final divisionData = divisionDoc.data();

        // Get teacher for this division
        final teachersSnapshot = await _firestore
            .collection('teachers')
            .where('divisionId', isEqualTo: divisionDoc.id)
            .limit(1)
            .get();

        String teacherId = '';
        String subject = 'General';
        if (teachersSnapshot.docs.isNotEmpty) {
          final teacherData = teachersSnapshot.docs.first.data();
          teacherId = teachersSnapshot.docs.first.id;
          subject = teacherData['subject'] ?? 'General';
        }

        classes.add(
          ClassModel(
            id: divisionDoc.id,
            name: divisionData['name'] ?? 'Unknown Division',
            subject: subject,
            institutionId: divisionData['institutionId'] ?? '',
            divisionId: divisionDoc.id,
            gradeId: divisionData['gradeId'] ?? '',
            academicYearId: divisionData['academicYearId'] ?? '',
            classCode: divisionData['name'] ?? 'A',
            teacherId: teacherId,
            studentIds: [],
            coTeacherIds: [],
            schedule: null,
            description: divisionData['description'],
            createdAt: (divisionData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            isActive: divisionData['isActive'] ?? true,
          ),
        );
      }

      return classes;
    } catch (e) {
      return [];
    }
  }

  // Get Institution by ID
  Future<InstitutionModel?> getInstitutionById(String institutionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('institutions').doc(institutionId).get();
      if (doc.exists) {
        return InstitutionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ===== TEACHER STATS METHODS =====
// DatabaseService.dart

// Get Teacher Quizzes
// DatabaseService.dart

// Get Teacher Quizzes
  Stream<List<QuizModel>> getTeacherQuizzes(String teacherId) {
    return _firestore
        .collection('quizzes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              // 🔥 CLEANED: Removed the unnecessary cast, relying on doc.data()
              // to return Map<String, dynamic> as configured by Firestore.
              .map((doc) => QuizModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get Teacher Assignments
  Stream<List<AssignmentModel>> getTeacherAssignments(String teacherId) {
    return _firestore
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AssignmentModel.fromMap(doc.data()))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Get Assignments for Student based on their division
  Stream<List<AssignmentModel>> getStudentAssignments(String studentId) async* {
    try {
      // First get the student's data to find their division
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        yield [];
        return;
      }

      final studentData = StudentModel.fromMap(studentDoc.data()!);
      final divisionId = studentData.divisionId;

      if (divisionId.isEmpty) {
        yield [];
        return;
      }

      // Get assignments for the student's division
      yield* _firestore
          .collection('assignments')
          .where('divisionId', isEqualTo: divisionId)
          .where('isActive', isEqualTo: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AssignmentModel.fromMap(doc.data()))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          );
    } catch (e) {
      print('Error getting student assignments: $e');
      yield [];
    }
  }

  // Get Announcements for Student based on their division
  Stream<List<AnnouncementModel>> getStudentAnnouncements(
    String studentId,
  ) async* {
    try {
      // First get the student's data
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) {
        yield [];
        return;
      }

      final studentData = StudentModel.fromMap(studentDoc.data()!);
      final divisionId = studentData.divisionId;

      if (divisionId.isEmpty) {
        yield [];
        return;
      }

      // Get announcements for the student's division
      yield* _firestore
          .collection('announcements')
          .where('divisionId', isEqualTo: divisionId)
          .where('isPublished', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      print('Error getting student announcements: $e');
      yield [];
    }
  }

  // Update announcement creation to handle the new schema properly
  Future<String?> createAnnouncementNew({
    required String teacherId,
    required String title,
    required String content,
    required String institutionId,
    String? divisionId,
    List<String> classIds = const [],
    DateTime? scheduledFor,
  }) async {
    try {
      final announcement = AnnouncementModel(
        id: _firestore.collection('announcements').doc().id,
        title: title,
        content: content,
        institutionId: institutionId,
        divisionId: divisionId,
        teacherId: teacherId,
        classIds: classIds,
        createdAt: DateTime.now(),
        scheduledFor: scheduledFor,
        isPublished:
            scheduledFor == null || scheduledFor.isBefore(DateTime.now()),
      );

      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .set(announcement.toMap());
      return null;
    } catch (e) {
      return 'Error creating announcement: $e';
    }
  }

  // Get class student count - Using division
  Future<int> getClassStudentCount(String divisionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('divisionId', isEqualTo: divisionId)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting class student count: $e');
      return 0;
    }
  }

  // Get student by ID
  Future<StudentModel?> getStudent(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (doc.exists) {
        return StudentModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting student: $e');
      return null;
    }
  }

  // Get all students
  Stream<List<StudentModel>> getAllStudents() {
    return _firestore.collection('students').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get student submissions for assignments
  Stream<List<AssignmentSubmissionModel>> getStudentSubmissions(
    String studentId,
  ) {
    return _firestore
        .collection('assignment_submissions')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AssignmentSubmissionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get available quizzes for student
  Stream<List<QuizModel>> getStudentAvailableQuizzes(String studentId) {
    return _firestore
        .collection('quizzes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Division-based content retrieval methods
  Stream<List<CourseModel>> getCoursesByDivision(String divisionId) {
    return _firestore
        .collection('courses')
        .where('divisionId', isEqualTo: divisionId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CourseModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<AssignmentModel>> getAssignmentsByDivision(String divisionId) {
    return _firestore
        .collection('assignments')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AssignmentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<AnnouncementModel>> getAnnouncementsByDivision(
    String divisionId,
  ) {
    return _firestore
        .collection('announcements')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AnnouncementModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<QuizModel>> getQuizzesByDivision(String divisionId) {
    return _firestore
        .collection('quizzes')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuizModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<StudentModel>> getStudentsByDivision(String divisionId) {
    return _firestore
        .collection('students')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<TeacherModel>> getTeachersByDivision(String divisionId) {
    return _firestore
        .collection('teachers')
        .where('divisionId', isEqualTo: divisionId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeacherModel.fromMap(doc.data()))
              .toList(),
        );
  }

  //by ganesh
  Future<String?> submitQuizAttempt(QuizAttemptModel attempt) async {
    try {
      await _firestore
          .collection('quiz_attempts')
          .doc(attempt.id)
          .set(attempt.toMap());
      return null;
    } catch (e) {
      return e.toString();
    }
  }
  //Added By Kaustubh For Course Content screen
  // ===== COURSE MATERIALS OPERATIONS =====
  // ===== COURSE MATERIALS OPERATIONS =====

  // Create Course Material
  Future<String?> createCourseMaterial(CourseMaterial material) async {
    try {
      await _firestore
          .collection('course_materials')
          .doc(material.id)
          .set(material.toMap());
      return null;
    } catch (e) {
      return 'Error creating course material: $e';
    }
  }

  // Get Course Materials by Course
  // Stream<List<CourseMaterial>> getCourseMaterials(String courseId) {
  //   return _firestore
  //       .collection('course_materials')
  //       .where('courseId', isEqualTo: courseId)
  //       // Remove isActive filter since it doesn't exist in your data
  //       .orderBy('uploadedAt', descending: true)
  //       .snapshots()
  //       .map(
  //         (snapshot) =>
  //             snapshot.docs
  //                 .map((doc) => CourseMaterial.fromMap(doc.data()))
  //                 .toList(),
  //       );
  // }
  Stream<List<CourseMaterial>> getCourseMaterials(String courseId) {
    try {
      print('DB: Querying course_materials for course: $courseId');
      return _firestore
          .collection('course_materials')
          .where('courseId', isEqualTo: courseId)
          .snapshots()
          .map((snapshot) {
        print('DB: Got ${snapshot.docs.length} materials from Firestore');
        final materials = snapshot.docs.map((doc) {
          print('DB: Processing doc ${doc.id}');
          // Use the main fromMap constructor and pass the id separately
          return CourseMaterial.fromMap({...doc.data(), 'id': doc.id});
        }).toList();
        print('DB: Returning ${materials.length} materials');
        return materials;
      });
    } catch (e) {
      print('Error getting course materials: $e');
      return Stream.value([]);
    }
  }

  // Update Course Material
  Future<String?> updateCourseMaterial(CourseMaterial material) async {
    try {
      await _firestore
          .collection('course_materials')
          .doc(material.id)
          .update(material.toMap());
      return null;
    } catch (e) {
      return 'Error updating course material: $e';
    }
  }

  // Delete Course Material (Soft delete) - Update this if you add isActive later
  Future<String?> deleteCourseMaterial(String materialId) async {
    try {
      // For now, do hard delete since isActive field doesn't exist
      await _firestore.collection('course_materials').doc(materialId).delete();
      return null;
    } catch (e) {
      return 'Error deleting course material: $e';
    }
  }

  // Get Course Material by ID
  Future<CourseMaterial?> getCourseMaterialById(String materialId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('course_materials').doc(materialId).get();
      if (doc.exists) {
        return CourseMaterial.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  //Added by kaustubh
  Stream<List<AttendanceModel>> getAttendanceForClass(
      String classId, DateTime startDate, DateTime endDate) {
    return _firestore
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data()))
            .toList());
  }
}
