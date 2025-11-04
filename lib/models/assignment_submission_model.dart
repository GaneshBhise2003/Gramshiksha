import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final List<Map<String, dynamic>> attachments;
  final DateTime submittedAt;
  final bool isGraded;
  final double? marks;
  final double? totalMarks;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    required this.attachments,
    required this.submittedAt,
    required this.isGraded,
    this.marks,
    this.totalMarks,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'content': content,
      'attachments': attachments,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'isGraded': isGraded,
      'marks': marks,
      'totalMarks': totalMarks,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'gradedBy': gradedBy,
    };
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmissionModel(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      content: map['content'],
      attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      isGraded: map['isGraded'] ?? false,
      marks: map['marks']?.toDouble(),
      totalMarks: map['totalMarks']?.toDouble(),
      feedback: map['feedback'],
      gradedAt:
          map['gradedAt'] != null
              ? (map['gradedAt'] as Timestamp).toDate()
              : null,
      gradedBy: map['gradedBy'],
    );
  }

  AssignmentSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? content,
    List<Map<String, dynamic>>? attachments,
    DateTime? submittedAt,
    bool? isGraded,
    double? marks,
    double? totalMarks,
    String? feedback,
    DateTime? gradedAt,
    String? gradedBy,
  }) {
    return AssignmentSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      submittedAt: submittedAt ?? this.submittedAt,
      isGraded: isGraded ?? this.isGraded,
      marks: marks ?? this.marks,
      totalMarks: totalMarks ?? this.totalMarks,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
    );
  }
}
