import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { pending, submitted, graded, late }

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String institutionId; // Reference to college/school
  final String divisionId; // Reference to division
  final String classId;
  final String teacherId;
  final DateTime dueDate;
  final int totalMarks;
  final DateTime createdAt;
  final bool isActive;
  final List<String> attachments; // Added attachments property

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.institutionId,
    required this.divisionId,
    required this.classId,
    required this.teacherId,
    required this.dueDate,
    required this.totalMarks,
    required this.createdAt,
    this.isActive = true,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'classId': classId,
      'teacherId': teacherId,
      'dueDate': Timestamp.fromDate(dueDate),
      'totalMarks': totalMarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'attachments': attachments,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      totalMarks: map['totalMarks'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? answer;
  final DateTime submittedAt;
  final AssignmentStatus status;
  final int? marksObtained;
  final String? feedback;
  final DateTime? gradedAt;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.answer,
    required this.submittedAt,
    required this.status,
    this.marksObtained,
    this.feedback,
    this.gradedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'answer': answer,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.toString().split('.').last,
      'marksObtained': marksObtained,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
    };
  }

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      answer: map['answer'],
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => AssignmentStatus.pending,
      ),
      marksObtained: map['marksObtained'],
      feedback: map['feedback'],
      gradedAt:
          map['gradedAt'] != null
              ? (map['gradedAt'] as Timestamp).toDate()
              : null,
    );
  }
}
