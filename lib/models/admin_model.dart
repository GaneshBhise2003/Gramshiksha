import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String?
  institutionId; // Optional - admin can create institution after registration
  final DateTime createdAt;
  final bool isActive;
  final bool isSuperAdmin; // Super admin can manage multiple institutions

  AdminModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.institutionId,
    required this.createdAt,
    this.isActive = true,
    this.isSuperAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'institutionId': institutionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'isSuperAdmin': isSuperAdmin,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      institutionId: map['institutionId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      isSuperAdmin: map['isSuperAdmin'] ?? false,
    );
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? institutionId,
    DateTime? createdAt,
    bool? isActive,
    bool? isSuperAdmin,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      institutionId: institutionId ?? this.institutionId,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
    );
  }
}
