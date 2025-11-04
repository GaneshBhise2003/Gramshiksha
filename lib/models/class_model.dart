// import 'package:cloud_firestore/cloud_firestore.dart';

// class ClassModel {
//   final String id;
//   final String name; // e.g., "Mathematics", "Physics", "English"
//   final String subject;
//   final String institutionId; // Reference to college/school
//   final String divisionId; // Reference to division (A, B, C)
//   final String gradeId; // Reference to grade (10th, 12th, First Year)
//   final String academicYearId; // Reference to academic year
//   final String classCode;
//   final String teacherId;
//   final List<String> studentIds;
//   final List<String> coTeacherIds;
//   final String? schedule;
//   final String? description;
//   final DateTime createdAt;
//   final bool isActive;

//   ClassModel({
//     required this.id,
//     required this.name,
//     required this.subject,
//     required this.institutionId,
//     required this.divisionId,
//     required this.gradeId,
//     required this.academicYearId,
//     required this.classCode,
//     required this.teacherId,
//     this.studentIds = const [],
//     this.coTeacherIds = const [],
//     this.schedule,
//     this.description,
//     required this.createdAt,
//     this.isActive = true,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'subject': subject,
//       'institutionId': institutionId,
//       'divisionId': divisionId,
//       'gradeId': gradeId,
//       'academicYearId': academicYearId,
//       'classCode': classCode,
//       'teacherId': teacherId,
//       'studentIds': studentIds,
//       'coTeacherIds': coTeacherIds,
//       'schedule': schedule,
//       'description': description,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'isActive': isActive,
//     };
//   }

//   factory ClassModel.fromMap(Map<String, dynamic> map) {
//     return ClassModel(
//       id: map['id'] ?? '',
//       name: map['name'] ?? '',
//       subject: map['subject'] ?? '',
//       institutionId: map['institutionId'] ?? '',
//       divisionId: map['divisionId'] ?? '',
//       gradeId: map['gradeId'] ?? '',
//       academicYearId: map['academicYearId'] ?? '',
//       classCode: map['classCode'] ?? '',
//       teacherId: map['teacherId'] ?? '',
//       studentIds: List<String>.from(map['studentIds'] ?? []),
//       coTeacherIds: List<String>.from(map['coTeacherIds'] ?? []),
//       schedule: map['schedule'],
//       description: map['description'],
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//       isActive: map['isActive'] ?? true,
//     );
//   }

//   ClassModel copyWith({
//     String? id,
//     String? name,
//     String? subject,
//     String? institutionId,
//     String? divisionId,
//     String? gradeId,
//     String? academicYearId,
//     String? classCode,
//     String? teacherId,
//     List<String>? studentIds,
//     List<String>? coTeacherIds,
//     String? schedule,
//     String? description,
//     DateTime? createdAt,
//     bool? isActive,
//   }) {
//     return ClassModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       subject: subject ?? this.subject,
//       institutionId: institutionId ?? this.institutionId,
//       divisionId: divisionId ?? this.divisionId,
//       gradeId: gradeId ?? this.gradeId,
//       academicYearId: academicYearId ?? this.academicYearId,
//       classCode: classCode ?? this.classCode,
//       teacherId: teacherId ?? this.teacherId,
//       studentIds: studentIds ?? this.studentIds,
//       coTeacherIds: coTeacherIds ?? this.coTeacherIds,
//       schedule: schedule ?? this.schedule,
//       description: description ?? this.description,
//       createdAt: createdAt ?? this.createdAt,
//       isActive: isActive ?? this.isActive,
//     );
//   }

//   // Backward compatibility getters
//   String get section =>
//       divisionId; // Use divisionId as section for backward compatibility
//   String get academicYear =>
//       academicYearId; // Use academicYearId as academicYear for backward compatibility
// }

//new code kaustubh
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name; // e.g., "Mathematics", "Physics", "English"
  final String subject;
  final String institutionId; // Reference to college/school
  final String divisionId; // Reference to division (A, B, C)
  final String gradeId; // Reference to grade (10th, 12th, First Year)
  final String academicYearId; // Reference to academic year
  final String classCode;
  final String teacherId;
  final List<String> studentIds;
  final List<String> coTeacherIds;
  final String? schedule;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  ClassModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.institutionId,
    required this.divisionId,
    required this.gradeId,
    required this.academicYearId,
    required this.classCode,
    required this.teacherId,
    this.studentIds = const [],
    this.coTeacherIds = const [],
    this.schedule,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'gradeId': gradeId,
      'academicYearId': academicYearId,
      'classCode': classCode,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'coTeacherIds': coTeacherIds,
      'schedule': schedule,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'] ?? '',
      gradeId: map['gradeId'] ?? '',
      academicYearId: map['academicYearId'] ?? '',
      classCode: map['classCode'] ?? '',
      teacherId: map['teacherId'] ?? '',
      studentIds: List<String>.from(map['studentIds'] ?? []),
      coTeacherIds: List<String>.from(map['coTeacherIds'] ?? []),
      schedule: map['schedule'],
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  ClassModel copyWith({
    String? id,
    String? name,
    String? subject,
    String? institutionId,
    String? divisionId,
    String? gradeId,
    String? academicYearId,
    String? classCode,
    String? teacherId,
    List<String>? studentIds,
    List<String>? coTeacherIds,
    String? schedule,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      institutionId: institutionId ?? this.institutionId,
      divisionId: divisionId ?? this.divisionId,
      gradeId: gradeId ?? this.gradeId,
      academicYearId: academicYearId ?? this.academicYearId,
      classCode: classCode ?? this.classCode,
      teacherId: teacherId ?? this.teacherId,
      studentIds: studentIds ?? this.studentIds,
      coTeacherIds: coTeacherIds ?? this.coTeacherIds,
      schedule: schedule ?? this.schedule,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Backward compatibility getters
  String get section => divisionId;
  String get academicYear => academicYearId;

  // Helper method to create ClassModel from Division data
  factory ClassModel.fromDivision({
    required String divisionId,
    required Map<String, dynamic> divisionData,
    required String teacherId,
    required String subject,
  }) {
    return ClassModel(
      id: divisionId,
      name: divisionData['name'] ?? 'Unknown Division',
      subject: subject,
      institutionId: divisionData['institutionId'] ?? '',
      divisionId: divisionId,
      gradeId: divisionData['gradeId'] ?? '',
      academicYearId: divisionData['academicYearId'] ?? '',
      classCode: divisionData['name'] ?? 'A',
      teacherId: teacherId,
      studentIds: [],
      coTeacherIds: [],
      schedule: null,
      description: divisionData['description'],
      createdAt:
          (divisionData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: divisionData['isActive'] ?? true,
    );
  }
}
