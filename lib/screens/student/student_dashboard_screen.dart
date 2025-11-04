import 'package:flutter/material.dart';
import 'package:gramshiksha/screens/student/StudentCoursesScreen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/student_model.dart';
import '../../models/announcement_model.dart';
import '../../models/assignment_model.dart';
import '../../models/course_model.dart';
import '../../models/attendance_model.dart';
import '../../models/quiz_model.dart';
import '../../utils/responsive_helper.dart';
import 'student_assignments_screen.dart';
import 'student_quizzes_screen.dart';
import 'student_attendance_screen.dart';
import 'student_announcements_screen.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onPressed: () => _showProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              if (shouldLogout == true) {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.signOut();

                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              }
            },
          ),
        ],
      ),

      body: FutureBuilder<StudentModel?>(
        future: databaseService.getStudentById(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Student data not found'));
          }

          final student = snapshot.data!;
          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(student, isTablet),
                    const SizedBox(height: 24),
                    _buildQuickStats(student, databaseService, isTablet),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, student, isTablet),
                    const SizedBox(height: 24),
                    if (isDesktop) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildRecentAnnouncements(
                                  student,
                                  databaseService,
                                ),
                                const SizedBox(height: 24),
                                _buildUpcomingAssignments(
                                  student,
                                  databaseService,
                                ),
                                const SizedBox(height: 24),
                                _buildRecentCourses(student, databaseService),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildAttendanceOverview(
                                  student,
                                  databaseService,
                                  isTablet,
                                ),
                                const SizedBox(height: 24),
                                _buildRecentQuizzes(student, databaseService),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildRecentAnnouncements(student, databaseService),
                      const SizedBox(height: 24),
                      _buildUpcomingAssignments(student, databaseService),
                      const SizedBox(height: 24),
                      _buildRecentCourses(student, databaseService),
                      const SizedBox(height: 24),
                      _buildAttendanceOverview(
                        student,
                        databaseService,
                        isTablet,
                      ),
                      const SizedBox(height: 24),
                      _buildRecentQuizzes(student, databaseService),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(StudentModel student, bool isTablet) {
    final now = DateTime.now();
    final greeting =
        now.hour < 12
            ? 'Good Morning'
            : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${student.name.split(' ').first}!',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Roll No: ${student.rollNumber} | Division: ${student.divisionId}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              size: isTablet ? 32 : 28,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    StudentModel student,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStudentStats(student, databaseService),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ??
            {'courses': 0, 'assignments': 0, 'quizzes': 0, 'attendance': 0.0};

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Courses',
                stats['courses'].toString(),
                Icons.book,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Assignments',
                stats['assignments'].toString(),
                Icons.assignment,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Quizzes',
                stats['quizzes'].toString(),
                Icons.quiz,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Attendance',
                '${stats['attendance'].toStringAsFixed(1)}%',
                Icons.check_circle,
                isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isTablet ? 32 : 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 12 : 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    StudentModel student,
    bool isTablet,
  ) {
    final actions = [
      {
        'title': 'Course Materials',
        'icon': Icons.book,
        'color': Colors.blue,
        'onTap': () => _navigateToCourses(context, student),
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment,
        'color': Colors.orange,
        'onTap': () => _navigateToAssignments(context, student),
      },
      {
        'title': 'Quizzes',
        'icon': Icons.quiz,
        'color': Colors.red,
        'onTap': () => _navigateToQuizzes(context, student),
      },
      {
        'title': 'Attendance',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'onTap': () => _navigateToAttendance(context, student),
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign,
        'color': Colors.purple,
        'onTap': () => _navigateToAnnouncements(context, student),
      },
      {
        'title': 'Profile',
        'icon': Icons.person,
        'color': Colors.indigo,
        'onTap': () => _navigateToProfile(context, student),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          size: isTablet ? 28 : 24,
                          color: action['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentAnnouncements(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Announcements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToAnnouncements(context, student),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<AnnouncementModel>>(
            stream: databaseService.getAnnouncementsForStudent(
              student.divisionId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No announcements yet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final announcements = snapshot.data!.take(3).toList();
              return Column(
                children:
                    announcements
                        .map(
                          (announcement) =>
                              _buildAnnouncementItem(announcement),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAssignments(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Assignments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToAssignments(context, student),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<AssignmentModel>>(
            stream: databaseService.getClassAssignments(student.divisionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No assignments yet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final assignments =
                  snapshot.data!
                      .where((a) => a.dueDate.isAfter(DateTime.now()))
                      .take(3)
                      .toList();

              if (assignments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming assignments',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children:
                    assignments.map((assignment) {
                      final isUrgent =
                          assignment.dueDate
                              .difference(DateTime.now())
                              .inDays <=
                          2;
                      return _buildTaskItem(
                        assignment.title,
                        'Due ${DateFormat('MMM dd, yyyy').format(assignment.dueDate)}',
                        isUrgent ? Colors.red : Colors.orange,
                        isUrgent: isUrgent,
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCourses(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToCourses(context, student),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<CourseModel>>(
            stream: databaseService.getClassCourses(student.divisionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No courses available yet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final courses = snapshot.data!.take(3).toList();
              return Column(
                children:
                    courses.map((course) {
                      return _buildCourseItem(course);
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview(
    StudentModel student,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<AttendanceModel>>(
            stream: databaseService.getStudentAttendance(
              student.divisionId,
              student.uid,
            ),
            builder: (context, snapshot) {
              double attendancePercentage = 0.0;
              int present = 0;
              int total = 0;
              int absent = 0;

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                total = snapshot.data!.length;
                for (final record in snapshot.data!) {
                  final status = record.studentAttendance[student.uid];
                  // FIXED: Properly handle AttendanceStatus enum instead of bool
                  if (status == AttendanceStatus.present) {
                    present++;
                  } else {
                    absent++;
                  }
                }
                attendancePercentage =
                    total > 0 ? (present / total) * 100 : 0.0;
              }

              return Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: total > 0 ? attendancePercentage / 100 : 0,
                            strokeWidth: 8,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${attendancePercentage.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Present',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAttendanceDetail(
                        'Present',
                        present.toString(),
                        Colors.green,
                      ),
                      _buildAttendanceDetail(
                        'Absent',
                        absent.toString(),
                        Colors.red,
                      ),
                      _buildAttendanceDetail(
                        'Total',
                        total.toString(),
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentQuizzes(
    StudentModel student,
    DatabaseService databaseService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Quiz Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToQuizzes(context, student),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<QuizModel>>(
            stream: databaseService.getQuizzesByDivision(student.divisionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No quiz results yet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final quizzes = snapshot.data!.take(3).toList();
              return Column(
                children:
                    quizzes.map((quiz) {
                      return _buildQuizResultItem(
                        quiz.title,
                        'Pending',
                        Colors.grey,
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementItem(AnnouncementModel announcement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  announcement.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  DateFormat(
                    'MMM dd, yyyy - HH:mm',
                  ).format(announcement.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(CourseModel course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.book, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  course.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '${course.materials.length} materials',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    String title,
    String dueDate,
    Color color, {
    bool isUrgent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isUrgent ? Border.all(color: color, width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  dueDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isUrgent) Icon(Icons.priority_high, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResultItem(String title, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getStudentStats(
    StudentModel student,
    DatabaseService databaseService,
  ) async {
    try {
      final assignments =
          await databaseService.getClassAssignments(student.divisionId).first;
      final quizzes =
          await databaseService.getQuizzesByDivision(student.divisionId).first;
      final attendance =
          await databaseService
              .getStudentAttendance(student.divisionId, student.uid)
              .first;

      // FIXED: Properly handle AttendanceStatus enum
      double attendancePercentage = 0.0;
      if (attendance.isNotEmpty) {
        int present = 0;
        for (final record in attendance) {
          final status = record.studentAttendance[student.uid];
          if (status == AttendanceStatus.present) {
            present++;
          }
        }
        attendancePercentage = (present / attendance.length) * 100;
      }

      return {
        'courses': 1,
        'assignments': assignments.length,
        'quizzes': quizzes.length,
        'attendance': attendancePercentage,
      };
    } catch (e) {
      print('Error getting student stats: $e');
      return {'courses': 0, 'assignments': 0, 'quizzes': 0, 'attendance': 0.0};
    }
  }

  void _navigateToCourses(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentCoursesScreen(
              student: student,
              divisionId: student.divisionId,
            ),
      ),
    );
  }

  void _navigateToAssignments(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAssignmentsScreen(student: student),
      ),
    );
  }

  void _navigateToQuizzes(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentQuizzesScreen(student: student),
      ),
    );
  }

  void _navigateToAttendance(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAttendanceScreen(student: student),
      ),
    );
  }

  void _navigateToAnnouncements(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentAnnouncementsScreen(student: student),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentProfileScreen(student: student),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Notifications'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.assignment),
                  title: Text('New assignment posted'),
                  subtitle: Text('Math Assignment - Due Monday'),
                ),
                ListTile(
                  leading: Icon(Icons.quiz),
                  title: Text('Quiz results available'),
                  subtitle: Text('Science Quiz 2 - You scored 92%'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showProfile(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );

    databaseService.getStudentById(authService.currentUser!.uid).then((
      student,
    ) {
      if (student != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentProfileScreen(student: student),
          ),
        );
      }
    });
  }
}
