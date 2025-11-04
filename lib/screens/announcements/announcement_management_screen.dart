import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart'; // Not needed for current implementation
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/announcement_model.dart';
import '../../models/class_model.dart';
import '../../utils/responsive_helper.dart';

class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  State<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends State<AnnouncementManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Announcements', icon: Icon(Icons.campaign)),
            Tab(text: 'Create', icon: Icon(Icons.add)),
          ],
        ),
      ),
      body: FutureBuilder<TeacherModel?>(
        future: databaseService.getTeacher(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Teacher data not found'));
          }

          final teacher = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAnnouncementsTab(teacher, databaseService, isTablet),
              _buildCreateAnnouncementTab(teacher, databaseService, isTablet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementsTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
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
                  hintText: 'Search announcements...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
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
            ],
          ),
        ),
        // Announcements List
        Expanded(
          child: StreamBuilder<List<AnnouncementModel>>(
            stream: databaseService.getAnnouncementsForTeacher(teacher.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No announcements found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first announcement to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              var announcements = snapshot.data!;

              if (_searchQuery.isNotEmpty) {
                announcements =
                    announcements.where((announcement) {
                      return announcement.title.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          announcement.content.toLowerCase().contains(
                            _searchQuery,
                          );
                    }).toList();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    return _buildAnnouncementCard(
                      announcement,
                      databaseService,
                      isTablet,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(
    AnnouncementModel announcement,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(announcement),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: TextStyle(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (!announcement.isPublished)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'DRAFT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
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
                          _editAnnouncement(announcement);
                          break;
                        case 'delete':
                          _deleteAnnouncement(announcement);
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
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(announcement.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Classes: ${announcement.classIds.isEmpty ? "All" : announcement.classIds.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildCreateAnnouncementTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return _CreateAnnouncementForm(
      teacher: teacher,
      databaseService: databaseService,
      isTablet: isTablet,
    );
  }

  void _showAnnouncementDetails(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: ResponsiveHelper.isDesktop(context) ? 600 : null,
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(announcement.title),
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
                            'Content',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(announcement.content),
                          const SizedBox(height: 20),
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            announcement.isPublished ? 'Published' : 'Draft',
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Created',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy hh:mm a',
                            ).format(announcement.createdAt),
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

  void _editAnnouncement(AnnouncementModel announcement) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit announcement feature coming soon!')),
    );
  }

  void _deleteAnnouncement(AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Announcement'),
            content: Text(
              'Are you sure you want to delete "${announcement.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete announcement feature coming soon!'),
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
}

class _CreateAnnouncementForm extends StatefulWidget {
  final TeacherModel teacher;
  final DatabaseService databaseService;
  final bool isTablet;

  const _CreateAnnouncementForm({
    required this.teacher,
    required this.databaseService,
    required this.isTablet,
  });

  @override
  State<_CreateAnnouncementForm> createState() =>
      __CreateAnnouncementFormState();
}

class __CreateAnnouncementFormState extends State<_CreateAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _selectedClassIds = [];
  bool _isPublished = true;
  // DateTime? _scheduledFor; // For future scheduled announcements feature
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Announcement',
              style: TextStyle(
                fontSize: widget.isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Announcement Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Announcement Title',
                hintText: 'e.g., Important: Class Schedule Update',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an announcement title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Announcement Content
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Announcement Content',
                hintText: 'Write your announcement here...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter announcement content';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Class Selection
            StreamBuilder<List<ClassModel>>(
              stream: widget.databaseService.getTeacherClasses(
                widget.teacher.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No classes available. This announcement will be sent to all students.',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }

                final classes = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Classes (optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Leave empty to send to all classes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...classes.map(
                      (classModel) => CheckboxListTile(
                        title: Text(classModel.name),
                        value: _selectedClassIds.contains(classModel.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedClassIds.add(classModel.id);
                            } else {
                              _selectedClassIds.remove(classModel.id);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Publish Options
            SwitchListTile(
              title: const Text('Publish Immediately'),
              subtitle: const Text('Turn off to save as draft'),
              value: _isPublished,
              onChanged: (value) {
                setState(() {
                  _isPublished = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAnnouncement,
                child:
                    _isLoading
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
                        : Text(
                          _isPublished
                              ? 'Publish Announcement'
                              : 'Save as Draft',
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected class to retrieve its division ID
      String? divisionId;
      if (_selectedClassIds.isNotEmpty) {
        final classes =
            await widget.databaseService
                .getTeacherClasses(widget.teacher.uid)
                .first;

        if (classes.isNotEmpty) {
          final selectedClass = classes.firstWhere(
            (c) => c.id == _selectedClassIds.first,
            orElse: () => throw Exception('Selected class not found'),
          );
          divisionId = selectedClass.divisionId;
        }
      }

      final result = await widget.databaseService.createAnnouncement(
        teacherId: widget.teacher.uid,
        title: _titleController.text.trim(),
        description: _contentController.text.trim(),
        // classId: _selectedClassIds.isNotEmpty ? _selectedClassIds.first : '',
        institutionId: widget.teacher.institutionId,
        divisionId: divisionId ?? '',
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isPublished
                    ? 'Announcement published successfully!'
                    : 'Announcement saved as draft!',
              ),
            ),
          );

          // Clear form
          _titleController.clear();
          _contentController.clear();
          setState(() {
            _selectedClassIds.clear();
            _isPublished = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating announcement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
