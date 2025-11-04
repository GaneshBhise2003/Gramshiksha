import 'package:cloud_firestore/cloud_firestore.dart';

enum InstitutionType { college, school }

class InstitutionModel {
  final String id;
  final String name;
  final InstitutionType type;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final String adminId; // ID of the admin who manages this institution
  final String code; // Unique institution code
  final DateTime createdAt;
  final bool isActive;

  InstitutionModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.phone,
    this.email,
    this.website,
    required this.adminId,
    required this.code,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'adminId': adminId,
      'code': code,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory InstitutionModel.fromMap(Map<String, dynamic> map) {
    return InstitutionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: InstitutionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => InstitutionType.school,
      ),
      address: map['address'] ?? '',
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      adminId: map['adminId'] ?? '',
      code: map['code'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  InstitutionModel copyWith({
    String? id,
    String? name,
    InstitutionType? type,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? adminId,
    String? code,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return InstitutionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      adminId: adminId ?? this.adminId,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
