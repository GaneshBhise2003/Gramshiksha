// import 'package:cloud_firestore/cloud_firestore.dart';

// enum AttendanceStatus { present, absent, late }

// class AttendanceModel {
//   final String id;
//   final String institutionId; // Reference to college/school
//   final String divisionId; // Reference to division
//   final String classId;
//   final DateTime date;
//   final Map<String, AttendanceStatus> studentAttendance;
//   final String markedBy;
//   final DateTime createdAt;

//   AttendanceModel({
//     required this.id,
//     required this.institutionId,
//     required this.divisionId,
//     required this.classId,
//     required this.date,
//     required this.studentAttendance,
//     required this.markedBy,
//     required this.createdAt,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'institutionId': institutionId,
//       'divisionId': divisionId,
//       'classId': classId,
//       'date': Timestamp.fromDate(date),
//       'studentAttendance': studentAttendance.map(
//         (key, value) => MapEntry(key, value.toString().split('.').last),
//       ),
//       'markedBy': markedBy,
//       'createdAt': Timestamp.fromDate(createdAt),
//     };
//   }

//   factory AttendanceModel.fromMap(Map<String, dynamic> map) {
//     Map<String, AttendanceStatus> attendance = {};
//     if (map['studentAttendance'] != null) {
//       (map['studentAttendance'] as Map<String, dynamic>).forEach((key, value) {
//         attendance[key] = AttendanceStatus.values.firstWhere(
//           (e) => e.toString().split('.').last == value,
//           orElse: () => AttendanceStatus.absent,
//         );
//       });
//     }

//     return AttendanceModel(
//       id: map['id'] ?? '',
//       institutionId: map['institutionId'] ?? '',
//       divisionId: map['divisionId'] ?? '',
//       classId: map['classId'] ?? '',
//       date: (map['date'] as Timestamp).toDate(),
//       studentAttendance: attendance,
//       markedBy: map['markedBy'] ?? '',
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceModel {
  final String id;
  final String institutionId;
  final String divisionId;
  final String classId;
  final DateTime date;
  final Map<String, AttendanceStatus> studentAttendance;
  final String markedBy;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.institutionId,
    required this.divisionId,
    required this.classId,
    required this.date,
    required this.studentAttendance,
    required this.markedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'classId': classId,
      'date': Timestamp.fromDate(date),
      'studentAttendance': studentAttendance.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'markedBy': markedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    Map<String, AttendanceStatus> attendance = {};
    if (map['studentAttendance'] != null) {
      (map['studentAttendance'] as Map<String, dynamic>).forEach((key, value) {
        attendance[key] = AttendanceStatus.values.firstWhere(
          (e) => e.toString().split('.').last == value,
          orElse: () => AttendanceStatus.absent,
        );
      });
    }

    return AttendanceModel(
      id: map['id'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'] ?? '',
      classId: map['classId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      studentAttendance: attendance,
      markedBy: map['markedBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
