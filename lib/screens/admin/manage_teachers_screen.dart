import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/teacher_model.dart';
import '../../models/division_model.dart';

class ManageTeachersScreen extends StatefulWidget {
  final String institutionId;

  const ManageTeachersScreen({super.key, required this.institutionId});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  List<TeacherModel> _teachers = [];
  List<DivisionModel> _divisions = [];
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
      final teachers = await databaseService.getTeachersByInstitution(
        widget.institutionId,
      );
      final divisions = await databaseService.getDivisionsByInstitutionFuture(
        widget.institutionId,
      );

      setState(() {
        _teachers = teachers;
        _divisions = divisions;
      });
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

  Future<void> _showCreateTeacherDialog([TeacherModel? teacher]) async {
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final emailController = TextEditingController(text: teacher?.email ?? '');
    final phoneController = TextEditingController(text: teacher?.phone ?? '');
    final subjectController = TextEditingController(
      text: teacher?.subject ?? '',
    );
    final passwordController = TextEditingController();
    String? selectedDivisionId =
        _divisions.isNotEmpty ? _divisions.first.id : null;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(teacher == null ? 'Create Teacher' : 'Edit Teacher'),
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
                            hintText: 'Enter teacher name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'teacher@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          enabled:
                              teacher ==
                              null, // Don't allow email change for existing teachers
                        ),
                        if (teacher == null) ...[
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
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone (Optional)',
                            hintText: '+1234567890',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject/Specialization',
                            hintText: 'e.g., Mathematics, Physics',
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedDivisionId,
                          decoration: const InputDecoration(
                            labelText: 'Division',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Select Division'),
                          items:
                              _divisions.map((division) {
                                return DropdownMenuItem(
                                  value: division.id,
                                  child: Text(division.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setDialogState(() => selectedDivisionId = value);
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
                        content: Text('Please enter teacher name'),
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

                  if (teacher == null && passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 6 characters'),
                      ),
                    );
                    return;
                  }

                  if (selectedDivisionId == null) {
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

                    if (teacher == null) {
                      // Create new teacher
                      final result = await authService.createTeacherAccount(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        name: nameController.text.trim(),
                        institutionId: widget.institutionId,
                        divisionId: selectedDivisionId,
                        phone:
                            phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                        subject:
                            subjectController.text.trim().isEmpty
                                ? null
                                : subjectController.text.trim(),
                      );

                      if (!result['success']) {
                        throw Exception(result['error']);
                      }
                    } else {
                      // Update existing teacher
                      final updatedTeacher = teacher.copyWith(
                        name: nameController.text.trim(),
                        phone:
                            phoneController.text.trim().isEmpty
                                ? null
                                : phoneController.text.trim(),
                        subject:
                            subjectController.text.trim().isEmpty
                                ? null
                                : subjectController.text.trim(),
                      );

                      await databaseService.updateTeacher(updatedTeacher);
                    }

                    Navigator.pop(context);
                    _loadData();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          teacher == null
                              ? 'Teacher created successfully!'
                              : 'Teacher updated successfully!',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: Text(teacher == null ? 'Create' : 'Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTeacher(TeacherModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Teacher'),
            content: Text('Are you sure you want to delete "${teacher.name}"?'),
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

        // Delete from authentication
        // Note: This would typically require admin privileges in Firebase Auth
        // For now, we'll just remove from our database

        await databaseService.deleteTeacher(teacher.uid);
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting teacher: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        actions: [
          IconButton(
            onPressed: () => _showCreateTeacherDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _teachers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No teachers found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create teacher accounts for your institution',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showCreateTeacherDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Teacher'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _teachers.length,
                itemBuilder: (context, index) {
                  final teacher = _teachers[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          teacher.name.isNotEmpty
                              ? teacher.name[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(teacher.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher.email),
                          Text('Institution: ${widget.institutionId}'),
                          if (teacher.subject != null)
                            Text('Subject: ${teacher.subject}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showCreateTeacherDialog(teacher),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _deleteTeacher(teacher),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      floatingActionButton:
          _teachers.isNotEmpty
              ? FloatingActionButton(
                onPressed: () => _showCreateTeacherDialog(),
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
