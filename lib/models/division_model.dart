import 'package:cloud_firestore/cloud_firestore.dart';

class DivisionModel {
  final String id;
  final String name; // e.g., "A", "B", "C"
  final String institutionId; // Reference to college/school
  final String gradeId; // Reference to grade (10th, 12th, First Year, etc.)
  final String academicYearId; // Reference to academic year
  final String? description;
  final int maxStudents; // Maximum students allowed in this division
  final DateTime createdAt;
  final bool isActive;

  DivisionModel({
    required this.id,
    required this.name,
    required this.institutionId,
    required this.gradeId,
    required this.academicYearId,
    this.description,
    this.maxStudents = 50,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institutionId': institutionId,
      'gradeId': gradeId,
      'academicYearId': academicYearId,
      'description': description,
      'maxStudents': maxStudents,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory DivisionModel.fromMap(Map<String, dynamic> map) {
    return DivisionModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      institutionId: map['institutionId'] ?? '',
      gradeId: map['gradeId'] ?? '',
      academicYearId: map['academicYearId'] ?? '',
      description: map['description'],
      maxStudents: map['maxStudents'] ?? 50,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  DivisionModel copyWith({
    String? id,
    String? name,
    String? institutionId,
    String? gradeId,
    String? academicYearId,
    String? description,
    int? maxStudents,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return DivisionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      institutionId: institutionId ?? this.institutionId,
      gradeId: gradeId ?? this.gradeId,
      academicYearId: academicYearId ?? this.academicYearId,
      description: description ?? this.description,
      maxStudents: maxStudents ?? this.maxStudents,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Backward compatibility getters
  int? get yearLevel => null; // Legacy field, now use grade
  String get academicYear =>
      academicYearId; // Use academicYearId as academicYear for backward compatibility
}
