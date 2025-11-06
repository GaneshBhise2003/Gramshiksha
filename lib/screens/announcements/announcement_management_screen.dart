import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    _searchController.dispose();
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
        _AnnouncementsListTab(
          teacher: _cachedTeacher!,
          searchQuery: _searchQuery,
          searchController: _searchController,
          onSearchChanged: (query) => setState(() => _searchQuery = query),
        ),
        _CreateAnnouncementTab(
          teacher: _cachedTeacher!,
          isTablet: isTablet,
        ),
      ],
    );
  }
}

class _AnnouncementsListTab extends StatefulWidget {
  final TeacherModel teacher;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _AnnouncementsListTab({
    required this.teacher,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<_AnnouncementsListTab> createState() => _AnnouncementsListTabState();
}

class _AnnouncementsListTabState extends State<_AnnouncementsListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: TextField(
            controller: widget.searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search announcements...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.searchController.clear();
                  widget.onSearchChanged('');
                },
              )
                  : null,
            ),
          ),
        ),
        // Announcements List
        Expanded(
          child: _AnnouncementsList(
            teacher: widget.teacher,
            searchQuery: widget.searchQuery,
          ),
        ),
      ],
    );
  }
}

class _AnnouncementsList extends StatefulWidget {
  final TeacherModel teacher;
  final String searchQuery;

  const _AnnouncementsList({
    required this.teacher,
    required this.searchQuery,
  });

  @override
  State<_AnnouncementsList> createState() => _AnnouncementsListState();
}

class _AnnouncementsListState extends State<_AnnouncementsList> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final announcements = await databaseService.getAnnouncementsForTeacher(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _announcements = announcements;
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

    var announcements = _announcements;
    if (widget.searchQuery.isNotEmpty) {
      announcements = announcements.where((announcement) {
        return announcement.title.toLowerCase().contains(widget.searchQuery) ||
            announcement.content.toLowerCase().contains(widget.searchQuery);
      }).toList();
    }

    if (announcements.isEmpty) {
      return _EmptyAnnouncementsState(searchQuery: widget.searchQuery);
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 20 : 16),
        itemCount: announcements.length,
        itemBuilder: (context, index) => _AnnouncementCard(
          announcement: announcements[index],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showAnnouncementDetails(context, announcement),
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
                                  color: Theme.of(context).colorScheme.onSurface,
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
                          _editAnnouncement(context);
                          break;
                        case 'delete':
                          _deleteAnnouncement(context, announcement);
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  void _showAnnouncementDetails(BuildContext context, AnnouncementModel announcement) {
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
                      Text(announcement.isPublished ? 'Published' : 'Draft'),
                      const SizedBox(height: 20),
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(announcement.createdAt),
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

  void _editAnnouncement(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit announcement feature coming soon!')),
    );
  }

  void _deleteAnnouncement(BuildContext context, AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "${announcement.title}"?'),
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

class _EmptyAnnouncementsState extends StatelessWidget {
  final String searchQuery;

  const _EmptyAnnouncementsState({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'No announcements found' : 'No matching announcements',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Create your first announcement to get started'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAnnouncementTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateAnnouncementTab({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateAnnouncementTab> createState() => _CreateAnnouncementTabState();
}

class _CreateAnnouncementTabState extends State<_CreateAnnouncementTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _CreateAnnouncementForm(
      teacher: widget.teacher,
      isTablet: widget.isTablet,
    );
  }
}

class _CreateAnnouncementForm extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateAnnouncementForm({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateAnnouncementForm> createState() => _CreateAnnouncementFormState();
}

class _CreateAnnouncementFormState extends State<_CreateAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<String> _selectedClassIds = [];
  bool _isPublished = true;
  bool _isLoading = false;
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
    _contentController.dispose();
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
            _buildClassSelection(),

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
                    : Text(
                  _isPublished ? 'Publish Announcement' : 'Save as Draft',
                ),
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
            'No classes available. This announcement will be sent to all students.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        ..._classes.map(
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
  }

  Future<void> _createAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      String? divisionId;
      if (_selectedClassIds.isNotEmpty) {
        final selectedClass = _classes.firstWhere(
              (c) => c.id == _selectedClassIds.first,
          orElse: () => throw Exception('Selected class not found'),
        );
        divisionId = selectedClass.divisionId;
      }

      final result = await databaseService.createAnnouncement(
        teacherId: widget.teacher.uid,
        title: _titleController.text.trim(),
        description: _contentController.text.trim(),
        institutionId: widget.teacher.institutionId,
        divisionId: divisionId ?? '',
      );

      if (mounted) {
        if (result == null) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
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
        setState(() => _isLoading = false);
      }
    }
  }
}