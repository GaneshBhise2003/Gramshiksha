import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../utils/responsive_helper.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassId;
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
        title: const Text('Student Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Students', icon: Icon(Icons.people)),
            Tab(text: 'Add Student', icon: Icon(Icons.person_add)),
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
              _buildStudentsTab(teacher, databaseService, isTablet),
              _buildAddStudentTab(teacher, databaseService, isTablet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentsTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Class and Search Selection
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              // Class Selection
              StreamBuilder<List<ClassModel>>(
                stream: databaseService.getTeacherClasses(teacher.uid),
                builder: (context, classSnapshot) {
                  if (!classSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final classes = classSnapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
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
              const SizedBox(height: 16),
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search students...',
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
        // Students List
        Expanded(
          child: StreamBuilder<List<StudentModel>>(
            stream:
                _selectedClassId != null
                    ? databaseService.getClassStudents(_selectedClassId!)
                    : databaseService.getAllStudents(),
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
                        Icons.people_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedClassId != null
                            ? 'No students in this class'
                            : 'No students registered yet',
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

              var students = snapshot.data!;

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                students =
                    students.where((student) {
                      return student.name.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          student.email.toLowerCase().contains(_searchQuery) ||
                          student.rollNumber.toLowerCase().contains(
                            _searchQuery,
                          );
                    }).toList();
              }

              if (students.isEmpty) {
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
                        'No students found',
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
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return _buildStudentCard(
                      student,
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

  Widget _buildStudentCard(
    StudentModel student,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showStudentDetails(student, databaseService),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 30 : 25,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll No: ${student.rollNumber}',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.email,
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
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attendance',
                        child: ListTile(
                          leading: Icon(Icons.how_to_reg),
                          title: Text('Attendance'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'grades',
                        child: ListTile(
                          leading: Icon(Icons.grade),
                          title: Text('Grades'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showStudentDetails(student, databaseService);
                      break;
                    case 'attendance':
                      _viewStudentAttendance(student, databaseService);
                      break;
                    case 'grades':
                      _viewStudentGrades(student, databaseService);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStudentTab(
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
              Icons.person_add,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Student',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Student registration and management features coming soon!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add student feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(
    StudentModel student,
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
                    title: Text(student.name),
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
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(student.email),
                          const SizedBox(height: 16),
                          Text(
                            'Roll Number',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(student.rollNumber),
                          const SizedBox(height: 16),
                          Text(
                            'Phone',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (student.phone?.isNotEmpty ?? false)
                                ? student.phone!
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Address',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (student.address?.isNotEmpty ?? false)
                                ? student.address!
                                : 'Not provided',
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

  void _viewStudentAttendance(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student attendance view coming soon!')),
    );
  }

  void _viewStudentGrades(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student grades view coming soon!')),
    );
  }
}
