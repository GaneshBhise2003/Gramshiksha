import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gramshiksha/screens/courses/course_create_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/course_model.dart';
import '../../models/class_model.dart';
import '../../utils/responsive_helper.dart';

class CourseContentScreen extends StatefulWidget {
  const CourseContentScreen({super.key});

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TeacherModel? _cachedTeacher;
  bool _isLoadingTeacher = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final teacher = await databaseService.getTeacher(authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _cachedTeacher = teacher;
          _isLoadingTeacher = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeacher = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Content'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Courses', icon: Icon(Icons.book)),
            Tab(text: 'Create Course', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: _buildBody(isTablet),
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_isLoadingTeacher) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedTeacher == null) {
      return const Center(child: Text('Teacher data not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _CoursesListTab(teacher: _cachedTeacher!),
        _CreateCourseTab(teacher: _cachedTeacher!, isTablet: isTablet),
      ],
    );
  }
}

class _CoursesListTab extends StatefulWidget {
  final TeacherModel teacher;

  const _CoursesListTab({required this.teacher});

  @override
  State<_CoursesListTab> createState() => _CoursesListTabState();
}

class _CoursesListTabState extends State<_CoursesListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _CoursesListContent(teacher: widget.teacher);
  }
}

class _CoursesListContent extends StatefulWidget {
  final TeacherModel teacher;

  const _CoursesListContent({required this.teacher});

  @override
  State<_CoursesListContent> createState() => _CoursesListContentState();
}

class _CoursesListContentState extends State<_CoursesListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Class Filter
              StreamBuilder<List<ClassModel>>(
                stream: databaseService.getTeacherClasses(widget.teacher.uid),
                builder: (context, classSnapshot) {
                  if (!classSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final classes = classSnapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                            (classModel) => DropdownMenuItem(
                          value: classModel.id,
                          child: Text(classModel.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        // Courses List
        Expanded(
          child: _CoursesList(
            teacher: widget.teacher,
            searchQuery: _searchQuery,
            selectedClassId: _selectedClassId,
          ),
        ),
      ],
    );
  }
}

class _CoursesList extends StatefulWidget {
  final TeacherModel teacher;
  final String searchQuery;
  final String? selectedClassId;

  const _CoursesList({
    required this.teacher,
    required this.searchQuery,
    required this.selectedClassId,
  });

  @override
  State<_CoursesList> createState() => _CoursesListState();
}

class _CoursesListState extends State<_CoursesList> {
  List<CourseModel> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final courses = await databaseService.getTeacherCourses(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var courses = _courses;

    // Apply filters
    if (widget.selectedClassId != null) {
      courses = courses
          .where((course) => course.classId == widget.selectedClassId)
          .toList();
    }

    if (widget.searchQuery.isNotEmpty) {
      courses = courses.where((course) {
        return course.title.toLowerCase().contains(widget.searchQuery) ||
            course.description.toLowerCase().contains(widget.searchQuery);
      }).toList();
    }

    if (courses.isEmpty) {
      return _EmptyCoursesState(
        searchQuery: widget.searchQuery,
        hasSelectedClass: widget.selectedClassId != null,
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: ListView.builder(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        itemCount: courses.length,
        itemBuilder: (context, index) => _CourseCard(
          course: courses[index],
          databaseService: databaseService,
        ),
      ),
    );
  }
}

class _EmptyCoursesState extends StatelessWidget {
  final String searchQuery;
  final bool hasSelectedClass;

  const _EmptyCoursesState({
    required this.searchQuery,
    required this.hasSelectedClass,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (searchQuery.isNotEmpty) return 'No matching courses';
    if (hasSelectedClass) return 'No courses for selected class';
    return 'No courses found';
  }

  String _getEmptyStateSubtitle() {
    if (searchQuery.isNotEmpty) return 'Try a different search term';
    if (hasSelectedClass) return 'Create a course for this class';
    return 'Create your first course to get started';
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final DatabaseService databaseService;

  const _CourseCard({
    required this.course,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showCourseDetails(context, course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'materials',
                        child: ListTile(
                          leading: Icon(Icons.folder),
                          title: Text('Manage Materials'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCourse(context, course);
                          break;
                        case 'delete':
                          _deleteCourse(context, course);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  StreamBuilder<List<CourseMaterial>>(
                    stream: databaseService.getCourseMaterials(course.id),
                    builder: (context, snapshot) {
                      final materialCount = snapshot.data?.length ?? 0;
                      return Text(
                        '$materialCount materials',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(course.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseDetails(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveHelper.isDesktop(context) ? 600 : null,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(course.title),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(course.description),
                      const SizedBox(height: 20),
                      Text(
                        'Materials',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<CourseMaterial>>(
                        stream: databaseService.getCourseMaterials(course.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final materials = snapshot.data ?? [];
                          if (materials.isEmpty) {
                            return const Text('No materials available');
                          }

                          return Column(
                            children: materials
                                .map(
                                  (material) => ListTile(
                                leading: Icon(_getMaterialIcon(material.type)),
                                title: Text(material.title),
                                subtitle: material.description != null
                                    ? Text(material.description!)
                                    : null,
                                trailing: Text(
                                  DateFormat('MMM dd').format(material.uploadedAt),
                                ),
                                onTap: () => _openMaterial(context, material),
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
            ],
          ),
        ),
      ),
    );
  }

  void _editCourse(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CourseCreateScreen(course: course)),
    );
  }

  void _deleteCourse(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${course.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await databaseService.deleteCourse(course.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaterial(BuildContext context, CourseMaterial material) {
    if (material.type == 'video' && material.url != null) {
      _openGoogleDriveLink(context, material.url!);
    } else if (material.type == 'pdf' && material.hasFileData) {
      _openPdfFromBase64(context, material);
    } else if (material.type == 'image' && material.hasFileData) {
      _showImageFromBase64(context, material);
    } else if (material.type == 'link' && material.url != null) {
      _openExternalLink(context, material.url!);
    } else if (material.type == 'note' && material.url != null) {
      _showNoteDialog(context, material.url!);
    }
  }

  void _openPdfFromBase64(BuildContext context, CourseMaterial material) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening PDF: ${material.fileName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showImageFromBase64(BuildContext context, CourseMaterial material) {
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

  void _showNoteDialog(BuildContext context, String noteContent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note'),
        content: SingleChildScrollView(child: Text(noteContent)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleDriveLink(BuildContext context, String url) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Google Drive Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('This will open the video in Google Drive.', textAlign: TextAlign.center),
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
          throw Exception('Could not launch $url');
        }
      } catch (e) {
        if (context.mounted) {
          _showLinkErrorDialog(context, url);
        }
      }
    }
  }

  void _showLinkErrorDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Open Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Unable to open the Google Drive link.', textAlign: TextAlign.center),
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

  void _openExternalLink(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url'), backgroundColor: Colors.blue),
    );
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
}

class _CreateCourseTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateCourseTab({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateCourseTab> createState() => _CreateCourseTabState();
}

class _CreateCourseTabState extends State<_CreateCourseTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _CreateCourseForm(
      teacher: widget.teacher,
      isTablet: widget.isTablet,
    );
  }
}

class _CreateCourseForm extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateCourseForm({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateCourseForm> createState() => __CreateCourseFormState();
}

class __CreateCourseFormState extends State<_CreateCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClassId;
  bool _isLoading = false;
  List<CourseMaterial> _materials = [];
  List<ClassModel> _classes = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final classes = await databaseService.getTeacherClasses(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  void _addMaterial() {
    final temporaryCourseId = 'temp_${const Uuid().v4()}';

    showDialog(
      context: context,
      builder: (context) => _MaterialDialog(
        courseId: temporaryCourseId,
        onMaterialAdded: (material) {
          setState(() {
            _materials.add(material);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material added - will be saved when course is created'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  void _editMaterial(int index) {
    showDialog(
      context: context,
      builder: (context) => _MaterialDialog(
        courseId: 'temp_${const Uuid().v4()}',
        material: _materials[index],
        onMaterialAdded: (material) {
          setState(() {
            _materials[index] = material;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _deleteMaterial(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _materials.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Material deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      if (_classes.isEmpty) {
        throw Exception('No classes available. Please create a class first.');
      }

      final selectedClass = _classes.firstWhere(
            (c) => c.id == _selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final courseId = const Uuid().v4();
      final course = CourseModel(
        id: courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        institutionId: widget.teacher.institutionId,
        divisionId: selectedClass.divisionId,
        classId: _selectedClassId!,
        teacherId: widget.teacher.uid,
        createdAt: DateTime.now(),
      );

      // Create the course in the database
      final courseError = await databaseService.createCourse(course);
      if (courseError != null) {
        throw Exception(courseError);
      }

      // Save all materials with the actual course ID
      for (final material in _materials) {
        final materialWithCourseId = CourseMaterial(
          id: material.id,
          courseId: courseId,
          title: material.title,
          description: material.description,
          type: material.type,
          url: material.url,
          fileData: material.fileData,
          fileName: material.fileName,
          fileSize: material.fileSize,
          fileExtension: material.fileExtension,
          uploadedAt: material.uploadedAt,
        );

        final materialError = await databaseService.createCourseMaterial(materialWithCourseId);
        if (materialError != null) {
          print('Warning: Failed to save material ${material.title}: $materialError');
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course created successfully!')),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedClassId = null;
          _materials.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating course: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Course',
              style: TextStyle(
                fontSize: widget.isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Course Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Course Title',
                hintText: 'e.g., Mathematics - Algebra',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Course Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Course Description',
                hintText: 'Describe what this course covers...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a course description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Class Selection
            _buildClassSelection(),

            const SizedBox(height: 24),

            // Course Materials Section
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${_materials.length} materials',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_materials.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No materials added yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add videos, PDFs, images, or links to enrich your course',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _materials.length,
                        itemBuilder: (context, index) {
                          final material = _materials[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getMaterialColor(material.type),
                                child: Icon(
                                  _getMaterialIcon(material.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(material.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(material.type.toUpperCase()),
                                  if (material.description != null)
                                    Text(
                                      material.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editMaterial(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteMaterial(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addMaterial,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Material'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCourse,
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Creating...'),
                  ],
                )
                    : const Text('Create Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    if (_isLoadingClasses) {
      return const CircularProgressIndicator();
    }

    if (_classes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No classes available. Please contact your administrator.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'Select Class',
        prefixIcon: Icon(Icons.class_),
      ),
      items: _classes
          .map(
            (classModel) => DropdownMenuItem(
          value: classModel.id,
          child: Text(classModel.name),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a class';
        }
        return null;
      },
    );
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
}

class _MaterialDialog extends StatefulWidget {
  final String courseId;
  final CourseMaterial? material;
  final Function(CourseMaterial) onMaterialAdded;

  const _MaterialDialog({
    required this.courseId,
    this.material,
    required this.onMaterialAdded,
  });

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late String _selectedType;

  bool _isUploading = false;
  String? _fileName;
  double? _fileSize;
  String? _fileExtension;
  String? _fileData;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.material?.title ?? '');
    _descriptionController = TextEditingController(text: widget.material?.description ?? '');
    _urlController = TextEditingController(text: widget.material?.url ?? '');
    _selectedType = widget.material?.type ?? 'pdf';
    _fileName = widget.material?.fileName;
    _fileSize = widget.material?.fileSize;
    _fileExtension = widget.material?.fileExtension;
    _fileData = widget.material?.fileData;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickPDF() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;

        if (platformFile.bytes == null) {
          throw Exception('No file data available');
        }

        final fileBytes = platformFile.bytes!;
        final fileSizeInBytes = fileBytes.length;
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        // Validate file size (max 10MB)
        if (fileSizeInMB > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _isUploading = true;
        });

        // Convert file to base64
        final base64String = base64Encode(fileBytes);

        setState(() {
          _isUploading = false;
          _fileData = base64String;
          _fileName = platformFile.name;
          _fileSize = fileSizeInBytes / 1024; // Convert to KB
          _fileExtension = 'pdf';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking PDF: $e');
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      print('Image picker called');

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        print('Image selected: ${image.name}');

        final bytes = await image.readAsBytes();
        final fileSizeInBytes = bytes.length;
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        // Validate file size (max 5MB for images)
        if (fileSizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _isUploading = true;
        });

        // Convert image to base64
        final base64String = base64Encode(bytes);

        setState(() {
          _isUploading = false;
          _fileData = base64String;
          _imageBytes = bytes;
          _fileName = image.name;
          _fileSize = fileSizeInBytes / 1024; // Convert to KB
          _fileExtension = image.name.split('.').last.toLowerCase();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFile() {
    setState(() {
      _fileData = null;
      _fileName = null;
      _fileSize = null;
      _fileExtension = null;
      _imageBytes = null;
    });
  }

  void _saveMaterial() {
    if (!_formKey.currentState!.validate()) return;

    // Validate file upload for image and PDF types
    if ((_selectedType == 'pdf' || _selectedType == 'image') && _fileData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate URL for video and link types
    if ((_selectedType == 'video' || _selectedType == 'link') && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate content for note type
    if (_selectedType == 'note' && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter note content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final material = CourseMaterial(
      id: widget.material?.id ?? const Uuid().v4(),
      courseId: widget.courseId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      type: _selectedType,
      url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      fileData: _fileData,
      fileName: _fileName,
      fileSize: _fileSize,
      fileExtension: _fileExtension,
      uploadedAt: widget.material?.uploadedAt ?? DateTime.now(),
    );

    widget.onMaterialAdded(material);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Material Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Material Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'video',
                      child: Text('Video (Google Drive Link)'),
                    ),
                    DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(value: 'link', child: Text('External Link')),
                    DropdownMenuItem(value: 'note', child: Text('Text Note')),
                  ],
                  onChanged: _isUploading
                      ? null
                      : (value) {
                    setState(() {
                      _selectedType = value!;
                      _urlController.clear();
                      _clearFile();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select material type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter material title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter material description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Content based on type
                if (_selectedType == 'video') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive Video Link *',
                      hintText: 'https://drive.google.com/...',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter video link';
                      }
                      if (!value.contains('drive.google.com')) {
                        return 'Please enter a valid Google Drive link';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Make sure the Google Drive link is accessible to students',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ] else if (_selectedType == 'pdf') ...[
                  if (_isUploading) ...[
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Processing PDF file...'),
                      ],
                    ),
                  ] else if (_fileData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'PDF File',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_fileSize != null)
                                  Text(
                                    '${_fileSize!.toStringAsFixed(1)} KB',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                Text(
                                  'Ready to be saved with course',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _clearFile,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _pickPDF,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select PDF File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Max file size: 10MB',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else if (_selectedType == 'image') ...[
                  if (_isUploading) ...[
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Processing image...'),
                      ],
                    ),
                  ] else if (_fileData != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? 'Image',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (_fileSize != null)
                                  Text(
                                    '${_fileSize!.toStringAsFixed(1)} KB',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                Text(
                                  'Ready to be saved with course',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _clearFile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Preview image
                    if (_imageBytes != null)
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Select Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Max file size: 5MB',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ] else if (_selectedType == 'link') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'External Link *',
                      hintText: 'https://example.com',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter link';
                      }
                      if (!value.startsWith('http')) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                ] else if (_selectedType == 'note') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Note Content *',
                      hintText: 'Enter your text note here...',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter note content';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _saveMaterial,
          child: const Text('Save Material'),
        ),
      ],
    );
  }
}