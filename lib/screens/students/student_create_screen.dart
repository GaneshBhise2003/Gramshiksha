import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/academic_year_model.dart';
import '../../models/grade_model.dart';
import '../../models/division_model.dart';
import '../../models/student_model.dart';

class StudentCreateScreen extends StatefulWidget {
  final StudentModel? student;

  const StudentCreateScreen({super.key, this.student});

  @override
  State<StudentCreateScreen> createState() => _StudentCreateScreenState();
}

class _StudentCreateScreenState extends State<StudentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _rollNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _parentEmailController;
  late final TextEditingController _passwordController;

  bool _isLoading = false;

  // Hierarchy selection variables
  String? _selectedInstitutionId;
  String? _selectedAcademicYearId;
  String? _selectedGradeId;
  String? _selectedDivisionId;

  List<AcademicYearModel> _academicYears = [];
  List<GradeModel> _grades = [];
  List<DivisionModel> _divisions = [];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _emailController = TextEditingController(text: widget.student?.email ?? '');
    _rollNumberController = TextEditingController(
      text: widget.student?.rollNumber ?? '',
    );
    _phoneController = TextEditingController(text: widget.student?.phone ?? '');
    _parentEmailController = TextEditingController(
      text: widget.student?.parentEmail ?? '',
    );
    _passwordController = TextEditingController();

    // Initialize hierarchy selection from existing student data
    _selectedAcademicYearId = widget.student?.academicYearId;
    _selectedGradeId = widget.student?.gradeId;
    _selectedDivisionId = widget.student?.divisionId;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser == null) return;

    final userData = await authService.getUserData(currentUser.uid);
    _selectedInstitutionId = userData?.institutionId;
    if (_selectedInstitutionId == null) return;

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    // Load academic years for this institution
    final academicYears = await databaseService.getAcademicYearsByInstitution(
      _selectedInstitutionId!,
    );
    setState(() {
      _academicYears = academicYears;
    });

    // If editing existing student, load grades and divisions
    if (_selectedAcademicYearId != null) {
      await _loadGrades();
      if (_selectedGradeId != null) {
        await _loadDivisions();
      }
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedAcademicYearId == null || _selectedInstitutionId == null)
      return;

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final grades = await databaseService.getGradesByInstitutionAndAcademicYear(
      _selectedInstitutionId!,
      _selectedAcademicYearId!,
    );
    setState(() {
      _grades = grades;
    });
  }

  Future<void> _loadDivisions() async {
    if (_selectedGradeId == null ||
        _selectedAcademicYearId == null ||
        _selectedInstitutionId == null)
      return;

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final divisions = await databaseService
        .getDivisionsByInstitutionAndAcademicYearAndGrade(
          _selectedInstitutionId!,
          _selectedAcademicYearId!,
          _selectedGradeId!,
        );
    setState(() {
      _divisions = divisions;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    _phoneController.dispose();
    _parentEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDivisionId == null ||
        _selectedAcademicYearId == null ||
        _selectedGradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select academic year, grade, and division'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    try {
      if (widget.student == null) {
        // Get current user data to retrieve institutionId
        final currentUser = authService.currentUser;
        if (currentUser == null) throw Exception('Not authenticated');

        final userData = await authService.getUserData(currentUser.uid);
        if (userData == null) throw Exception('User data not found');

        // Creating new student with hierarchy data
        final result = await authService.createStudentAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          rollNumber: _rollNumberController.text.trim(),
          institutionId: userData.institutionId ?? _selectedInstitutionId!,
          academicYearId: _selectedAcademicYearId!,
          gradeId: _selectedGradeId!,
          divisionId: _selectedDivisionId!,
          phone:
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
          parentEmail:
              _parentEmailController.text.trim().isEmpty
                  ? null
                  : _parentEmailController.text.trim(),
        );

        if (result['success']) {
          // Add student to class
          // Student is now assigned to division, not directly to classes

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student created successfully!'),
                    Text('Email: ${result['email']}'),
                    Text('Password: ${result['password']}'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Updating existing student
        final updatedStudent = widget.student!.copyWith(
          name: _nameController.text.trim(),
          rollNumber: _rollNumberController.text.trim(),
          phone:
              _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
          parentEmail:
              _parentEmailController.text.trim().isEmpty
                  ? null
                  : _parentEmailController.text.trim(),
          academicYearId: _selectedAcademicYearId!,
          gradeId: _selectedGradeId!,
          divisionId: _selectedDivisionId!,
        );

        final error = await databaseService.updateStudent(updatedStudent);

        if (mounted) {
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Student updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add New Student'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveStudent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter student name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (readonly for editing)
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        readOnly: isEditing,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Academic Year Selection
                      DropdownButtonFormField<String>(
                        value: _selectedAcademicYearId,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        items:
                            _academicYears.map((academicYear) {
                              return DropdownMenuItem<String>(
                                value: academicYear.id,
                                child: Text(academicYear.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAcademicYearId = value;
                            _selectedGradeId = null;
                            _selectedDivisionId = null;
                            _grades.clear();
                            _divisions.clear();
                          });
                          if (value != null) {
                            _loadGrades();
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an academic year';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Grade Selection
                      DropdownButtonFormField<String>(
                        value: _selectedGradeId,
                        decoration: const InputDecoration(
                          labelText: 'Grade *',
                          prefixIcon: Icon(Icons.school),
                        ),
                        items:
                            _grades.map((grade) {
                              return DropdownMenuItem<String>(
                                value: grade.id,
                                child: Text(grade.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGradeId = value;
                            _selectedDivisionId = null;
                            _divisions.clear();
                          });
                          if (value != null &&
                              _selectedAcademicYearId != null) {
                            _loadDivisions();
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a grade';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Roll Number
                          Expanded(
                            child: TextFormField(
                              controller: _rollNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Roll Number *',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter roll number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Division Selection
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedDivisionId,
                              decoration: const InputDecoration(
                                labelText: 'Division *',
                                prefixIcon: Icon(Icons.group),
                              ),
                              items:
                                  _divisions.map((division) {
                                    return DropdownMenuItem<String>(
                                      value: division.id,
                                      child: Text(division.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDivisionId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a division';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      if (!isEditing) ...[
                        const SizedBox(height: 16),
                        // Password (only for new students)
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Initial Password *',
                            prefixIcon: Icon(Icons.lock),
                            helperText:
                                'Student can change this after first login',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Parent Email
                      TextFormField(
                        controller: _parentEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Parent Email (Optional)',
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          isEditing ? 'Update Student' : 'Create Student',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
