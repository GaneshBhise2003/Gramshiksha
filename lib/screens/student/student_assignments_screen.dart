import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/assignment_model.dart';
import '../../models/assignment_submission_model.dart';
import '../../utils/responsive_helper.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  final StudentModel student;

  const StudentAssignmentsScreen({super.key, required this.student});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Submitted', icon: Icon(Icons.check_circle)),
            Tab(text: 'All', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentsList(
            databaseService,
            isTablet,
            AssignmentFilter.pending,
          ),
          _buildAssignmentsList(
            databaseService,
            isTablet,
            AssignmentFilter.submitted,
          ),
          _buildAssignmentsList(
            databaseService,
            isTablet,
            AssignmentFilter.all,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList(
    DatabaseService databaseService,
    bool isTablet,
    AssignmentFilter filter,
  ) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: databaseService.getClassAssignments(widget.student.divisionId),
      builder: (context, assignmentSnapshot) {
        if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!assignmentSnapshot.hasData || assignmentSnapshot.data!.isEmpty) {
          return _buildEmptyState(filter);
        }

        final assignments = assignmentSnapshot.data!;

        return StreamBuilder<List<AssignmentSubmissionModel>>(
          stream: databaseService.getStudentSubmissions(widget.student.uid),
          builder: (context, submissionSnapshot) {
            final submissions = submissionSnapshot.data ?? [];
            final submittedAssignmentIds =
                submissions.map((s) => s.assignmentId).toSet();

            List<AssignmentModel> filteredAssignments;
            switch (filter) {
              case AssignmentFilter.pending:
                filteredAssignments =
                    assignments
                        .where(
                          (a) =>
                              !submittedAssignmentIds.contains(a.id) &&
                              a.dueDate.isAfter(DateTime.now()),
                        )
                        .toList();
                break;
              case AssignmentFilter.submitted:
                filteredAssignments =
                    assignments
                        .where((a) => submittedAssignmentIds.contains(a.id))
                        .toList();
                break;
              case AssignmentFilter.all:
                filteredAssignments = assignments;
                break;
            }

            if (filteredAssignments.isEmpty) {
              return _buildEmptyState(filter);
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                itemCount: filteredAssignments.length,
                itemBuilder: (context, index) {
                  final assignment = filteredAssignments[index];
                  final isSubmitted = submittedAssignmentIds.contains(
                    assignment.id,
                  );
                  final submission = submissions.firstWhere(
                    (s) => s.assignmentId == assignment.id,
                    orElse:
                        () => AssignmentSubmissionModel(
                          id: '',
                          assignmentId: assignment.id,
                          studentId: widget.student.uid,
                          submittedAt: DateTime.now(),
                          content: '',
                          attachments: [],
                          isGraded: false,
                        ),
                  );

                  return _buildAssignmentCard(
                    assignment,
                    isSubmitted,
                    submission,
                    isTablet,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AssignmentFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case AssignmentFilter.pending:
        title = 'No pending assignments';
        subtitle = 'Great! You\'re all caught up with your assignments.';
        icon = Icons.task_alt;
        break;
      case AssignmentFilter.submitted:
        title = 'No submitted assignments';
        subtitle = 'Your submitted assignments will appear here.';
        icon = Icons.assignment_turned_in;
        break;
      case AssignmentFilter.all:
        title = 'No assignments yet';
        subtitle = 'Your teacher hasn\'t assigned any work yet.';
        icon = Icons.assignment_outlined;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(
    AssignmentModel assignment,
    bool isSubmitted,
    AssignmentSubmissionModel? submission,
    bool isTablet,
  ) {
    final isOverdue =
        !isSubmitted && assignment.dueDate.isBefore(DateTime.now());
    final isUrgent =
        !isSubmitted &&
        assignment.dueDate.difference(DateTime.now()).inDays <= 1;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isSubmitted) {
      if (submission?.isGraded == true) {
        statusColor = Colors.green;
        statusText = 'Graded';
        statusIcon = Icons.grade;
      } else {
        statusColor = Colors.blue;
        statusText = 'Submitted';
        statusIcon = Icons.check_circle;
      }
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
      statusIcon = Icons.error;
    } else if (isUrgent) {
      statusColor = Colors.orange;
      statusText = 'Due Soon';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.grey;
      statusText = 'Pending';
      statusIcon = Icons.pending;
    }

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      elevation: 2,
      child: InkWell(
        onTap:
            () => _showAssignmentDetails(assignment, isSubmitted, submission),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 8),
                        Text(
                          assignment.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy - HH:mm').format(assignment.dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  if (assignment.totalMarks > 0) ...[
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${assignment.totalMarks} marks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
              if (submission?.marks != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.grade, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${submission!.marks}/${assignment.totalMarks}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      if (submission.feedback?.isNotEmpty == true) ...[
                        const Spacer(),
                        const Icon(Icons.comment, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Feedback',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
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
    );
  }

  void _showAssignmentDetails(
    AssignmentModel assignment,
    bool isSubmitted,
    AssignmentSubmissionModel? submission,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AssignmentDetailsDialog(
            assignment: assignment,
            student: widget.student,
            isSubmitted: isSubmitted,
            submission: submission,
          ),
    );
  }
}

enum AssignmentFilter { pending, submitted, all }

class AssignmentDetailsDialog extends StatefulWidget {
  final AssignmentModel assignment;
  final StudentModel student;
  final bool isSubmitted;
  final AssignmentSubmissionModel? submission;

  const AssignmentDetailsDialog({
    super.key,
    required this.assignment,
    required this.student,
    required this.isSubmitted,
    this.submission,
  });

  @override
  State<AssignmentDetailsDialog> createState() =>
      _AssignmentDetailsDialogState();
}

class _AssignmentDetailsDialogState extends State<AssignmentDetailsDialog> {
  final TextEditingController _submissionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.submission != null &&
        widget.submission!.content?.isNotEmpty == true) {
      _submissionController.text = widget.submission!.content ?? '';
    }
  }

  @override
  void dispose() {
    _submissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        !widget.isSubmitted &&
        widget.assignment.dueDate.isBefore(DateTime.now());

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.assignment.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assignment Details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'Description',
                      widget.assignment.description,
                    ),
                    _buildDetailRow(
                      'Due Date',
                      DateFormat(
                        'EEEE, MMMM dd, yyyy at HH:mm',
                      ).format(widget.assignment.dueDate),
                    ),
                    if (widget.assignment.totalMarks > 0)
                      _buildDetailRow(
                        'Total Marks',
                        widget.assignment.totalMarks.toString(),
                      ),
                    _buildDetailRow(
                      'Created',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(widget.assignment.createdAt),
                    ),

                    const SizedBox(height: 24),

                    // Submission Section
                    if (!widget.isSubmitted && !isOverdue) ...[
                      const Text(
                        'Your Submission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _submissionController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Enter your assignment submission here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else if (widget.isSubmitted) ...[
                      const Text(
                        'Your Submission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.submission?.content ?? 'No content',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Submitted On',
                        DateFormat(
                          'MMM dd, yyyy at HH:mm',
                        ).format(widget.submission!.submittedAt),
                      ),
                      if (widget.submission?.marks != null) ...[
                        _buildDetailRow(
                          'Score',
                          '${widget.submission!.marks}/${widget.assignment.totalMarks}',
                        ),
                        if (widget.submission?.feedback?.isNotEmpty == true)
                          _buildDetailRow(
                            'Feedback',
                            widget.submission!.feedback!,
                          ),
                      ],
                    ] else if (isOverdue) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This assignment is overdue. You can no longer submit it.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Submit Button
            if (!widget.isSubmitted && !isOverdue) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAssignment,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Submit Assignment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _submitAssignment() async {
    if (_submissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your submission content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final submissionId = DateTime.now().millisecondsSinceEpoch.toString();

    final submission = AssignmentSubmission(
      id: submissionId,
      assignmentId: widget.assignment.id,
      studentId: widget.student.uid,
      submittedAt: DateTime.now(),
      answer: _submissionController.text.trim(),
      status: AssignmentStatus.submitted,
    );

    final error = await databaseService.submitAssignment(submission);

    setState(() => _isSubmitting = false);

    if (error == null) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit assignment: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
