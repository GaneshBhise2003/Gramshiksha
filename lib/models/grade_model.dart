import 'package:cloud_firestore/cloud_firestore.dart';

class GradeModel {
  final String id;
  final String name; // e.g., "10th Class", "12th Class", "First Year", "Second Year"
  final String institutionId;
  final String academicYearId;
  final int levelNumber; // 10, 12, 1 (for college years), etc.
  final String type; // "school" or "college"
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  GradeModel({
    required this.id,
    required this.name,
    required this.institutionId,
    required this.academicYearId,
    required this.levelNumber,
    required this.type,
    this.description,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'institutionId': institutionId,
      'academicYearId': academicYearId,
      'levelNumber': levelNumber,
      'type': type,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      institutionId: map['institutionId'] ?? '',
      academicYearId: map['academicYearId'] ?? '',
      levelNumber: map['levelNumber'] ?? 0,
      type: map['type'] ?? 'school',
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  GradeModel copyWith({
    String? id,
    String? name,
    String? institutionId,
    String? academicYearId,
    int? levelNumber,
    String? type,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return GradeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      institutionId: institutionId ?? this.institutionId,
      academicYearId: academicYearId ?? this.academicYearId,
      levelNumber: levelNumber ?? this.levelNumber,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}