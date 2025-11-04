import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course_model.dart';
import 'course_create_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final List<CourseMaterial> courseMaterials;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.courseMaterials,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUser = authService.currentUser;
    final isTeacher = currentUser?.uid == widget.course.teacherId;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (isTeacher)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CourseCreateScreen(course: widget.course),
                    ),
                  );
                },
                tooltip: 'Edit Course',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.share),
              onPressed: () {
                // TODO: Implement share functionality
              },
              tooltip: 'Share Course',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: Colors.blue[700], size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Created ${_formatDate(widget.course.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.course.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // Use passed courseMaterials for count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.courseMaterials.length} Materials',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Materials Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Course Materials',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        // Use passed courseMaterials for count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.courseMaterials.length}',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Use passed courseMaterials directly
                    _buildMaterialsList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    if (widget.courseMaterials.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No materials available yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course.teacherId ==
                      Provider.of<AuthService>(
                        context,
                        listen: false,
                      ).currentUser?.uid
                  ? 'Add materials to help students learn better'
                  : 'Your teacher will add materials soon',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.courseMaterials.length,
      itemBuilder: (context, index) {
        final material = widget.courseMaterials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMaterialColor(material.type),
              child: Icon(_getMaterialIcon(material.type), color: Colors.white),
            ),
            title: Text(
              material.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (material.description != null &&
                    material.description!.isNotEmpty) ...[
                  Text(
                    material.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  '${material.type.toUpperCase()} • Uploaded ${_formatDate(material.uploadedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: _getMaterialTrailing(material),
            onTap: () => _openMaterial(material),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
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
        return Icons.folder;
    }
  }

  Widget? _getMaterialTrailing(CourseMaterial material) {
    if (material.type == 'note') {
      return IconButton(
        icon: const Icon(Icons.visibility),
        onPressed: () => _openMaterial(material),
      );
    } else if (material.url != null || material.hasFileData) {
      return IconButton(
        icon: const Icon(Icons.open_in_new),
        onPressed: () => _openMaterial(material),
      );
    }
    return null;
  }

  Future<void> _openMaterial(CourseMaterial material) async {
    if (material.type == 'note') {
      // Show note content in dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(material.title),
          content: SingleChildScrollView(
            child: Text(material.url ?? 'No content available'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (material.type == 'image' && material.hasFileData) {
      // Show image in dialog
      _showImageFromBase64(material);
    } else if (material.type == 'pdf' && material.hasFileData) {
      // Handle PDF
      _openPdfFromBase64(material);
    } else if (material.url != null) {
      // Open external URL for video, link, etc.
      final uri = Uri.parse(material.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open ${material.type}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open ${material.type}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _openPdfFromBase64(CourseMaterial material) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening PDF: ${material.fileName}'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement PDF viewer
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
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
