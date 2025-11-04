import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String uid;
  final String email;
  final String name;
  final String institutionId; // Reference to college/school
  final String? divisionId; // Reference to assigned division
  final String? phone;
  final String? subject;
  final List<String> classIds;
  final DateTime createdAt;
  final bool isActive;

  TeacherModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.institutionId,
    this.divisionId,
    this.phone,
    this.subject,
    this.classIds = const [],
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'phone': phone,
      'subject': subject,
      'classIds': classIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'],
      phone: map['phone'],
      subject: map['subject'],
      classIds: List<String>.from(map['classIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  TeacherModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? institutionId,
    String? phone,
    String? subject,
    List<String>? classIds,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TeacherModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      institutionId: institutionId ?? this.institutionId,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      classIds: classIds ?? this.classIds,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
