import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/assignment_model.dart';
import '../../models/assignment_submission_model.dart';
import '../../models/student_model.dart';
import '../../models/class_model.dart';
import '../../utils/responsive_helper.dart';

class AssignmentManagementScreen extends StatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  State<AssignmentManagementScreen> createState() =>
      _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TeacherModel? _cachedTeacher;
  bool _isLoadingTeacher = true;
  String? _selectedAssignmentForSubmissions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final teacher = await databaseService.getTeacher(authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _cachedTeacher = teacher;
          _isLoadingTeacher = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeacher = false);
      }
    }
  }

  void _selectAssignmentForSubmissions(String assignmentId) {
    setState(() {
      _selectedAssignmentForSubmissions = assignmentId;
    });
    _tabController.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Assignments', icon: Icon(Icons.assignment)),
            Tab(text: 'Create', icon: Icon(Icons.add)),
            Tab(text: 'Submissions', icon: Icon(Icons.inbox)),
          ],
        ),
      ),
      body: _buildBody(isTablet),
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_isLoadingTeacher) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedTeacher == null) {
      return const Center(child: Text('Teacher data not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _AssignmentsListTab(
          teacher: _cachedTeacher!,
          onViewSubmissions: _selectAssignmentForSubmissions,
        ),
        _CreateAssignmentTab(teacher: _cachedTeacher!, isTablet: isTablet),
        _SubmissionsTab(
          teacher: _cachedTeacher!,
          isTablet: isTablet,
          selectedAssignmentId: _selectedAssignmentForSubmissions,
        ),
      ],
    );
  }
}

class _AssignmentsListTab extends StatefulWidget {
  final TeacherModel teacher;
  final Function(String) onViewSubmissions;

  const _AssignmentsListTab({
    required this.teacher,
    required this.onViewSubmissions,
  });

  @override
  State<_AssignmentsListTab> createState() => _AssignmentsListTabState();
}

class _AssignmentsListTabState extends State<_AssignmentsListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _AssignmentsListContent(
      teacher: widget.teacher,
      onViewSubmissions: widget.onViewSubmissions,
    );
  }
}

class _AssignmentsListContent extends StatefulWidget {
  final TeacherModel teacher;
  final Function(String) onViewSubmissions;

  const _AssignmentsListContent({
    required this.teacher,
    required this.onViewSubmissions,
  });

  @override
  State<_AssignmentsListContent> createState() => _AssignmentsListContentState();
}

class _AssignmentsListContentState extends State<_AssignmentsListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search assignments...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Class Filter
              StreamBuilder<List<ClassModel>>(
                stream: databaseService.getTeacherClasses(widget.teacher.uid),
                builder: (context, classSnapshot) {
                  if (!classSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final classes = classSnapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                            (classModel) => DropdownMenuItem(
                          value: classModel.id,
                          child: Text(classModel.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        // Assignments List
        Expanded(
          child: _AssignmentsList(
            teacher: widget.teacher,
            searchQuery: _searchQuery,
            selectedClassId: _selectedClassId,
            onViewSubmissions: widget.onViewSubmissions,
          ),
        ),
      ],
    );
  }
}

class _AssignmentsList extends StatefulWidget {
  final TeacherModel teacher;
  final String searchQuery;
  final String? selectedClassId;
  final Function(String) onViewSubmissions;

  const _AssignmentsList({
    required this.teacher,
    required this.searchQuery,
    required this.selectedClassId,
    required this.onViewSubmissions,
  });

  @override
  State<_AssignmentsList> createState() => _AssignmentsListState();
}

class _AssignmentsListState extends State<_AssignmentsList> {
  List<AssignmentModel> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final assignments = await databaseService.getTeacherAssignments(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var assignments = _assignments;

    // Apply filters
    if (widget.selectedClassId != null) {
      assignments = assignments
          .where((assignment) => assignment.classId == widget.selectedClassId)
          .toList();
    }

    if (widget.searchQuery.isNotEmpty) {
      assignments = assignments.where((assignment) {
        return assignment.title.toLowerCase().contains(widget.searchQuery) ||
            assignment.description.toLowerCase().contains(widget.searchQuery);
      }).toList();
    }

    if (assignments.isEmpty) {
      return _EmptyAssignmentsState(
        searchQuery: widget.searchQuery,
        hasSelectedClass: widget.selectedClassId != null,
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        itemCount: assignments.length,
        itemBuilder: (context, index) => _AssignmentCard(
          assignment: assignments[index],
          databaseService: databaseService,
          onViewSubmissions: widget.onViewSubmissions,
        ),
      ),
    );
  }
}

class _EmptyAssignmentsState extends StatelessWidget {
  final String searchQuery;
  final bool hasSelectedClass;

  const _EmptyAssignmentsState({
    required this.searchQuery,
    required this.hasSelectedClass,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (searchQuery.isNotEmpty) return 'No matching assignments';
    if (hasSelectedClass) return 'No assignments for selected class';
    return 'No assignments found';
  }

  String _getEmptyStateSubtitle() {
    if (searchQuery.isNotEmpty) return 'Try a different search term';
    if (hasSelectedClass) return 'Create an assignment for this class';
    return 'Create your first assignment to get started';
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final DatabaseService databaseService;
  final Function(String) onViewSubmissions;

  const _AssignmentCard({
    required this.assignment,
    required this.databaseService,
    required this.onViewSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isOverdue = DateTime.now().isAfter(assignment.dueDate);

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showAssignmentDetails(context, assignment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'submissions',
                        child: ListTile(
                          leading: Icon(Icons.inbox),
                          title: Text('View Submissions'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editAssignment(context, assignment);
                          break;
                        case 'submissions':
                          onViewSubmissions(assignment.id);
                          break;
                        case 'delete':
                          _deleteAssignment(context, assignment);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy hh:mm a').format(assignment.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${assignment.totalMarks} marks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveHelper.isDesktop(context) ? 600 : null,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(assignment.title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(assignment.description),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy hh:mm a').format(assignment.dueDate),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Marks',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text('${assignment.totalMarks}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(assignment.createdAt),
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

  void _editAssignment(BuildContext context, AssignmentModel assignment) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit assignment feature coming soon!')),
    );
  }

  void _deleteAssignment(BuildContext context, AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete assignment feature coming soon!'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAssignmentTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateAssignmentTab({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateAssignmentTab> createState() => _CreateAssignmentTabState();
}

class _CreateAssignmentTabState extends State<_CreateAssignmentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _CreateAssignmentForm(
      teacher: widget.teacher,
      isTablet: widget.isTablet,
    );
  }
}

class _CreateAssignmentForm extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateAssignmentForm({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateAssignmentForm> createState() => __CreateAssignmentFormState();
}

class __CreateAssignmentFormState extends State<_CreateAssignmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalMarksController = TextEditingController();
  String? _selectedClassId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isLoading = false;
  List<ClassModel> _classes = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final classes = await databaseService.getTeacherClasses(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time != null) {
      setState(() {
        _dueTime = time;
      });
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null || _dueTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select due date and time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      if (_classes.isEmpty) {
        throw Exception('No classes available. Please create a class first.');
      }

      final selectedClass = _classes.firstWhere(
            (c) => c.id == _selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final assignmentId = const Uuid().v4();
      final dueDateTime = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        _dueTime!.hour,
        _dueTime!.minute,
      );

      final assignment = AssignmentModel(
        id: assignmentId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        institutionId: widget.teacher.institutionId,
        divisionId: selectedClass.divisionId,
        classId: _selectedClassId!,
        teacherId: widget.teacher.uid,
        dueDate: dueDateTime,
        totalMarks: int.parse(_totalMarksController.text.trim()),
        createdAt: DateTime.now(),
      );

      final result = await databaseService.createAssignment(assignment);

      if (result == null) {
        // Success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment created successfully!')),
          );

          // Clear form
          _titleController.clear();
          _descriptionController.clear();
          _totalMarksController.clear();
          setState(() {
            _selectedClassId = null;
            _dueDate = null;
            _dueTime = null;
          });
        }
      } else {
        // Error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating assignment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Assignment',
              style: TextStyle(
                fontSize: widget.isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Assignment Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                hintText: 'e.g., Math Assignment - Chapter 5',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an assignment title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Assignment Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Assignment Description',
                hintText: 'Describe the assignment requirements...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an assignment description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Class Selection
            _buildClassSelection(),

            const SizedBox(height: 16),

            // Total Marks
            TextFormField(
              controller: _totalMarksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Marks',
                hintText: 'e.g., 100',
                prefixIcon: Icon(Icons.grade),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter total marks';
                }
                final marks = int.tryParse(value);
                if (marks == null || marks <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dueDate != null
                            ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _dueDate != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Time',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _dueTime != null
                            ? _dueTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: _dueTime != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAssignment,
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Creating...'),
                  ],
                )
                    : const Text('Create Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    if (_isLoadingClasses) {
      return const CircularProgressIndicator();
    }

    if (_classes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No classes available. Please contact your administrator.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'Select Class',
        prefixIcon: Icon(Icons.class_),
      ),
      items: _classes
          .map(
            (classModel) => DropdownMenuItem(
          value: classModel.id,
          child: Text(classModel.name),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedClassId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a class';
        }
        return null;
      },
    );
  }
}

class _SubmissionsTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;
  final String? selectedAssignmentId;

  const _SubmissionsTab({
    required this.teacher,
    required this.isTablet,
    required this.selectedAssignmentId,
  });

  @override
  State<_SubmissionsTab> createState() => _SubmissionsTabState();
}

class _SubmissionsTabState extends State<_SubmissionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _SubmissionsContent(
      teacher: widget.teacher,
      isTablet: widget.isTablet,
      selectedAssignmentId: widget.selectedAssignmentId,
    );
  }
}

class _SubmissionsContent extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;
  final String? selectedAssignmentId;

  const _SubmissionsContent({
    required this.teacher,
    required this.isTablet,
    required this.selectedAssignmentId,
  });

  @override
  State<_SubmissionsContent> createState() => _SubmissionsContentState();
}

class _SubmissionsContentState extends State<_SubmissionsContent> {
  String? _selectedAssignmentForSubmissions;

  @override
  void initState() {
    super.initState();
    _selectedAssignmentForSubmissions = widget.selectedAssignmentId;
  }

  @override
  void didUpdateWidget(covariant _SubmissionsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAssignmentId != oldWidget.selectedAssignmentId) {
      setState(() {
        _selectedAssignmentForSubmissions = widget.selectedAssignmentId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Column(
      children: [
        // Assignment Filter for submissions
        Container(
          padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
          child: StreamBuilder<List<AssignmentModel>>(
            stream: databaseService.getTeacherAssignments(widget.teacher.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final assignments = snapshot.data!;
              if (assignments.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No assignments found. Create assignments to view submissions.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedAssignmentForSubmissions,
                decoration: const InputDecoration(
                  labelText: 'Select Assignment to View Submissions',
                  prefixIcon: Icon(Icons.assignment),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select an assignment...'),
                  ),
                  ...assignments.map(
                        (assignment) => DropdownMenuItem(
                      value: assignment.id,
                      child: Text(
                        '${assignment.title} (${DateFormat('MMM dd').format(assignment.dueDate)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAssignmentForSubmissions = value;
                  });
                },
              );
            },
          ),
        ),
        // Submissions List
        Expanded(
          child: _selectedAssignmentForSubmissions == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select an assignment',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an assignment from the dropdown to view submissions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
              : _SubmissionsList(
            assignmentId: _selectedAssignmentForSubmissions!,
            isTablet: widget.isTablet,
          ),
        ),
      ],
    );
  }
}

class _SubmissionsList extends StatefulWidget {
  final String assignmentId;
  final bool isTablet;

  const _SubmissionsList({
    required this.assignmentId,
    required this.isTablet,
  });

  @override
  State<_SubmissionsList> createState() => _SubmissionsListState();
}

class _SubmissionsListState extends State<_SubmissionsList> {
  List<AssignmentSubmissionModel> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final submissions = await _getAssignmentSubmissions(widget.assignmentId).first;
      if (mounted) {
        setState(() {
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Stream<List<AssignmentSubmissionModel>> _getAssignmentSubmissions(String assignmentId) {
    return FirebaseFirestore.instance
        .collection('assignment_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => AssignmentSubmissionModel.fromMap(doc.data()))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final databaseService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<List<AssignmentModel>>(
      stream: databaseService.getTeacherAssignments(authService.currentUser!.uid),
      builder: (context, assignmentSnapshot) {
        if (!assignmentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignment = assignmentSnapshot.data!.firstWhere(
              (a) => a.id == widget.assignmentId,
          orElse: () => AssignmentModel(
            id: widget.assignmentId,
            title: 'Assignment',
            description: '',
            institutionId: '',
            divisionId: '',
            classId: '',
            teacherId: '',
            dueDate: DateTime.now(),
            totalMarks: 100,
            createdAt: DateTime.now(),
          ),
        );

        return StreamBuilder<List<StudentModel>>(
          stream: databaseService.getClassStudents(assignment.divisionId),
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!studentsSnapshot.hasData || studentsSnapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No students found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No students are enrolled in this class',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            final students = studentsSnapshot.data!;
            final submissionMap = {
              for (var submission in _submissions) submission.studentId: submission,
            };

            return Column(
              children: [
                // Assignment Info Header
                Container(
                  padding: EdgeInsets.all(widget.isTablet ? 20 : 16),
                  margin: EdgeInsets.all(widget.isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.title,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy hh:mm a').format(assignment.dueDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${_submissions.length}/${students.length}',
                            style: TextStyle(
                              fontSize: widget.isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Submitted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Submissions List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadSubmissions,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isTablet ? 20 : 16,
                        vertical: 8,
                      ),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final submission = submissionMap[student.uid];
                        return _SubmissionCard(
                          student: student,
                          submission: submission,
                          assignment: assignment,
                          isTablet: widget.isTablet,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final StudentModel student;
  final AssignmentSubmissionModel? submission;
  final AssignmentModel assignment;
  final bool isTablet;

  const _SubmissionCard({
    required this.student,
    required this.submission,
    required this.assignment,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final hasSubmission = submission != null;
    final isOverdue = DateTime.now().isAfter(assignment.dueDate);
    final isLateSubmission =
        hasSubmission && submission!.submittedAt.isAfter(assignment.dueDate);

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: InkWell(
        onTap: hasSubmission
            ? () => _viewSubmissionDetails(
          context,
          submission!,
          student,
          assignment,
          databaseService,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Row(
            children: [
              // Student Avatar
              CircleAvatar(
                radius: isTablet ? 24 : 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  student.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll: ${student.rollNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (hasSubmission) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${DateFormat('MMM dd, hh:mm a').format(submission!.submittedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLateSubmission ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasSubmission)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: submission!.isGraded
                            ? Colors.green.shade100
                            : isLateSubmission
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        submission!.isGraded
                            ? 'Graded'
                            : isLateSubmission
                            ? 'Late'
                            : 'Submitted',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: submission!.isGraded
                              ? Colors.green.shade700
                              : isLateSubmission
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue ? Colors.red.shade100 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOverdue ? 'Missing' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (hasSubmission && submission!.isGraded)
                    Text(
                      '${submission!.marks?.toInt() ?? 0}/${assignment.totalMarks}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
              if (hasSubmission)
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('View Details'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'grade',
                      enabled: !submission!.isGraded,
                      child: const ListTile(
                        leading: Icon(Icons.grade),
                        title: Text('Grade Submission'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _viewSubmissionDetails(
                          context,
                          submission!,
                          student,
                          assignment,
                          databaseService,
                        );
                        break;
                      case 'grade':
                        _gradeSubmission(
                          context,
                          submission!,
                          student,
                          assignment,
                          databaseService,
                        );
                        break;
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewSubmissionDetails(
      BuildContext context,
      AssignmentSubmissionModel submission,
      StudentModel student,
      AssignmentModel assignment,
      DatabaseService databaseService,
      ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveHelper.isDesktop(context) ? 700 : null,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('${student.name}\'s Submission'),
                automaticallyImplyLeading: false,
                actions: [
                  if (!submission.isGraded)
                    TextButton.icon(
                      icon: const Icon(Icons.grade),
                      label: const Text('Grade'),
                      onPressed: () {
                        Navigator.pop(context);
                        _gradeSubmission(
                          context,
                          submission,
                          student,
                          assignment,
                          databaseService,
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assignment Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assignment',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(assignment.title),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Student',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text('${student.name} (${student.rollNumber})'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Submission Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Submitted At',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy hh:mm a').format(submission.submittedAt),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  submission.submittedAt.isAfter(assignment.dueDate)
                                      ? 'Late Submission'
                                      : 'On Time',
                                  style: TextStyle(
                                    color: submission.submittedAt.isAfter(assignment.dueDate)
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Content
                      if (submission.content != null && submission.content!.isNotEmpty) ...[
                        Text(
                          'Submission Content',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(submission.content!),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Attachments
                      if (submission.attachments.isNotEmpty) ...[
                        Text(
                          'Attachments',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...submission.attachments.map(
                              (attachment) => ListTile(
                            leading: const Icon(Icons.attachment),
                            title: Text(attachment['name'] ?? 'Attachment'),
                            subtitle: Text(attachment['type'] ?? 'File'),
                            trailing: const Icon(Icons.download),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('File download feature coming soon!'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Grading Info
                      if (submission.isGraded) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.grade, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Graded',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${submission.marks?.toInt() ?? 0}/${assignment.totalMarks}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Feedback:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(submission.feedback!),
                              ],
                              if (submission.gradedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Graded on: ${DateFormat('MMM dd, yyyy hh:mm a').format(submission.gradedAt!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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

  void _gradeSubmission(
      BuildContext context,
      AssignmentSubmissionModel submission,
      StudentModel student,
      AssignmentModel assignment,
      DatabaseService databaseService,
      ) {
    final marksController = TextEditingController(
      text: submission.marks?.toInt().toString() ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${student.name}\'s Submission'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: marksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Marks (out of ${assignment.totalMarks})',
                  prefixIcon: const Icon(Icons.grade),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Feedback (optional)',
                  prefixIcon: Icon(Icons.comment),
                  alignLabelWithHint: true,
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
              final marksText = marksController.text.trim();
              if (marksText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter marks')),
                );
                return;
              }

              final marks = double.tryParse(marksText);
              if (marks == null || marks < 0 || marks > assignment.totalMarks) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter valid marks between 0 and ${assignment.totalMarks}',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await FirebaseFirestore.instance
                    .collection('assignment_submissions')
                    .doc(submission.id)
                    .update({
                  'isGraded': true,
                  'marks': marks,
                  'feedback': feedbackController.text.trim(),
                  'gradedAt': Timestamp.fromDate(DateTime.now()),
                  'gradedBy': Provider.of<AuthService>(context, listen: false).currentUser?.uid,
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Submission graded successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error grading submission: $e')),
                  );
                }
              }
            },
            child: const Text('Grade'),
          ),
        ],
      ),
    );
  }
}