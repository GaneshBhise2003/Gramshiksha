import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/academic_year_model.dart';
import '../../models/grade_model.dart';
import '../../models/division_model.dart';
import '../../models/class_model.dart';

class ManageClassesScreen extends StatefulWidget {
  final String institutionId;

  const ManageClassesScreen({super.key, required this.institutionId});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  List<ClassModel> _classes = [];
  List<AcademicYearModel> _academicYears = [];
  List<GradeModel> _grades = [];
  List<DivisionModel> _divisions = [];

  String? _selectedAcademicYearId;
  String? _selectedGradeId;
  String? _selectedDivisionId;
  bool _isLoading = true;

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

      // Load academic years first
      final academicYears = await databaseService.getAcademicYearsByInstitution(
        widget.institutionId,
      );

      setState(() {
        _academicYears = academicYears;
        // Set current academic year as default
        if (academicYears.isNotEmpty) {
          final currentYear = academicYears.firstWhere(
            (year) => year.isCurrent,
            orElse: () => academicYears.first,
          );
          _selectedAcademicYearId = currentYear.id;
        }
      });

      // Load grades and other data
      if (_selectedAcademicYearId != null) {
        _loadGrades();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrades() async {
    if (_selectedAcademicYearId == null) return;

    try {
      print('Loading grades for academic year: $_selectedAcademicYearId');
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final grades = await databaseService
          .getGradesByInstitutionAndAcademicYear(
            widget.institutionId,
            _selectedAcademicYearId!,
          );

      print(
        'Loaded ${grades.length} grades: ${grades.map((g) => g.name).toList()}',
      );

      setState(() {
        _grades = grades;
        _selectedGradeId = grades.isNotEmpty ? grades.first.id : null;
      });

      if (_selectedGradeId != null) {
        _loadDivisions();
      } else {
        print('No grades found, clearing divisions and classes');
        setState(() {
          _divisions.clear();
          _classes.clear();
        });
      }
    } catch (e) {
      print('Error loading grades: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading grades: $e')));
      }
    }
  }

  Future<void> _loadDivisions() async {
    if (_selectedGradeId == null || _selectedAcademicYearId == null) {
      print('DEBUG: Cannot load divisions - missing gradeId or academicYearId');
      return;
    }

    print(
      'DEBUG: Starting to load divisions for grade: $_selectedGradeId, academicYear: $_selectedAcademicYearId',
    );

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      // Use the proper hierarchy method
      final divisions = await databaseService
          .getDivisionsByInstitutionAndAcademicYearAndGrade(
            widget.institutionId,
            _selectedAcademicYearId!,
            _selectedGradeId!,
          );

      print('DEBUG: Loaded ${divisions.length} divisions');

      setState(() {
        _divisions = divisions;
        _selectedDivisionId = null; // Don't auto-select, let user choose
        _classes.clear(); // Clear classes when divisions change
      });

      // Don't automatically load classes - wait for division selection
    } catch (e) {
      print('DEBUG: Error loading divisions: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading divisions: $e')));
      }
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedDivisionId == null) return;

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final allClasses = await databaseService.getClassesByInstitution(
        widget.institutionId,
      );

      // Filter classes by selected division
      final classes =
          allClasses
              .where(
                (cls) =>
                    cls.divisionId == _selectedDivisionId &&
                    cls.academicYearId == _selectedAcademicYearId &&
                    cls.gradeId == _selectedGradeId,
              )
              .toList();

      setState(() {
        _classes = classes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading classes: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Classes Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      floatingActionButton:
          _canAddClass()
              ? FloatingActionButton.extended(
                onPressed: () => _showCreateClassDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Subject Class'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              )
              : null,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _academicYears.isEmpty
              ? _buildNoDataState(
                'No Academic Years',
                'Please create academic years first',
              )
              : Column(
                children: [
                  _buildSelectionPanel(),
                  Expanded(
                    child:
                        _selectedAcademicYearId != null && _grades.isEmpty
                            ? _buildNoDataState(
                              'No Classes Found',
                              'Please create grades for the selected academic year first\n(e.g., 10th Class, 12th Class, First Year)',
                            )
                            : _selectedGradeId != null && _divisions.isEmpty
                            ? _buildNoDataState(
                              'No Divisions Found',
                              'Please create divisions for the selected grade first\n(e.g., A, B, C sections)',
                            )
                            : _classes.isEmpty && _selectedDivisionId != null
                            ? _buildNoDataState(
                              'No Subject Classes',
                              'Create subject classes for the selected division\n(e.g., Mathematics, English, Science)',
                            )
                            : _classes.isNotEmpty
                            ? _buildClassesList()
                            : _buildNoDataState(
                              'Select Hierarchy',
                              'Please select Academic Year → Grade → Division to view classes',
                            ),
                  ),
                ],
              ),
    );
  }

  bool _canAddClass() {
    return _selectedAcademicYearId != null &&
        _selectedGradeId != null &&
        _selectedDivisionId != null;
  }

  Widget _buildNoDataState(String title, String description) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subject, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Hierarchy Level:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Academic Year Selection
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Academic Year:'),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAcademicYearId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items:
                      _academicYears.map((year) {
                        return DropdownMenuItem(
                          value: year.id,
                          child: Text(year.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAcademicYearId = value;
                      _selectedGradeId = null;
                      _selectedDivisionId = null;
                      _grades.clear();
                      _divisions.clear();
                      _classes.clear();
                    });
                    if (value != null) _loadGrades();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grade Selection
          Row(
            children: [
              Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
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
                            ? 'No classes available'
                            : 'Select Class',
                  ),
                  items:
                      _grades.isEmpty
                          ? null
                          : _grades.map((grade) {
                            return DropdownMenuItem(
                              value: grade.id,
                              child: Text(grade.name),
                            );
                          }).toList(),
                  onChanged:
                      _grades.isEmpty
                          ? null
                          : (value) {
                            setState(() {
                              _selectedGradeId = value;
                              _selectedDivisionId = null;
                              _divisions.clear();
                              _classes.clear();
                            });
                            if (value != null) _loadDivisions();
                          },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Division Selection
          Row(
            children: [
              Icon(Icons.class_, color: Theme.of(context).colorScheme.primary),
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
                            ? 'No divisions available'
                            : 'Select division',
                  ),
                  items:
                      _divisions.isEmpty
                          ? null
                          : _divisions.map((division) {
                            return DropdownMenuItem(
                              value: division.id,
                              child: Text(division.name),
                            );
                          }).toList(),
                  onChanged:
                      _divisions.isEmpty
                          ? null
                          : (value) {
                            setState(() {
                              _selectedDivisionId = value;
                              _classes.clear();
                            });
                            if (value != null) _loadClasses();
                          },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classModel = _classes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.subject, color: Colors.deepPurple),
            ),
            title: Text(
              classModel.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (classModel.description?.isNotEmpty ?? false)
                  Text('Description: ${classModel.description}'),
                Text('Subject: ${classModel.subject}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showCreateClassDialog(classModel);
                    break;
                  case 'delete':
                    _deleteClass(classModel);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateClassDialog([ClassModel? classModel]) async {
    final nameController = TextEditingController(text: classModel?.name ?? '');
    final subjectController = TextEditingController(
      text: classModel?.subject ?? '',
    );
    final descriptionController = TextEditingController(
      text: classModel?.description ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              classModel == null
                  ? 'Create Subject Class'
                  : 'Edit Subject Class',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Class Name',
                      hintText: 'e.g., 10th A - Mathematics',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      hintText: 'e.g., Mathematics, English, Science',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Brief description of the class',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter class name')),
                    );
                    return;
                  }

                  if (subjectController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter subject')),
                    );
                    return;
                  }

                  try {
                    final databaseService = Provider.of<DatabaseService>(
                      context,
                      listen: false,
                    );

                    if (classModel == null) {
                      // Create new class
                      final newClass = ClassModel(
                        id: '', // Will be generated by database
                        name: nameController.text.trim(),
                        subject: subjectController.text.trim(),
                        description: descriptionController.text.trim(),
                        institutionId: widget.institutionId,
                        academicYearId: _selectedAcademicYearId!,
                        gradeId: _selectedGradeId!,
                        divisionId: _selectedDivisionId!,
                        classCode: '', // Will be generated
                        teacherId: '', // Will be assigned later
                        createdAt: DateTime.now(),
                        isActive: true,
                      );

                      await databaseService.createClass(newClass);
                    } else {
                      // Update existing class
                      final updatedClass = classModel.copyWith(
                        name: nameController.text.trim(),
                        subject: subjectController.text.trim(),
                        description: descriptionController.text.trim(),
                      );

                      await databaseService.updateClass(updatedClass);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _loadClasses();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text(classModel == null ? 'Create' : 'Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Subject Class'),
            content: Text(
              'Are you sure you want to delete "${classModel.name}"?\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        await databaseService.deleteClass(classModel.id);
        _loadClasses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject class deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting class: $e')));
        }
      }
    }
  }
}
