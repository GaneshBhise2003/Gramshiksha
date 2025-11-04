// import 'package:cloud_firestore/cloud_firestore.dart';

// class CourseModel {
//   final String id;
//   final String title;
//   final String description;
//   final String institutionId; // Reference to institution
//   final String divisionId; // Reference to division
//   final String classId;
//   final String teacherId;
//   final List<CourseMaterial> materials;
//   final DateTime createdAt;
//   final bool isActive;

//   // 👇 Added fields for PDF, image, and Drive link
//   final String? pdfPath;
//   final String? imagePath;
//   final String? driveLink;

//   CourseModel({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.institutionId,
//     required this.divisionId,
//     required this.classId,
//     required this.teacherId,
//     this.materials = const [],
//     required this.createdAt,
//     this.isActive = true,
//     this.pdfPath,
//     this.imagePath,
//     this.driveLink,
//   });

//   // ✅ Convert to Firestore map
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'institutionId': institutionId,
//       'divisionId': divisionId,
//       'classId': classId,
//       'teacherId': teacherId,
//       'materials': materials.map((m) => m.toMap()).toList(),
//       'createdAt': Timestamp.fromDate(createdAt),
//       'isActive': isActive,
//       'pdfPath': pdfPath,
//       'imagePath': imagePath,
//       'driveLink': driveLink,
//     };
//   }

//   // ✅ Convert from Firestore map
//   factory CourseModel.fromMap(Map<String, dynamic> map) {
//     return CourseModel(
//       id: map['id'] ?? '',
//       title: map['title'] ?? '',
//       description: map['description'] ?? '',
//       institutionId: map['institutionId'] ?? '',
//       divisionId: map['divisionId'] ?? '',
//       classId: map['classId'] ?? '',
//       teacherId: map['teacherId'] ?? '',
//       materials: (map['materials'] as List<dynamic>?)
//               ?.map((m) => CourseMaterial.fromMap(m as Map<String, dynamic>))
//               .toList() ??
//           [],
//       createdAt: map['createdAt'] != null
//           ? (map['createdAt'] as Timestamp).toDate()
//           : DateTime.now(),
//       isActive: map['isActive'] ?? true,
//       pdfPath: map['pdfPath'],
//       imagePath: map['imagePath'],
//       driveLink: map['driveLink'],
//     );
//   }

//   // ✅ Helper for updating courses easily
//   CourseModel copyWith({
//     String? title,
//     String? description,
//     String? pdfPath,
//     String? imagePath,
//     String? driveLink,
//     bool? isActive,
//   }) {
//     return CourseModel(
//       id: id,
//       title: title ?? this.title,
//       description: description ?? this.description,
//       institutionId: institutionId,
//       divisionId: divisionId,
//       classId: classId,
//       teacherId: teacherId,
//       materials: materials,
//       createdAt: createdAt,
//       isActive: isActive ?? this.isActive,
//       pdfPath: pdfPath ?? this.pdfPath,
//       imagePath: imagePath ?? this.imagePath,
//       driveLink: driveLink ?? this.driveLink,
//     );
//   }
// }

// // 🔹 Model for materials inside each course
// class CourseMaterial {
//   final String id;
//   final String title;
//   final String? description;
//   final String? url;
//   final String type; // 'video', 'document', 'link', 'note'
//   final DateTime uploadedAt;

//   CourseMaterial({
//     required this.id,
//     required this.title,
//     this.description,
//     this.url,
//     required this.type,
//     required this.uploadedAt,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'description': description,
//       'url': url,
//       'type': type,
//       'uploadedAt': Timestamp.fromDate(uploadedAt),
//     };
//   }

//   factory CourseMaterial.fromMap(Map<String, dynamic> map) {
//     return CourseMaterial(
//       id: map['id'] ?? '',
//       title: map['title'] ?? '',
//       description: map['description'],
//       url: map['url'],
//       type: map['type'] ?? 'document',
//       uploadedAt: map['uploadedAt'] != null
//           ? (map['uploadedAt'] as Timestamp).toDate()
//           : DateTime.now(),
//     );
//   }
// }

//Added BY kaustubh for the course_content
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String institutionId; // Reference to institution
  final String divisionId; // Reference to division
  final String classId;
  final String teacherId;
  final List<CourseMaterial> materials;
  final DateTime createdAt;
  final bool isActive;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.institutionId,
    required this.divisionId,
    required this.classId,
    required this.teacherId,
    this.materials = const [],
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'institutionId': institutionId,
      'divisionId': divisionId,
      'classId': classId,
      'teacherId': teacherId,
      'materials': materials.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      institutionId: map['institutionId'] ?? '',
      divisionId: map['divisionId'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      materials: (map['materials'] as List<dynamic>?)
              ?.map((m) => CourseMaterial.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class CourseMaterial {
  final String id;
  final String title;
  final String courseId;
  final String? description;
  final String? url;
  final String type; // 'video', 'pdf', 'image', 'link', 'note'
  final DateTime uploadedAt;
  final String? fileData; // Base64 encoded string for PDFs and images
  final String? fileName;
  final double? fileSize; // Size in KB
  final String? fileExtension;
  final String? thumbnailUrl; // For videos
  final int? duration; // For videos in seconds

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.url,
    required this.type,
    required this.uploadedAt,
    this.fileData,
    this.fileName,
    this.fileSize,
    this.fileExtension,
    this.thumbnailUrl,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileData': fileData,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileExtension': fileExtension,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
    };
  }

  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    print('=== CourseMaterial.fromMap CALLED ===');
    print('Map keys: ${map.keys}');
    print('uploadedAt value: ${map['uploadedAt']}');
    print('uploadedAt type: ${map['uploadedAt']?.runtimeType}');
    print('Full map: $map');

    // Handle timestamp conversion safely for different formats
    DateTime uploadedAt;
    if (map['uploadedAt'] is Timestamp) {
      print('Processing as Timestamp');
      uploadedAt = (map['uploadedAt'] as Timestamp).toDate();
    } else if (map['uploadedAt'] is int) {
      print('Processing as int timestamp');
      uploadedAt = DateTime.fromMillisecondsSinceEpoch(map['uploadedAt']);
    } else if (map['uploadedAt'] is String) {
      print('Processing as String');
      uploadedAt = DateTime.parse(map['uploadedAt']);
    } else {
      print('Using current time as fallback');
      uploadedAt = DateTime.now();
    }

    print('Final uploadedAt: $uploadedAt');

    final material = CourseMaterial(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      url: map['url'],
      type: map['type'] ?? 'document',
      uploadedAt: uploadedAt,
      fileData: map['fileData'],
      fileName: map['fileName'],
      fileSize: map['fileSize'] != null
          ? double.parse(map['fileSize'].toString())
          : null,
      fileExtension: map['fileExtension'],
      thumbnailUrl: map['thumbnailUrl'],
      duration: map['duration'],
    );

    print('=== CourseMaterial CREATED: ${material.title} ===');
    return material;
  }

  // Helper method to check if material has file data
  bool get hasFileData => fileData != null && fileData!.isNotEmpty;

  // Helper method to get display file size
  String get displayFileSize {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) {
      return '${fileSize!.toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / 1024).toStringAsFixed(1)} MB';
    }
  }
}
