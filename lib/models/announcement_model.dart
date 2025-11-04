import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String institutionId; // Reference to college/school
  final String?
  divisionId; // Optional - announcement can be for entire institution
  final String teacherId;
  final List<String>
  classIds; // Empty means announcement for all classes in division/institution
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isPublished;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.institutionId,
    this.divisionId,
    required this.teacherId,
    required this.classIds,
    required this.createdAt,
    this.scheduledFor,
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'teacherId': teacherId,
      'classIds': classIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor':
          scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'isPublished': isPublished,
    };
  }

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    return AnnouncementModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'],
      teacherId: map['teacherId'] ?? '',
      classIds: List<String>.from(map['classIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledFor:
          map['scheduledFor'] != null
              ? (map['scheduledFor'] as Timestamp).toDate()
              : null,
      isPublished: map['isPublished'] ?? true,
    );
  }
}
