import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/division_model.dart';

import '../../models/academic_year_model.dart';
import '../../models/grade_model.dart';

class ManageStudentsScreen extends StatefulWidget {
  final String institutionId;

  const ManageStudentsScreen({super.key, required this.institutionId});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  List<AcademicYearModel> _academicYears = [];
  List<GradeModel> _grades = [];
  List<DivisionModel> _divisions = [];

  bool _isLoading = true;

  // Hierarchy filter variables
  String? _selectedAcademicYearId;
  String? _selectedGradeId;
  String? _selectedDivisionId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final students = await databaseService.getStudentsByInstitution(
        widget.institutionId,
      );
      final academicYears = await databaseService.getAcademicYearsByInstitution(
        widget.institutionId,
      );
      final divisions = await databaseService.getDivisionsByInstitutionFuture(
        widget.institutionId,
      );

      setState(() {
        _students = students;
        _academicYears = academicYears;
        _divisions = divisions;
        _filteredStudents = students; // Initialize filtered list
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
      _filterStudents();
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedAcademicYearId == null) return;

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final grades = await databaseService
          .getGradesByInstitutionAndAcademicYear(
            widget.institutionId,
            _selectedAcademicYearId!,
          );
      setState(() {
        _grades = grades;
        _selectedGradeId = null;
        _selectedDivisionId = null;
        _divisions.clear();
      });
      _filterStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading grades: $e')));
      }
    }
  }

  Future<void> _loadDivisions() async {
    if (_selectedGradeId == null || _selectedAcademicYearId == null) return;

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final divisions = await databaseService
          .getDivisionsByInstitutionAndAcademicYearAndGrade(
            widget.institutionId,
            _selectedAcademicYearId!,
            _selectedGradeId!,
          );
      setState(() {
        _divisions = divisions;
        _selectedDivisionId = null;
      });
      _filterStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading divisions: $e')));
      }
    }
  }

  void _filterStudents() {
    List<StudentModel> filtered = _students;

    if (_selectedAcademicYearId != null) {
      filtered =
          filtered
              .where(
                (student) => student.academicYearId == _selectedAcademicYearId,
              )
              .toList();
    }
    if (_selectedGradeId != null) {
      filtered =
          filtered
              .where((student) => student.gradeId == _selectedGradeId)
              .toList();
    }
    if (_selectedDivisionId != null) {
      filtered =
          filtered
              .where((student) => student.divisionId == _selectedDivisionId)
              .toList();
    }

    setState(() {
      _filteredStudents = filtered;
    });
  }

  Future<void> _showCreateStudentDialog([StudentModel? student]) async {
    final nameController = TextEditingController(text: student?.name ?? '');
    final emailController = TextEditingController(text: student?.email ?? '');
    final rollNumberController = TextEditingController(
      text: student?.rollNumber ?? '',
    );
    final phoneController = TextEditingController(text: student?.phone ?? '');
    final parentEmailController = TextEditingController(
      text: student?.parentEmail ?? '',
    );
    final passwordController = TextEditingController();

    // Hierarchy selection variables for dialog
    String? dialogAcademicYearId = student?.academicYearId;
    String? dialogGradeId = student?.gradeId;
    String? dialogDivisionId = student?.divisionId;
    List<GradeModel> dialogGrades = [];
    List<DivisionModel> dialogDivisions = [];

    // Load initial data if editing existing student
    if (student != null && dialogAcademicYearId != null) {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      dialogGrades = await databaseService
          .getGradesByInstitutionAndAcademicYear(
            widget.institutionId,
            dialogAcademicYearId,
          );
      if (dialogGradeId != null) {
        dialogDivisions = await databaseService
            .getDivisionsByInstitutionAndAcademicYearAndGrade(
              widget.institutionId,
              dialogAcademicYearId,
              dialogGradeId,
            );
      }
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(student == null ? 'Create Student' : 'Edit Student'),
            content: StatefulBuilder(
              builder:
                  (context, setDialogState) => SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter student name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'student@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled:
                              student ==
                              null, // Don't allow email change for existing students
                        ),
                        if (student == null) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              hintText: 'Minimum 6 characters',
                            ),
                            obscureText: true,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: rollNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Roll Number',
                            hintText: 'e.g., 2024001',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone (Optional)',
                            hintText: '+1234567890',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: parentEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Parent Email (Optional)',
                            hintText: 'parent@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Academic Year Selection
                        DropdownButtonFormField<String>(
                          value: dialogAcademicYearId,
                          decoration: const InputDecoration(
                            labelText: 'Academic Year',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Academic Year'),
                          items:
                              _academicYears.map((academicYear) {
                                return DropdownMenuItem(
                                  value: academicYear.id,
                                  child: Text(academicYear.name),
                                );
                              }).toList(),
                          onChanged: (value) async {
                            setDialogState(() {
                              dialogAcademicYearId = value;
                              dialogGradeId = null;
                              dialogDivisionId = null;
                              dialogGrades.clear();
                              dialogDivisions.clear();
                            });

                            if (value != null) {
                              final databaseService =
                                  Provider.of<DatabaseService>(
                                    context,
                                    listen: false,
                                  );
                              final grades = await databaseService
                                  .getGradesByInstitutionAndAcademicYear(
                                    widget.institutionId,
                                    value,
                                  );
                              setDialogState(() {
                                dialogGrades = grades;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an academic year';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Grade Selection
                        DropdownButtonFormField<String>(
                          value: dialogGradeId,
                          decoration: const InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Class'),
                          items:
                              dialogGrades.map((grade) {
                                return DropdownMenuItem(
                                  value: grade.id,
                                  child: Text(grade.name),
                                );
                              }).toList(),
                          onChanged: (value) async {
                            setDialogState(() {
                              dialogGradeId = value;
                              dialogDivisionId = null;
                              dialogDivisions.clear();
                            });

                            if (value != null && dialogAcademicYearId != null) {
                              final databaseService =
                                  Provider.of<DatabaseService>(
                                    context,
                                    listen: false,
                                  );
                              final divisions = await databaseService
                                  .getDivisionsByInstitutionAndAcademicYearAndGrade(
                                    widget.institutionId,
                                    dialogAcademicYearId!,
                                    value,
                                  );
                              setDialogState(() {
                                dialogDivisions = divisions;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a grade';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Division Selection
                        DropdownButtonFormField<String>(
                          value: dialogDivisionId,
                          decoration: const InputDecoration(
                            labelText: 'Division (Class Section)',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text(
                            'Select Division (e.g., 10th A, 12th B)',
                          ),
                          items:
                              dialogDivisions.map((division) {
                                return DropdownMenuItem(
                                  value: division.id,
                                  child: Text(division.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              dialogDivisionId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a division';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  // Validation
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please select academic year, grade, and division',
                        ),
                      ),
                    );
                    return;
                  }

                  if (emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter email')),
                    );
                    return;
                  }

                  if (student == null && passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                      ),
                    );
                    return;
                  }

                  if (rollNumberController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter roll number')),
                    );
                    return;
                  }

                  if (dialogDivisionId == null ||
                      dialogAcademicYearId == null ||
                      dialogGradeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a division')),
                    );
                    return;
                  }

                  try {
                    final authService = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final databaseService = Provider.of<DatabaseService>(
                      context,
                      listen: false,
                    );

                    if (student == null) {
                      // Create new student
                      final result = await authService.createStudentAccount(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        name: nameController.text.trim(),
                        rollNumber: rollNumberController.text.trim(),
                        institutionId: widget.institutionId,
                        academicYearId: dialogAcademicYearId!,
                        gradeId: dialogGradeId!,
                        divisionId: dialogDivisionId!,
                        phone:
                            phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                        parentEmail:
                            parentEmailController.text.trim().isEmpty
                                ? null
                                : parentEmailController.text.trim(),
                      );

                      if (!result['success']) {
                        throw Exception(result['error']);
                      }
                    } else {
                      // Update existing student
                      final updatedStudent = student.copyWith(
                        name: nameController.text.trim(),
                        rollNumber: rollNumberController.text.trim(),
                        academicYearId: dialogAcademicYearId!,
                        gradeId: dialogGradeId!,
                        divisionId: dialogDivisionId!,
                        phone:
                            phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                        parentEmail:
                            parentEmailController.text.trim().isEmpty
                                ? null
                                : parentEmailController.text.trim(),
                      );

                      await databaseService.updateStudent(updatedStudent);
                    }

                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          student == null
                              ? 'Student created successfully!'
                              : 'Student updated successfully!',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(student == null ? 'Create' : 'Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteStudent(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Student'),
            content: Text('Are you sure you want to delete "${student.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final databaseService = Provider.of<DatabaseService>(
          context,
          listen: false,
        );
        await databaseService.deleteStudent(student.uid);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting student: $e')));
        }
      }
    }
  }

  String _getDivisionName(String divisionId) {
    final division = _divisions.firstWhere(
      (div) => div.id == divisionId,
      orElse:
          () => DivisionModel(
            id: '',
            name: 'Unknown Division',
            institutionId: '',
            gradeId: '',
            academicYearId: '',
            createdAt: DateTime.now(),
          ),
    );
    return division.name;
  }

  Widget _buildSelectionPanel() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Students by Hierarchy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Academic Year Selection
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Academic Year:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAcademicYearId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText:
                          _academicYears.isEmpty
                              ? 'No academic years available'
                              : 'All academic years',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Academic Years'),
                      ),
                      ..._academicYears.map((academicYear) {
                        return DropdownMenuItem(
                          value: academicYear.id,
                          child: Text(academicYear.name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAcademicYearId = value;
                        _selectedGradeId = null;
                        _selectedDivisionId = null;
                        _grades.clear();
                        _divisions.clear();
                      });
                      if (value != null) _loadGrades();
                      _filterStudents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grade Selection
            Row(
              children: [
                Icon(Icons.grade, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Class:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGradeId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText:
                          _grades.isEmpty
                              ? 'Select academic year first'
                              : 'All classes',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All classes'),
                      ),
                      ..._grades.map((grade) {
                        return DropdownMenuItem(
                          value: grade.id,
                          child: Text(grade.name),
                        );
                      }).toList(),
                    ],
                    onChanged:
                        _grades.isEmpty
                            ? null
                            : (value) {
                              setState(() {
                                _selectedGradeId = value;
                                _selectedDivisionId = null;
                                _divisions.clear();
                              });
                              if (value != null) _loadDivisions();
                              _filterStudents();
                            },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Division Selection
            Row(
              children: [
                Icon(
                  Icons.class_,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Division:'),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDivisionId,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText:
                          _divisions.isEmpty
                              ? 'Select grade first'
                              : 'All divisions',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Divisions'),
                      ),
                      ..._divisions.map((division) {
                        return DropdownMenuItem(
                          value: division.id,
                          child: Text(division.name),
                        );
                      }).toList(),
                    ],
                    onChanged:
                        _divisions.isEmpty
                            ? null
                            : (value) {
                              setState(() {
                                _selectedDivisionId = value;
                              });
                              _filterStudents();
                            },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: () => _showCreateStudentDialog(),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No students found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create student accounts for your institution',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showCreateStudentDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Student'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  _buildSelectionPanel(),
                  Expanded(
                    child:
                        _filteredStudents.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No students match the selected filters',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Try changing the filter criteria or create a new student',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => _showCreateStudentDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Student'),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        student.name.isNotEmpty
                                            ? student.name[0].toUpperCase()
                                            : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(student.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(student.email),
                                        Text('Roll: ${student.rollNumber}'),
                                        Text(
                                          'Division: ${_getDivisionName(student.divisionId)}',
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed:
                                              () => _showCreateStudentDialog(
                                                student,
                                              ),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          onPressed:
                                              () => _deleteStudent(student),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStudentDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (shouldLogout == true && mounted) {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
        }
      }
    }
  }
}
