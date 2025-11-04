import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String uid;
  final String email;
  final String name;
  final String rollNumber;
  final String institutionId; // Reference to college/school
  final String academicYearId; // Reference to academic year
  final String gradeId; // Reference to grade (10th, 12th, First Year)
  final String divisionId; // Reference to division (A, B, C)
  final String? phone;
  final String? parentEmail;
  final String? address; // Added address property
  final DateTime createdAt;
  final bool isActive;
  final bool isFirstLogin;

  StudentModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.rollNumber,
    required this.institutionId,
    required this.academicYearId,
    required this.gradeId,
    required this.divisionId,
    this.phone,
    this.parentEmail,
    this.address,
    required this.createdAt,
    this.isActive = true,
    this.isFirstLogin = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'rollNumber': rollNumber,
      'institutionId': institutionId,
      'academicYearId': academicYearId,
      'gradeId': gradeId,
      'divisionId': divisionId,
      'phone': phone,
      'parentEmail': parentEmail,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'isFirstLogin': isFirstLogin,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      institutionId: map['institutionId'] ?? '',
      academicYearId: map['academicYearId'] ?? '',
      gradeId: map['gradeId'] ?? '',
      divisionId: map['divisionId'] ?? '',
      phone: map['phone'],
      parentEmail: map['parentEmail'],
      address: map['address'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      isFirstLogin: map['isFirstLogin'] ?? true,
    );
  }

  StudentModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? rollNumber,
    String? institutionId,
    String? academicYearId,
    String? gradeId,
    String? divisionId,
    String? phone,
    String? parentEmail,
    DateTime? createdAt,
    bool? isActive,
    bool? isFirstLogin,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      institutionId: institutionId ?? this.institutionId,
      academicYearId: academicYearId ?? this.academicYearId,
      gradeId: gradeId ?? this.gradeId,
      divisionId: divisionId ?? this.divisionId,
      phone: phone ?? this.phone,
      parentEmail: parentEmail ?? this.parentEmail,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }

  // Backward compatibility getter for classId
  String get classId =>
      divisionId; // For now, use divisionId as classId for compatibility
}
