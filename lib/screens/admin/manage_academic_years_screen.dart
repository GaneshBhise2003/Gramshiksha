import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/academic_year_model.dart';

class ManageAcademicYearsScreen extends StatefulWidget {
  final String institutionId;

  const ManageAcademicYearsScreen({super.key, required this.institutionId});

  @override
  State<ManageAcademicYearsScreen> createState() =>
      _ManageAcademicYearsScreenState();
}

class _ManageAcademicYearsScreenState extends State<ManageAcademicYearsScreen> {
  List<AcademicYearModel> _academicYears = [];
  bool _isLoading = true;

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

      setState(() {
        _academicYears = academicYears;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Years Management'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAcademicYearDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Academic Year'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _academicYears.isEmpty
              ? _buildEmptyState()
              : _buildAcademicYearsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Academic Years',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first academic year to get started\n(e.g., 2025-26, 2026-27)',
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

  Widget _buildAcademicYearsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _academicYears.length,
      itemBuilder: (context, index) {
        final academicYear = _academicYears[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    academicYear.isCurrent
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                academicYear.isCurrent ? Icons.star : Icons.calendar_today,
                color: academicYear.isCurrent ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              academicYear.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start: ${_formatDate(academicYear.startDate)}'),
                Text('End: ${_formatDate(academicYear.endDate)}'),
                if (academicYear.isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
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
                    if (!academicYear.isCurrent)
                      const PopupMenuItem(
                        value: 'set_current',
                        child: Row(
                          children: [
                            Icon(Icons.star),
                            SizedBox(width: 8),
                            Text('Set as Current'),
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
                    _showCreateAcademicYearDialog(academicYear);
                    break;
                  case 'set_current':
                    _setCurrentAcademicYear(academicYear);
                    break;
                  case 'delete':
                    _deleteAcademicYear(academicYear);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showCreateAcademicYearDialog([
    AcademicYearModel? academicYear,
  ]) async {
    final nameController = TextEditingController(
      text: academicYear?.name ?? '',
    );
    DateTime startDate = academicYear?.startDate ?? DateTime.now();
    DateTime endDate =
        academicYear?.endDate ?? DateTime.now().add(const Duration(days: 365));

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    academicYear == null
                        ? 'Create Academic Year'
                        : 'Edit Academic Year',
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Academic Year Name',
                            hintText: 'e.g., 2025-26',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Start Date'),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setDialogState(
                                          () => startDate = picked,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(_formatDate(startDate)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('End Date'),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: endDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setDialogState(() => endDate = picked);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(_formatDate(endDate)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                              content: Text('Please enter academic year name'),
                            ),
                          );
                          return;
                        }

                        try {
                          final databaseService = Provider.of<DatabaseService>(
                            context,
                            listen: false,
                          );

                          if (academicYear == null) {
                            // Create new academic year
                            final newAcademicYear = AcademicYearModel(
                              id: '', // Will be generated by database
                              name: nameController.text.trim(),
                              institutionId: widget.institutionId,
                              startDate: startDate,
                              endDate: endDate,
                              isActive: true,
                              isCurrent:
                                  _academicYears
                                      .isEmpty, // First academic year is current
                              createdAt: DateTime.now(),
                            );

                            await databaseService.createAcademicYear(
                              newAcademicYear,
                            );
                          } else {
                            // Update existing academic year
                            final updatedAcademicYear = academicYear.copyWith(
                              name: nameController.text.trim(),
                              startDate: startDate,
                              endDate: endDate,
                            );

                            await databaseService.updateAcademicYear(
                              updatedAcademicYear,
                            );
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            _loadAcademicYears();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(academicYear == null ? 'Create' : 'Update'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _setCurrentAcademicYear(AcademicYearModel academicYear) async {
    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      await databaseService.setCurrentAcademicYear(academicYear.id);
      _loadAcademicYears();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${academicYear.name} set as current academic year'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAcademicYear(AcademicYearModel academicYear) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Academic Year'),
            content: Text(
              'Are you sure you want to delete "${academicYear.name}"?\n\nThis action cannot be undone.',
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
        await databaseService.deleteAcademicYear(academicYear.id);
        _loadAcademicYears();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Academic year deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting academic year: $e')),
          );
        }
      }
    }
  }
}
