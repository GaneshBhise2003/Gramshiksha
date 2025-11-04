import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/division_model.dart';
import '../../models/academic_year_model.dart';
import '../../models/grade_model.dart';

class ManageDivisionsScreen extends StatefulWidget {
  final String institutionId;

  const ManageDivisionsScreen({super.key, required this.institutionId});

  @override
  State<ManageDivisionsScreen> createState() => _ManageDivisionsScreenState();
}

class _ManageDivisionsScreenState extends State<ManageDivisionsScreen> {
  List<AcademicYearModel> _academicYears = [];
  List<GradeModel> _grades = [];
  List<DivisionModel> _divisions = [];
  bool _isLoading = true;

  String? _selectedAcademicYearId;
  String? _selectedGradeId;

  @override
  void initState() {
    super.initState();
    _loadAcademicYears();
  }

  Future<void> _loadAcademicYears() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final academicYears = await databaseService.getAcademicYearsByInstitution(
        widget.institutionId,
      );
      setState(() => _academicYears = academicYears);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading academic years: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
        _divisions.clear();
      });
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
      setState(() => _divisions = divisions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading divisions: $e')));
      }
    }
  }

  Future<void> _showCreateDivisionDialog([DivisionModel? division]) async {
    if (_selectedAcademicYearId == null || _selectedGradeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an academic year and grade first'),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: division?.name ?? '');
    final descriptionController = TextEditingController(
      text: division?.description ?? '',
    );
    final maxStudentsController = TextEditingController(
      text: division?.maxStudents.toString() ?? '50',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(division == null ? 'Create Division' : 'Edit Division'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Division Name',
                      hintText: 'e.g., A, B, C',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g., Morning batch, Evening batch',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: maxStudentsController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Students',
                      hintText: 'e.g., 50',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter division name'),
                      ),
                    );
                    return;
                  }

                  try {
                    final databaseService = Provider.of<DatabaseService>(
                      context,
                      listen: false,
                    );

                    if (division == null) {
                      // Create new division
                      await databaseService.createDivision(
                        name: nameController.text.trim(),
                        institutionId: widget.institutionId,
                        academicYearId: _selectedAcademicYearId!,
                        gradeId: _selectedGradeId!,
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                        maxStudents:
                            int.tryParse(maxStudentsController.text.trim()) ??
                            50,
                      );
                    } else {
                      // Update existing division
                      final updatedDivision = division.copyWith(
                        name: nameController.text.trim(),
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                        maxStudents:
                            int.tryParse(maxStudentsController.text.trim()) ??
                            50,
                      );
                      await databaseService.updateDivision(updatedDivision);
                    }

                    Navigator.pop(context);
                    _loadDivisions();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          division == null
                              ? 'Division created successfully!'
                              : 'Division updated successfully!',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(division == null ? 'Create' : 'Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteDivision(DivisionModel division) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Division'),
            content: Text(
              'Are you sure you want to delete "${division.name}"?',
            ),
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
        await databaseService.deleteDivision(division.id);
        _loadDivisions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Division deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting division: $e')),
          );
        }
      }
    }
  }

  Widget _buildNoDataState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
              'Select Academic Hierarchy',
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
                              : 'Select academic year',
                    ),
                    items:
                        _academicYears.isEmpty
                            ? null
                            : _academicYears.map((academicYear) {
                              return DropdownMenuItem(
                                value: academicYear.id,
                                child: Text(academicYear.name),
                              );
                            }).toList(),
                    onChanged:
                        _academicYears.isEmpty
                            ? null
                            : (value) {
                              setState(() {
                                _selectedAcademicYearId = value;
                                _selectedGradeId = null;
                                _grades.clear();
                                _divisions.clear();
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
                              ? 'No classes available'
                              : 'Select classes',
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
                                _divisions.clear();
                              });
                              if (value != null) _loadDivisions();
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

  bool _canAddDivision() {
    return _selectedAcademicYearId != null && _selectedGradeId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Division Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      floatingActionButton:
          _canAddDivision()
              ? FloatingActionButton.extended(
                onPressed: () => _showCreateDivisionDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Division'),
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
                              'Click the + button to create divisions\n(e.g., A, B, C)',
                            )
                            : _buildDivisionsList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildDivisionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _divisions.length,
      itemBuilder: (context, index) {
        final division = _divisions[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                division.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(division.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (division.description != null)
                  Text('Description: ${division.description}'),
                Text('Max Students: ${division.maxStudents}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showCreateDivisionDialog(division);
                } else if (value == 'delete') {
                  _deleteDivision(division);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete'),
                        dense: true,
                      ),
                    ),
                  ],
            ),
          ),
        );
      },
    );
  }
}
