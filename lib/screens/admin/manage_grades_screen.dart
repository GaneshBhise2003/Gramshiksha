import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/academic_year_model.dart';
import '../../models/grade_model.dart';

class ManageGradesScreen extends StatefulWidget {
  final String institutionId;

  const ManageGradesScreen({super.key, required this.institutionId});

  @override
  State<ManageGradesScreen> createState() => _ManageGradesScreenState();
}

class _ManageGradesScreenState extends State<ManageGradesScreen> {
  List<GradeModel> _grades = [];
  List<AcademicYearModel> _academicYears = [];
  String? _selectedAcademicYearId;
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

      // Load grades
      _loadGrades();
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
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading grades: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades/Classes Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      floatingActionButton:
          _academicYears.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: () => _showCreateGradeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Class'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              )
              : null,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _academicYears.isEmpty
              ? _buildNoAcademicYearsState()
              : Column(
                children: [
                  _buildAcademicYearSelector(),
                  Expanded(
                    child:
                        _grades.isEmpty
                            ? _buildEmptyGradesState()
                            : _buildGradesList(),
                  ),
                ],
              ),
    );
  }

  Widget _buildNoAcademicYearsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Academic Years Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please create academic years first\nbefore managing grades',
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

  Widget _buildAcademicYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Academic Year:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedAcademicYearId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items:
                  _academicYears.map((academicYear) {
                    return DropdownMenuItem(
                      value: academicYear.id,
                      child: Row(
                        children: [
                          Text(academicYear.name),
                          if (academicYear.isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAcademicYearId = value;
                });
                _loadGrades();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGradesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Classes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create grades for the selected academic year\n(e.g., 10th Class, 12th Class, First Year)',
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

  Widget _buildGradesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _grades.length,
      itemBuilder: (context, index) {
        final grade = _grades[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    grade.type == 'school'
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                grade.type == 'school' ? Icons.school : Icons.account_balance,
                color: grade.type == 'school' ? Colors.blue : Colors.purple,
              ),
            ),
            title: Text(
              grade.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Level: ${grade.levelNumber}'),
                Text(
                  'Type: ${grade.type.toString().split('.').last.toUpperCase()}',
                ),
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
                    _showCreateGradeDialog(grade);
                    break;
                  case 'delete':
                    _deleteGrade(grade);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateGradeDialog([GradeModel? grade]) async {
    final nameController = TextEditingController(text: grade?.name ?? '');
    final levelController = TextEditingController(
      text: grade?.levelNumber.toString() ?? '',
    );
    String selectedType = grade?.type ?? 'school';

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(grade == null ? 'Create Class' : 'Edit Class'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Class Name',
                            hintText:
                                'e.g., 10th Class, First Year, B.Tech 2nd Year',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: levelController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Level Number',
                            hintText:
                                'e.g., 10 for 10th Class, 1 for First Year',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Grade Type',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              ['school', 'college'].map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        type == 'school'
                                            ? Icons.school
                                            : Icons.account_balance,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type.toUpperCase()),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedType = value);
                            }
                          },
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
                            const SnackBar(
                              content: Text('Please enter grade name'),
                            ),
                          );
                          return;
                        }

                        if (levelController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter level number'),
                            ),
                          );
                          return;
                        }

                        final levelNumber = int.tryParse(
                          levelController.text.trim(),
                        );
                        if (levelNumber == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a valid level number',
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          final databaseService = Provider.of<DatabaseService>(
                            context,
                            listen: false,
                          );

                          if (grade == null) {
                            // Create new grade
                            final newGrade = GradeModel(
                              id: '', // Will be generated by database
                              name: nameController.text.trim(),
                              institutionId: widget.institutionId,
                              academicYearId: _selectedAcademicYearId!,
                              levelNumber: levelNumber,
                              type: selectedType,
                              createdAt: DateTime.now(),
                            );

                            await databaseService.createGrade(newGrade);
                          } else {
                            // Update existing grade
                            final updatedGrade = grade.copyWith(
                              name: nameController.text.trim(),
                              levelNumber: levelNumber,
                              type: selectedType,
                            );

                            await databaseService.updateGrade(updatedGrade);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            _loadGrades();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(grade == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteGrade(GradeModel grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Class'),
            content: Text(
              'Are you sure you want to delete "${grade.name}"?\n\nThis action cannot be undone.',
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
        await databaseService.deleteGrade(grade.id);
        _loadGrades();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grade deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting grade: $e')));
        }
      }
    }
  }
}
