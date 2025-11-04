// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/database_service.dart';
// import '../../models/student_model.dart';
// import '../../models/course_model.dart';

// class StudentCoursesScreen extends StatefulWidget {
//   final StudentModel student;
//   final String divisionId;

//   const StudentCoursesScreen({
//     super.key,
//     required this.student,
//     required this.divisionId,
//   });

//   @override
//   State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
// }

// class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final databaseService = Provider.of<DatabaseService>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Courses'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: StreamBuilder<List<CourseModel>>(
//         stream: databaseService.getCoursesByDivision(widget.divisionId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No courses available'));
//           }

//           final courses = snapshot.data!;

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: courses.length,
//             itemBuilder: (context, index) {
//               final course = courses[index];
//               return Card(
//                 child: ListTile(
//                   leading: const Icon(Icons.book),
//                   title: Text(course.title),
//                   subtitle: Text(
//                     '${course.materials.length} materials - ${course.description}',
//                   ),
//                   onTap: () => _showCourseMaterials(course),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _showCourseMaterials(CourseModel course) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: Text(course.title),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(course.description),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'Materials:',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 ...course.materials.map(
//                   (material) => Text('- ${material.title}'),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//     );
//   }
// }
//updated by kaustubh
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For base64 decoding

import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/course_model.dart';

class StudentCoursesScreen extends StatefulWidget {
  final StudentModel student;
  final String divisionId;

  const StudentCoursesScreen({
    super.key,
    required this.student,
    required this.divisionId,
  });

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<CourseModel>>(
        stream: databaseService.getCoursesByDivision(widget.divisionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No courses available for your class',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final courses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue),
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: StreamBuilder<List<CourseMaterial>>(
                    stream: databaseService.getCourseMaterials(course.id),
                    builder: (context, materialSnapshot) {
                      final materialCount = materialSnapshot.data?.length ?? 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$materialCount materials',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCourseMaterials(course, databaseService),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCourseMaterials(
    CourseModel course,
    DatabaseService databaseService,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(course.title),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(course.description),
                      const SizedBox(height: 20),
                      Text(
                        'Course Materials',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<CourseMaterial>>(
                        stream: databaseService.getCourseMaterials(
                          course.id,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No materials available',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Check back later for course materials',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final materials = snapshot.data!;
                          return Column(
                            children: materials
                                .map(
                                  (material) => Card(
                                    margin: const EdgeInsets.only(
                                      bottom: 8,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getMaterialColor(
                                          material.type,
                                        ),
                                        child: Icon(
                                          _getMaterialIcon(
                                            material.type,
                                          ),
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        material.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (material.description != null)
                                            Text(
                                              material.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                material.type.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '•',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                DateFormat(
                                                  'MMM dd, yyyy',
                                                ).format(
                                                  material.uploadedAt,
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.download,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      onTap: () => _openMaterial(material),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMaterial(CourseMaterial material) {
    if (material.type == 'video' && material.url != null) {
      _openGoogleDriveLink(material.url!);
    } else if (material.type == 'pdf' && material.hasFileData) {
      _openPdfFromBase64(material);
    } else if (material.type == 'image' && material.hasFileData) {
      _showImageFromBase64(material);
    } else if (material.type == 'link' && material.url != null) {
      _openExternalLink(material.url!);
    } else if (material.type == 'note' && material.url != null) {
      _showNoteDialog(material.url!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open ${material.type} material'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'link':
        return Icons.link;
      case 'note':
        return Icons.note;
      default:
        return Icons.file_present;
    }
  }

  Color _getMaterialColor(String type) {
    switch (type) {
      case 'video':
        return Colors.red;
      case 'pdf':
        return Colors.blue;
      case 'image':
        return Colors.purple;
      case 'link':
        return Colors.green;
      case 'note':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _openPdfFromBase64(CourseMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open PDF: ${material.fileName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'PDF Document: ${material.title}',
              textAlign: TextAlign.center,
            ),
            if (material.fileSize != null)
              Text(
                'Size: ${material.displayFileSize}',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening PDF: ${material.title}'),
                  backgroundColor: Colors.green,
                ),
              );
              // Here you would implement actual PDF opening logic
            },
            child: const Text('Open PDF'),
          ),
        ],
      ),
    );
  }

  void _showImageFromBase64(CourseMaterial material) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(
                base64Decode(material.fileData!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text('Failed to load image'),
                        Text(
                          material.fileName ?? 'Unknown file',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(String noteContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: SingleChildScrollView(
          child: Text(
            noteContent,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleDriveLink(String url) async {
    // Show confirmation dialog first
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Google Drive Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'This will open the video in Google Drive.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure you have the Google Drive app installed for the best experience.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open in Drive'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      try {
        final uri = Uri.parse(url);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: Try to open in browser if direct launch fails
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            throw Exception('Could not launch $url');
          }
        }
      } catch (e) {
        print('Error opening Google Drive link: $e');

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cannot Open Link'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to open the Google Drive link.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can try copying the link and opening it manually:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        url,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _openExternalLink(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print('Error opening external link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
