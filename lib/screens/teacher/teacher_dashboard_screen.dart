import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramshiksha/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/responsive_helper.dart';
import '../courses/course_content_screen.dart';
import '../assignments/assignment_management_screen.dart';
import '../announcements/announcement_management_screen.dart';
import '../attendance/attendance_management_screen.dart';
import '../quizzes/quiz_management_screen.dart';
import '../classes/class_management_screen.dart';
import '../students/student_management_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
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
        title: const Text('Teacher Dashboard'),
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
                builder: (context) => AlertDialog(
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
                  // Use pushReplacement instead of pushNamedAndRemoveUntil
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<TeacherModel?>(
        future: databaseService.getTeacher(authService.currentUser!.uid),
        builder: (context, snapshot) {
          print(
              'TeacherDashboard: FutureBuilder state: ${snapshot.connectionState}');
          print('TeacherDashboard: Has data: ${snapshot.hasData}');
          print('TeacherDashboard: Has error: ${snapshot.hasError}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('TeacherDashboard: Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error loading teacher data'),
                  Text('${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            print(
                'TeacherDashboard: No teacher data found for uid: ${authService.currentUser!.uid}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, color: Colors.orange, size: 48),
                  SizedBox(height: 16),
                  Text('Teacher data not found'),
                  Text('UID: ${authService.currentUser!.uid}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final teacher = snapshot.data!;
          print(
              'TeacherDashboard: Teacher loaded: ${teacher.name}, UID: ${teacher.uid}');
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
                    _buildWelcomeHeader(teacher, isTablet),
                    const SizedBox(height: 24),
                    _buildQuickStats(teacher, databaseService, isTablet),
                    const SizedBox(height: 24),
                    _buildQuickActions(context, isTablet),
                    const SizedBox(height: 24),
                    if (isDesktop) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildRecentActivity(
                              teacher,
                              databaseService,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildUpcomingTasks(
                              teacher,
                              databaseService,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildRecentActivity(teacher, databaseService),
                      const SizedBox(height: 24),
                      _buildUpcomingTasks(teacher, databaseService),
                    ],
                    const SizedBox(height: 24),
                    _buildAttendanceChart(teacher, databaseService, isTablet),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(TeacherModel teacher, bool isTablet) {
    final now = DateTime.now();
    final greeting = now.hour < 12
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
                  '$greeting, ${teacher.name}!',
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
                if (teacher.subject != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Subject: ${teacher.subject}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
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
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return FutureBuilder<Map<String, int>>(
      future: _getTeacherStats(teacher, databaseService),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {'classes': 0, 'students': 0, 'assignments': 0, 'quizzes': 0};

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Classes',
                stats['classes']!,
                Icons.class_,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Students',
                stats['students']!,
                Icons.people,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Assignments',
                stats['assignments']!,
                Icons.assignment,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Quizzes',
                stats['quizzes']!,
                Icons.quiz,
                isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, bool isTablet) {
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
            value.toString(),
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isTablet) {
    final actions = [
      {
        'title': 'Course Content',
        'icon': Icons.book,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CourseContentScreen()),
            ),
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment,
        'color': Colors.orange,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AssignmentManagementScreen(),
              ),
            ),
      },
      {
        'title': 'Announcements',
        'icon': Icons.campaign,
        'color': Colors.green,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnnouncementManagementScreen(),
              ),
            ),
      },
      {
        'title': 'Attendance',
        'icon': Icons.check_circle,
        'color': Colors.purple,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AttendanceManagementScreen(),
              ),
            ),
      },
      {
        'title': 'Quizzes',
        'icon': Icons.quiz,
        'color': Colors.red,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuizManagementScreen()),
            ),
      },
      {
        'title': 'Classes',
        'icon': Icons.class_,
        'color': Colors.teal,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassManagementScreen()),
            ),
      },
      {
        'title': 'Students',
        'icon': Icons.people,
        'color': Colors.brown,
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StudentManagementScreen(),
              ),
            ),
      },
      {
        'title': 'Reports',
        'icon': Icons.analytics,
        'color': Colors.indigo,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports feature coming soon!')),
            ),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
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
                          size: isTablet ? 32 : 28,
                          color: action['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action['title'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
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

  Widget _buildRecentActivity(
    TeacherModel teacher,
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
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full activity log
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRecentActivity(teacher, databaseService),
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
                        Icons.history,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activity',
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

              final activities = snapshot.data!.take(3).toList();
              return Column(
                children: activities.map((activity) {
                  return _buildActivityItem(
                    activity['title'] as String,
                    activity['time'] as String,
                    activity['icon'] as IconData,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
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
              icon,
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
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  time,
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
    );
  }

  Widget _buildUpcomingTasks(
    TeacherModel teacher,
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
          Text(
            'Upcoming Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getUpcomingTasks(teacher, databaseService),
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
                        Icons.task_alt,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No upcoming tasks',
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

              final tasks = snapshot.data!.take(3).toList();
              return Column(
                children: tasks.map((task) {
                  return _buildTaskItem(
                    task['title'] as String,
                    task['dueDate'] as String,
                    task['color'] as Color,
                    isUrgent: task['isUrgent'] as bool,
                  );
                }).toList(),
              );
            },
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

  Widget _buildAttendanceChart(
    TeacherModel teacher,
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
            'Weekly Attendance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<AttendanceModel>>(
              future: _getWeeklyAttendanceData(teacher, databaseService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error loading attendance data',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final attendanceData = snapshot.data ?? [];
                final spots = _calculateWeeklyAttendanceSpots(attendanceData);

                // Check if we have any real data
                final hasRealData = spots.any((spot) => spot.y > 0);

                if (!hasRealData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No attendance data for this week',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mark attendance to see the chart',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).dividerColor,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).dividerColor,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final days = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ];
                            if (value.toInt() >= 0 &&
                                value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor:
                                  Theme.of(context).colorScheme.primary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            Theme.of(context).colorScheme.surface,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            return LineTooltipItem(
                              '${touchedSpot.y.toStringAsFixed(1)}%',
                              TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<AttendanceModel>>(
            future: _getWeeklyAttendanceData(teacher, databaseService),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }

              final attendanceData = snapshot.data ?? [];
              final spots = _calculateWeeklyAttendanceSpots(attendanceData);

              if (spots.isEmpty || !spots.any((spot) => spot.y > 0)) {
                return const SizedBox();
              }

              return _buildWeeklyStats(spots);
            },
          ),
        ],
      ),
    );
  }

  Future<List<AttendanceModel>> _getWeeklyAttendanceData(
    TeacherModel teacher,
    DatabaseService databaseService,
  ) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      List<AttendanceModel> allAttendanceRecords = [];

      // Get attendance records for all teacher's classes in the current week
      for (final classId in teacher.classIds) {
        try {
          // Use getDivisionAttendance if available, otherwise fallback
          final divisionAttendance = await _getDivisionAttendanceFallback(
            databaseService,
            classId,
          );

          final weeklyRecords = divisionAttendance.where((record) {
            return record.date.isAfter(
                  startOfWeek.subtract(const Duration(days: 1)),
                ) &&
                record.date.isBefore(
                  endOfWeek.add(const Duration(days: 1)),
                );
          }).toList();

          allAttendanceRecords.addAll(weeklyRecords);
        } catch (e) {
          print('Error getting attendance for class $classId: $e');
        }
      }

      return allAttendanceRecords;
    } catch (e) {
      print('Error in _getWeeklyAttendanceData: $e');
      return [];
    }
  }

  // Fallback method to get division attendance
  Future<List<AttendanceModel>> _getDivisionAttendanceFallback(
    DatabaseService databaseService,
    String divisionId,
  ) async {
    try {
      // Try to get all attendance records and filter by division
      final allAttendance = await databaseService.getAllAttendanceRecords();
      return allAttendance
          .where((record) => record.divisionId == divisionId)
          .toList();
    } catch (e) {
      print('Error in fallback attendance method: $e');
      return [];
    }
  }

  List<FlSpot> _calculateWeeklyAttendanceSpots(
    List<AttendanceModel> attendanceRecords,
  ) {
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // For each day of the week (Monday to Sunday)
    for (int day = 0; day < 7; day++) {
      final currentDay = startOfWeek.add(Duration(days: day));
      double dayAttendancePercentage = 0.0;

      // Get records for this specific day
      final dayRecords = attendanceRecords.where((record) {
        return record.date.year == currentDay.year &&
            record.date.month == currentDay.month &&
            record.date.day == currentDay.day;
      }).toList();

      if (dayRecords.isNotEmpty) {
        // Calculate average attendance percentage for the day across all classes
        double totalPercentage = 0.0;
        int validRecords = 0;

        for (final record in dayRecords) {
          final totalStudents = record.studentAttendance.length;
          if (totalStudents > 0) {
            final presentCount = record.studentAttendance.values
                .where((status) => status == AttendanceStatus.present)
                .length;
            final percentage = (presentCount / totalStudents) * 100;
            totalPercentage += percentage;
            validRecords++;
          }
        }

        if (validRecords > 0) {
          dayAttendancePercentage = totalPercentage / validRecords;
        }
      }

      spots.add(FlSpot(day.toDouble(), dayAttendancePercentage));
    }

    return spots;
  }

  Widget _buildWeeklyStats(List<FlSpot> spots) {
    final currentWeekAverage =
        spots.map((spot) => spot.y).reduce((a, b) => a + b) / spots.length;
    final maxDay = spots.reduce((a, b) => a.y > b.y ? a : b);
    final minDay = spots.reduce((a, b) => a.y < b.y ? a : b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Statistics',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Weekly Avg',
                '${currentWeekAverage.toStringAsFixed(1)}%',
                Icons.trending_up,
                _getPercentageColor(currentWeekAverage),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Best Day',
                '${days[maxDay.x.toInt()]}\n${maxDay.y.toStringAsFixed(1)}%',
                Icons.arrow_upward,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatItem(
                'Needs Attention',
                '${days[minDay.x.toInt()]}\n${minDay.y.toStringAsFixed(1)}%',
                Icons.arrow_downward,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }

  Future<Map<String, int>> _getTeacherStats(
    TeacherModel teacher,
    DatabaseService databaseService,
  ) async {
    try {
      print('Getting teacher stats for: ${teacher.name}');
      print('Teacher classIds: ${teacher.classIds}');
      print('Teacher divisionId: ${teacher.divisionId}');

      int totalStudents = 0;
      int totalAssignments = 0;
      int totalQuizzes = 0;
      int totalClasses = 0;

      // First, try to get data using teacher's UID directly
      try {
        final teacherAssignments =
            await databaseService.getTeacherAssignments(teacher.uid).first;
        totalAssignments += teacherAssignments.length;
        print('Found ${teacherAssignments.length} assignments by teacher UID');

        final teacherQuizzes =
            await databaseService.getTeacherQuizzes(teacher.uid).first;
        totalQuizzes += teacherQuizzes.length;
        print('Found ${teacherQuizzes.length} quizzes by teacher UID');

        final teacherClasses =
            await databaseService.getTeacherClasses(teacher.uid).first;
        totalClasses = teacherClasses.length;
        print('Found ${teacherClasses.length} classes by teacher UID');

        // Get students from teacher's classes
        for (final classModel in teacherClasses) {
          final students = await databaseService
              .getStudentsByDivision(classModel.divisionId)
              .first;
          totalStudents += students.length;
        }
      } catch (e) {
        print('Error getting data by teacher UID: $e');
      }

      // If teacher has divisionId, get data from that division
      if (teacher.divisionId != null && teacher.divisionId!.isNotEmpty) {
        try {
          final students = await databaseService
              .getStudentsByDivision(teacher.divisionId!)
              .first;
          totalStudents += students.length;
          print('Found ${students.length} students in teacher division');

          final assignments = await databaseService
              .getAssignmentsByDivision(teacher.divisionId!)
              .first;
          totalAssignments += assignments.length;
          print('Found ${assignments.length} assignments in teacher division');

          final quizzes = await databaseService
              .getQuizzesByDivision(teacher.divisionId!)
              .first;
          totalQuizzes += quizzes.length;
          print('Found ${quizzes.length} quizzes in teacher division');

          if (totalClasses == 0)
            totalClasses = 1; // At least one class if has division
        } catch (e) {
          print(
              'Error getting stats for teacher division ${teacher.divisionId}: $e');
        }
      }

      // If classIds array is populated, use that as well
      for (final classId in teacher.classIds) {
        try {
          // Get students in this class
          final students =
              await databaseService.getStudentsByDivision(classId).first;
          totalStudents += students.length;

          // Get assignments for this class
          final assignments =
              await databaseService.getAssignmentsByDivision(classId).first;
          totalAssignments += assignments.length;

          // Get quizzes for this class
          final quizzes =
              await databaseService.getQuizzesByDivision(classId).first;
          totalQuizzes += quizzes.length;
        } catch (e) {
          print('Error getting stats for class $classId: $e');
        }
      }

      final stats = {
        'classes': totalClasses > 0 ? totalClasses : teacher.classIds.length,
        'students': totalStudents,
        'assignments': totalAssignments,
        'quizzes': totalQuizzes,
      };

      print('Final teacher stats: $stats');
      return stats;
    } catch (e) {
      print('Error in _getTeacherStats: $e');
      // Fallback to basic data if there's an error
      return {
        'classes': teacher.classIds.length,
        'students': 0,
        'assignments': 0,
        'quizzes': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity(
    TeacherModel teacher,
    DatabaseService databaseService,
  ) async {
    try {
      List<Map<String, dynamic>> activities = [];

      // Get recent assignments created by this teacher
      try {
        final assignments =
            await databaseService.getTeacherAssignments(teacher.uid).first;
        final recentAssignments = assignments.take(3).toList();

        for (final assignment in recentAssignments) {
          activities.add({
            'title': 'Assignment "${assignment.title}" created',
            'time': _getTimeAgo(_parseDateTime(assignment.createdAt)),
            'icon': Icons.assignment,
          });
        }
      } catch (e) {
        print('Error getting teacher assignments: $e');
      }

      // Get recent quizzes created by this teacher
      try {
        final quizzes =
            await databaseService.getTeacherQuizzes(teacher.uid).first;
        final recentQuizzes = quizzes.take(3).toList();

        for (final quiz in recentQuizzes) {
          activities.add({
            'title': 'Quiz "${quiz.title}" created',
            'time': _getTimeAgo(_parseDateTime(quiz.createdAt)),
            'icon': Icons.quiz,
          });
        }
      } catch (e) {
        print('Error getting teacher quizzes: $e');
      }

      // If teacher has divisionId, get recent announcements from that division
      if (teacher.divisionId != null && teacher.divisionId!.isNotEmpty) {
        try {
          final announcements = await databaseService
              .getAnnouncementsByDivision(teacher.divisionId!)
              .first;
          final recentAnnouncements = announcements.take(2).toList();

          for (final announcement in recentAnnouncements) {
            activities.add({
              'title': 'Announcement "${announcement.title}" published',
              'time': _getTimeAgo(_parseDateTime(announcement.createdAt)),
              'icon': Icons.campaign,
            });
          }
        } catch (e) {
          print('Error getting announcements: $e');
        }
      }

      // Also check classIds for additional activity
      for (final classId in teacher.classIds) {
        try {
          final announcements =
              await databaseService.getAnnouncementsByDivision(classId).first;
          final recentAnnouncements = announcements.take(1).toList();

          for (final announcement in recentAnnouncements) {
            activities.add({
              'title': 'Class announcement "${announcement.title}" published',
              'time': _getTimeAgo(_parseDateTime(announcement.createdAt)),
              'icon': Icons.campaign,
            });
          }
        } catch (e) {
          print('Error getting activity for class $classId: $e');
        }
      }

      // Sort by most recent and take top activities
      activities.sort((a, b) {
        // Sort by time - this is simplified, you might want to use actual DateTime objects
        return b['time'].toString().compareTo(a['time'].toString());
      });

      return activities.take(5).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }

  // Helper method to parse DateTime from dynamic types (Timestamp, int, or DateTime)
  DateTime _parseDateTime(dynamic dateTime) {
    try {
      if (dateTime is DateTime) {
        return dateTime;
      } else if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateTime);
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else {
        return DateTime.now();
      }
    } catch (e) {
      print('Error parsing date time: $e');
      return DateTime.now();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Future<List<Map<String, dynamic>>> _getUpcomingTasks(
    TeacherModel teacher,
    DatabaseService databaseService,
  ) async {
    try {
      List<Map<String, dynamic>> tasks = [];
      final now = DateTime.now();

      // Get assignments created by this teacher with upcoming due dates
      try {
        final assignments =
            await databaseService.getTeacherAssignments(teacher.uid).first;

        for (final assignment in assignments) {
          final dueDate = _parseDateTime(assignment.dueDate);
          if (dueDate.isAfter(now)) {
            final daysDifference = dueDate.difference(now).inDays;
            final isUrgent = daysDifference <= 2;

            tasks.add({
              'title': 'Assignment "${assignment.title}" due',
              'dueDate': daysDifference == 0
                  ? 'Due today'
                  : daysDifference == 1
                      ? 'Due tomorrow'
                      : 'Due in $daysDifference days',
              'color': isUrgent ? Colors.red : Colors.orange,
              'isUrgent': isUrgent,
            });
          }
        }
      } catch (e) {
        print('Error getting teacher assignments for tasks: $e');
      }

      // Get quizzes created by this teacher
      try {
        final quizzes =
            await databaseService.getTeacherQuizzes(teacher.uid).first;
        for (final quiz in quizzes.take(3)) {
          tasks.add({
            'title': 'Review submissions for "${quiz.title}"',
            'dueDate': 'Ongoing',
            'color': Colors.blue,
            'isUrgent': false,
          });
        }
      } catch (e) {
        print('Error getting teacher quizzes for tasks: $e');
      }

      // If teacher has divisionId, get upcoming assignments from division
      if (teacher.divisionId != null && teacher.divisionId!.isNotEmpty) {
        try {
          final assignments = await databaseService
              .getAssignmentsByDivision(teacher.divisionId!)
              .first;

          for (final assignment in assignments.take(2)) {
            final dueDate = _parseDateTime(assignment.dueDate);
            if (dueDate.isAfter(now)) {
              final daysDifference = dueDate.difference(now).inDays;
              final isUrgent = daysDifference <= 2;

              tasks.add({
                'title': 'Check submissions: "${assignment.title}"',
                'dueDate': daysDifference == 0
                    ? 'Due today'
                    : daysDifference == 1
                        ? 'Due tomorrow'
                        : 'Due in $daysDifference days',
                'color': isUrgent ? Colors.orange : Colors.green,
                'isUrgent': isUrgent,
              });
            }
          }
        } catch (e) {
          print('Error getting division assignments for tasks: $e');
        }
      }

      // Also check classIds for additional tasks
      for (final classId in teacher.classIds.take(2)) {
        try {
          final assignments =
              await databaseService.getAssignmentsByDivision(classId).first;

          for (final assignment in assignments.take(1)) {
            final dueDate = _parseDateTime(assignment.dueDate);
            if (dueDate.isAfter(now)) {
              final daysDifference = dueDate.difference(now).inDays;
              final isUrgent = daysDifference <= 2;

              tasks.add({
                'title': 'Grade "${assignment.title}"',
                'dueDate': daysDifference == 0
                    ? 'Due today'
                    : daysDifference == 1
                        ? 'Due tomorrow'
                        : 'Due in $daysDifference days',
                'color': isUrgent ? Colors.red : Colors.purple,
                'isUrgent': isUrgent,
              });
            }
          }
        } catch (e) {
          print('Error getting tasks for class $classId: $e');
        }
      }

      // Sort by urgency and due date
      tasks.sort((a, b) {
        if (a['isUrgent'] != b['isUrgent']) {
          return (b['isUrgent'] as bool) ? 1 : -1; // Urgent tasks first
        }
        return 0;
      });

      return tasks.take(5).toList();
    } catch (e) {
      print('Error getting upcoming tasks: $e');
      return [];
    }
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('New assignment submission'),
              subtitle: Text('John Doe submitted Math Assignment 1'),
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Parent inquiry'),
              subtitle: Text('Parent of Sarah Smith sent a message'),
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
    // Navigate to profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile feature coming soon!')),
    );
  }
}
