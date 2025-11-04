import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/class_model.dart';
import '../../utils/responsive_helper.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen>
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
        title: const Text('Class Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Classes', icon: Icon(Icons.class_)),
            Tab(text: 'Create Class', icon: Icon(Icons.add)),
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
              _buildMyClassesTab(teacher, databaseService, isTablet),
              _buildCreateClassTab(teacher, databaseService, isTablet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMyClassesTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search classes...',
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
        ),
        // Classes List
        Expanded(
          child: StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(teacher.uid),
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
                        Icons.class_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first class to get started',
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

              var classes = snapshot.data!;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                classes =
                    classes.where((classModel) {
                      return classModel.name.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          classModel.subject.toLowerCase().contains(
                            _searchQuery,
                          );
                    }).toList();
              }

              if (classes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classModel = classes[index];
                    return _buildClassCard(
                      classModel,
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

  Widget _buildClassCard(
    ClassModel classModel,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showClassDetails(classModel, databaseService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        classModel.name.isNotEmpty
                            ? classModel.name[0].toUpperCase()
                            : 'C',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classModel.name,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          classModel.subject,
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
                            value: 'students',
                            child: ListTile(
                              leading: Icon(Icons.people),
                              title: Text('View Students'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit Class'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Delete Class'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'students':
                          _viewClassStudents(classModel, databaseService);
                          break;
                        case 'edit':
                          _editClass(classModel, databaseService);
                          break;
                        case 'delete':
                          _deleteClass(classModel, databaseService);
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
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    classModel.schedule ?? 'No schedule',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  FutureBuilder<int>(
                    future: databaseService.getClassStudentCount(classModel.id),
                    builder: (context, countSnapshot) {
                      return Text(
                        '${countSnapshot.data ?? 0} students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateClassTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Create New Class',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Class creation feature coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Class creation feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Class'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDetails(
    ClassModel classModel,
    DatabaseService databaseService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: ResponsiveHelper.isDesktop(context) ? 500 : null,
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(classModel.name),
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
                            'Subject',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(classModel.subject),
                          const SizedBox(height: 16),
                          Text(
                            'Schedule',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(classModel.schedule ?? 'No schedule'),
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (classModel.description?.isNotEmpty ?? false)
                                ? classModel.description!
                                : 'No description provided',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Created',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(classModel.createdAt),
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

  void _viewClassStudents(
    ClassModel classModel,
    DatabaseService databaseService,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View students feature coming soon!')),
    );
  }

  void _editClass(ClassModel classModel, DatabaseService databaseService) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit class feature coming soon!')),
    );
  }

  void _deleteClass(ClassModel classModel, DatabaseService databaseService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Class'),
            content: Text(
              'Are you sure you want to delete "${classModel.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete class feature coming soon!'),
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
