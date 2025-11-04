import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/institution_model.dart';

class ManageInstitutionScreen extends StatefulWidget {
  final bool isFirstTime;

  const ManageInstitutionScreen({super.key, this.isFirstTime = false});

  @override
  State<ManageInstitutionScreen> createState() =>
      _ManageInstitutionScreenState();
}

class _ManageInstitutionScreenState extends State<ManageInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _codeController = TextEditingController();

  InstitutionType _selectedType = InstitutionType.college;
  bool _isLoading = false;
  InstitutionModel? _currentInstitution;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      _loadCurrentInstitution();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentInstitution() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      final adminData = await authService.getAdminData(
        authService.currentUser!.uid,
      );
      if (adminData?.institutionId != null) {
        final institution = await databaseService.getInstitutionById(
          adminData!.institutionId!,
        );
        if (institution != null) {
          setState(() {
            _currentInstitution = institution;
            _nameController.text = institution.name;
            _addressController.text = institution.address;
            _codeController.text = institution.code;
            _selectedType = institution.type;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading institution: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveInstitution() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      if (_currentInstitution == null) {
        // Create new institution
        final institutionId = await databaseService.createInstitution(
          name: _nameController.text.trim(),
          type: _selectedType,
          address: _addressController.text.trim(),
          code: _codeController.text.trim(),
          adminId: authService.currentUser!.uid,
        );

        if (institutionId != null) {
          // Update admin with institution ID
          await authService.updateUserInstitution(
            authService.currentUser!.uid,
            institutionId,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Institution created successfully!'),
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        // Update existing institution
        final updatedInstitution = _currentInstitution!.copyWith(
          name: _nameController.text.trim(),
          type: _selectedType,
          address: _addressController.text.trim(),
          code: _codeController.text.trim(),
        );

        await databaseService.updateInstitution(updatedInstitution);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Institution updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving institution: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFirstTime ? 'Create Institution' : 'Manage Institution',
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveInstitution,
              child: Text(
                _currentInstitution == null ? 'Create' : 'Update',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Institution Details',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<InstitutionType>(
                                value: _selectedType,
                                decoration: const InputDecoration(
                                  labelText: 'Institution Type',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    InstitutionType.values.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type.name.toUpperCase()),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedType = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Institution Name',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., ABC College of Technology',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter institution name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Institution Code',
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., ABC123',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter institution code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  border: OutlineInputBorder(),
                                  hintText: 'Full address of the institution',
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter address';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.isFirstTime)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Welcome to Gramshiksha!',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'As an admin, you\'ll first need to set up your institution. '
                                  'After this, you can create divisions, manage teachers and students.',
                                  textAlign: TextAlign.center,
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
}
