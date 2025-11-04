import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student_model.dart';
import '../../services/database_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentModel student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _phoneController = TextEditingController(text: widget.student.phone ?? '');
    _parentNameController = TextEditingController(text: '');
    _parentPhoneController = TextEditingController(text: '');
    _addressController = TextEditingController(
      text: widget.student.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Save'),
            )
          else
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(isTablet),

              const SizedBox(height: 32),

              // Personal Information Section
              _buildSectionHeader('Personal Information', isTablet),
              const SizedBox(height: 16),
              _buildPersonalInfoSection(isTablet),

              const SizedBox(height: 32),

              // Academic Information Section
              _buildSectionHeader('Academic Information', isTablet),
              const SizedBox(height: 16),
              _buildAcademicInfoSection(isTablet),

              const SizedBox(height: 32),

              // Contact Information Section
              _buildSectionHeader('Contact Information', isTablet),
              const SizedBox(height: 16),
              _buildContactInfoSection(isTablet),

              if (_isEditing) ...[
                const SizedBox(height: 32),
                _buildActionButtons(isTablet),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: isTablet ? 80 : 60,
            height: isTablet ? 80 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: isTablet ? 40 : 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          SizedBox(width: isTablet ? 24 : 16),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name,
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: ${widget.student.uid}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: ${widget.student.rollNumber}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isTablet) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPersonalInfoSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildInfoField(
            'Full Name',
            _nameController,
            Icons.person_outline,
            isTablet,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Email',
            _emailController,
            Icons.email_outlined,
            isTablet,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Phone Number',
            _phoneController,
            Icons.phone_outlined,
            isTablet,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            'Address',
            _addressController,
            Icons.location_on_outlined,
            isTablet,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildReadOnlyInfoRow(
            'Division',
            widget.student.divisionId,
            Icons.class_outlined,
            isTablet,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyInfoRow(
            'Student ID',
            widget.student.uid,
            Icons.badge_outlined,
            isTablet,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyInfoRow(
            'Roll Number',
            widget.student.rollNumber,
            Icons.numbers,
            isTablet,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyInfoRow(
            'Grade ID',
            widget.student.gradeId,
            Icons.grade_outlined,
            isTablet,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyInfoRow(
            'Academic Year ID',
            widget.student.academicYearId,
            Icons.calendar_today_outlined,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildReadOnlyInfoRow(
            'Parent Email',
            widget.student.parentEmail ?? 'Not specified',
            Icons.email_outlined,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isTablet, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: controller,
                enabled: _isEditing,
                validator: validator,
                keyboardType: keyboardType,
                maxLines: maxLines,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color:
                      _isEditing
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  border:
                      _isEditing
                          ? const OutlineInputBorder()
                          : InputBorder.none,
                  contentPadding:
                      _isEditing ? const EdgeInsets.all(12) : EdgeInsets.zero,
                  hintText: _isEditing ? 'Enter $label' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyInfoRow(
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEditing,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      'Save Changes',
                      style: TextStyle(fontSize: isTablet ? 16 : 14),
                    ),
          ),
        ),
      ],
    );
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Reset form fields to original values
      _nameController.text = widget.student.name;
      _emailController.text = widget.student.email;
      _phoneController.text = widget.student.phone ?? '';
      _parentNameController.text = '';
      _parentPhoneController.text = '';
      _addressController.text = widget.student.address ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );

      // Update student model
      final updatedStudent = widget.student.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
      );

      final error = await databaseService.updateStudent(updatedStudent);

      if (error == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _isEditing = false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $error'),
              backgroundColor: Colors.red,
            ),
          );
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
}
