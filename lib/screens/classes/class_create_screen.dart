import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/class_model.dart';

class ClassCreateScreen extends StatefulWidget {
  final ClassModel? classModel;

  const ClassCreateScreen({super.key, this.classModel});

  @override
  State<ClassCreateScreen> createState() => _ClassCreateScreenState();
}

class _ClassCreateScreenState extends State<ClassCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _sectionController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  late String _classCode;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.classModel?.name ?? '',
    );
    _subjectController = TextEditingController(
      text: widget.classModel?.subject ?? '',
    );
    _sectionController = TextEditingController(
      text: widget.classModel?.section ?? '',
    );
    _academicYearController = TextEditingController(
      text: widget.classModel?.academicYear ?? '',
    );
    _scheduleController = TextEditingController(
      text: widget.classModel?.schedule ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.classModel?.description ?? '',
    );

    _classCode = widget.classModel?.classCode ?? _generateClassCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _sectionController.dispose();
    _academicYearController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      6,
      (index) => chars[(DateTime.now().millisecond + index) % chars.length],
    ).join();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get teacher data to access institutionId
      final teacherData = await authService.getTeacherData(currentUser.uid);
      if (teacherData == null) {
        throw Exception('Teacher data not found');
      }

      // For now, use the first division or allow teacher to select
      // You may want to add a division selector in the UI
      final divisions =
          await databaseService
              .getDivisionsByInstitution(teacherData.institutionId)
              .first;
      if (divisions.isEmpty) {
        throw Exception('No divisions found. Please create a division first.');
      }

      final classModel = ClassModel(
        id: widget.classModel?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        institutionId: teacherData.institutionId,
        divisionId: widget.classModel?.divisionId ?? divisions.first.id,
        gradeId: 'default-grade', // Default grade
        academicYearId: _academicYearController.text.trim(),
        classCode: _classCode,
        teacherId: currentUser.uid,
        studentIds: widget.classModel?.studentIds ?? [],
        coTeacherIds: widget.classModel?.coTeacherIds ?? [],
        schedule:
            _scheduleController.text.trim().isEmpty
                ? null
                : _scheduleController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        createdAt: widget.classModel?.createdAt ?? DateTime.now(),
        isActive: widget.classModel?.isActive ?? true,
      );

      final error =
          widget.classModel == null
              ? await databaseService.createClass(classModel)
              : await databaseService.updateClass(classModel);

      setState(() => _isLoading = false);

      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.classModel == null
                    ? 'Class created successfully!'
                    : 'Class updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classModel != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class' : 'Create New Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveClass,
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
                        'Class Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Class Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Class Name *',
                          prefixIcon: Icon(Icons.class_),
                          hintText: 'e.g., Grade 10A',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter class name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject *',
                          prefixIcon: Icon(Icons.book),
                          hintText: 'e.g., Mathematics',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          // Section
                          Expanded(
                            child: TextFormField(
                              controller: _sectionController,
                              decoration: const InputDecoration(
                                labelText: 'Section *',
                                prefixIcon: Icon(Icons.group),
                                hintText: 'A',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter section';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Academic Year
                          Expanded(
                            child: TextFormField(
                              controller: _academicYearController,
                              decoration: const InputDecoration(
                                labelText: 'Academic Year *',
                                prefixIcon: Icon(Icons.calendar_today),
                                hintText: '2023-24',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter academic year';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Class Code (Read-only)
                      TextFormField(
                        initialValue: _classCode,
                        decoration: InputDecoration(
                          labelText: 'Class Code',
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed:
                                isEditing
                                    ? null
                                    : () {
                                      setState(() {
                                        _classCode = _generateClassCode();
                                      });
                                    },
                            tooltip: 'Generate new code',
                          ),
                        ),
                        readOnly: true,
                      ),
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
                        'Additional Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Schedule
                      TextFormField(
                        controller: _scheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Schedule (Optional)',
                          prefixIcon: Icon(Icons.schedule),
                          hintText: 'e.g., Mon-Fri 10:00-11:00 AM',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Brief description of the class',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveClass,
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
                          isEditing ? 'Update Class' : 'Create Class',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
