import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import 'student_create_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view students')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Filter
          StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(currentUser.uid),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final classes = classSnapshot.data ?? [];

              if (classes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.class_, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No classes found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a class first to add students',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ...classes
                            .map(
                              (classModel) => DropdownMenuItem<String>(
                                value: classModel.id,
                                child: Text(
                                  '${classModel.name} - ${classModel.subject}',
                                ),
                              ),
                            )
                            .toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // Students List
          Expanded(
            child:
                _selectedClassId != null
                    ? _buildClassStudents(_selectedClassId!, databaseService)
                    : _buildAllStudents(currentUser.uid, databaseService),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createStudent(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildClassStudents(String classId, DatabaseService databaseService) {
    return StreamBuilder<List<StudentModel>>(
      stream: databaseService.getClassStudents(classId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final students = snapshot.data ?? [];
        return _buildStudentsList(students);
      },
    );
  }

  Widget _buildAllStudents(String teacherId, DatabaseService databaseService) {
    return FutureBuilder<List<StudentModel>>(
      future: databaseService.getStudentsByTeacher(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final students = snapshot.data ?? [];
        return _buildStudentsList(students);
      },
    );
  }

  Widget _buildStudentsList(List<StudentModel> students) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add students to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createStudent(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  student.isFirstLogin ? Colors.orange[100] : Colors.green[100],
              child: Text(
                student.name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      student.isFirstLogin
                          ? Colors.orange[800]
                          : Colors.green[800],
                ),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Roll No: ${student.rollNumber}'),
                Text(student.email),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder:
                  (context) => [
                    if (_selectedClassId == null) ...[
                      const PopupMenuItem(
                        value: 'add_to_class',
                        child: ListTile(
                          leading: Icon(Icons.add_box, color: Colors.green),
                          title: Text(
                            'Add to Class',
                            style: TextStyle(color: Colors.green),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Profile'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: ListTile(
                        leading: Icon(Icons.lock_reset),
                        title: Text('Reset Password'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_selectedClassId != null) ...[
                      const PopupMenuItem(
                        value: 'remove_from_class',
                        child: ListTile(
                          leading: Icon(
                            Icons.remove_circle,
                            color: Colors.orange,
                          ),
                          title: Text(
                            'Remove from Class',
                            style: TextStyle(color: Colors.orange),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
              onSelected: (value) => _handleStudentAction(value, student),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _createStudent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentCreateScreen()),
    );
  }

  void _handleStudentAction(String action, StudentModel student) {
    switch (action) {
      case 'add_to_class':
        _addStudentToClass(student);
        break;
      case 'remove_from_class':
        _removeStudentFromClass(student);
        break;
      case 'view':
        // TODO: Navigate to student profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile view coming soon')),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentCreateScreen(student: student),
          ),
        );
        break;
      case 'reset_password':
        _resetPassword(student);
        break;
      case 'delete':
        _deleteStudent(student);
        break;
    }
  }

  void _resetPassword(StudentModel student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Password'),
            content: Text('Reset password for "${student.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement password reset
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset functionality coming soon'),
                    ),
                  );
                },
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  void _deleteStudent(StudentModel student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Student'),
            content: Text(
              'Are you sure you want to delete "${student.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement student deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Student deletion functionality coming soon',
                      ),
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

  void _addStudentToClass(StudentModel student) {
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    // Get teacher's classes for selection
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add ${student.name} to Class'),
            content: StreamBuilder<List<ClassModel>>(
              stream: databaseService.getTeacherClasses(
                authService.currentUser!.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final classes = snapshot.data ?? [];
                if (classes.isEmpty) {
                  return const Text(
                    'No classes available. Create a class first.',
                  );
                }

                return SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classModel = classes[index];
                      final isAlreadyInClass = classModel.studentIds.contains(
                        student.uid,
                      );

                      return ListTile(
                        title: Text(
                          '${classModel.name} - ${classModel.subject}',
                        ),
                        subtitle: Text('Section: ${classModel.section}'),
                        trailing:
                            isAlreadyInClass
                                ? const Icon(Icons.check, color: Colors.green)
                                : const Icon(Icons.add),
                        enabled: !isAlreadyInClass,
                        onTap:
                            isAlreadyInClass
                                ? null
                                : () async {
                                  Navigator.pop(context);

                                  final error = await databaseService
                                      .addStudentToClass(
                                        classModel.id,
                                        student.uid,
                                      );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error ??
                                              'Student added to ${classModel.name} successfully!',
                                        ),
                                        backgroundColor:
                                            error != null
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    );
                                  }
                                },
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _removeStudentFromClass(StudentModel student) {
    if (_selectedClassId == null) return;

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove from Class'),
            content: Text('Remove ${student.name} from this class?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final error = await databaseService.removeStudentFromClass(
                    _selectedClassId!,
                    student.uid,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error ?? 'Student removed from class successfully!',
                        ),
                        backgroundColor:
                            error != null ? Colors.red : Colors.green,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
    );
  }
}
