import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicYearModel {
  final String id;
  final String name; // e.g., "2025-26"
  final String institutionId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isCurrent;
  final DateTime createdAt;

  AcademicYearModel({
    required this.id,
    required this.name,
    required this.institutionId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isCurrent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institutionId': institutionId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'isCurrent': isCurrent,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AcademicYearModel.fromMap(Map<String, dynamic> map) {
    return AcademicYearModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      institutionId: map['institutionId'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      isCurrent: map['isCurrent'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  AcademicYearModel copyWith({
    String? id,
    String? name,
    String? institutionId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return AcademicYearModel(
      id: id ?? this.id,
      name: name ?? this.name,
      institutionId: institutionId ?? this.institutionId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
