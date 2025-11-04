import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/announcement_model.dart';
import '../../models/attendance_model.dart';

import '../students/student_quiz_screen.dart';
import '../students/student_assignment_screen.dart';
import '../students/student_course_screen.dart';
import '../student/student_dashboard_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const StudentDashboardScreen(),
      const StudentCourseScreen(),
      const StudentQuizScreen(),
      const StudentAssignmentScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        elevation: 3,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
              color:
                  _selectedIndex == 0
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.book_outlined,
              color:
                  _selectedIndex == 1
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.book,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.quiz_outlined,
              color:
                  _selectedIndex == 2
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.quiz,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.assignment_outlined,
              color:
                  _selectedIndex == 3
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.assignment,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            label: 'Assignments',
          ),
        ],
      ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  late AnimationController _welcomeAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Student Statistics
  double _attendancePercentage = 0.0;
  double _averageScore = 0.0;
  int _completedAssignments = 0;
  int _pendingAssignments = 0;
  int _classRank = 0;

  @override
  void initState() {
    super.initState();
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _welcomeAnimationController.forward();
    _cardAnimationController.forward();
    _loadStudentStats();
  }

  Future<void> _loadStudentStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final studentId = authService.currentUser!.uid;

      // Get student details to find their division and then classes
      final student = await databaseService.getStudentById(studentId);

      if (student != null && student.divisionId.isNotEmpty) {
        // Get classes for this student's division
        final classes = await databaseService.getClassesByDivision(
          student.divisionId,
        );
        if (classes.isNotEmpty) {
          final classId = classes.first.id; // Use first class for stats

          // Get student's attendance records for their class
          final attendanceRecords =
              await databaseService
                  .getStudentAttendance(classId, studentId)
                  .first;

          // Calculate attendance statistics
          int totalClasses = 0;
          int presentClasses = 0;

          for (final record in attendanceRecords) {
            if (record.studentAttendance.containsKey(studentId)) {
              totalClasses++;
              if (record.studentAttendance[studentId] ==
                  AttendanceStatus.present) {
                presentClasses++;
              }
            }
          }

          // Calculate attendance percentage
          double attendancePercentage =
              totalClasses > 0 ? (presentClasses / totalClasses) * 100 : 0.0;

          // For assignments and scores, use placeholder values for now
          // These would need proper quiz/assignment result calculations
          int completedAssignments = 8; // Placeholder
          int pendingAssignments = 2; // Placeholder
          double averageScore = 85.0; // Placeholder
          int classRank = 3; // Placeholder

          if (mounted) {
            setState(() {
              _attendancePercentage = attendancePercentage;
              _averageScore = averageScore;
              _completedAssignments = completedAssignments;
              _pendingAssignments = pendingAssignments;
              _classRank = classRank;
            });
          }
        } else {
          // No classes found for division
          if (mounted) {
            setState(() {
              _attendancePercentage = 0.0;
              _averageScore = 0.0;
              _completedAssignments = 0;
              _pendingAssignments = 0;
              _classRank = 0;
            });
          }
        }
      } else {
        // Student not found or not assigned to a class
        if (mounted) {
          setState(() {
            _attendancePercentage = 0.0;
            _averageScore = 0.0;
            _completedAssignments = 0;
            _pendingAssignments = 0;
            _classRank = 0;
          });
        }
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error loading student stats: $e');
      // Set default values on error
      if (mounted) {
        setState(() {
          _attendancePercentage = 0.0;
          _averageScore = 0.0;
          _completedAssignments = 0;
          _pendingAssignments = 0;
          _classRank = 0;
        });
      }
    }
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  void dispose() {
    _welcomeAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 120,
            title: Text(
              'My Dashboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  icon: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  onPressed: () {
                    _showProfileDialog(context);
                  },
                  tooltip: 'Profile',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton.filledTonal(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  onPressed: () {
                    _showDoubtDialog(context);
                  },
                  tooltip: 'Ask Doubt',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton.filledTonal(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authService.signOut();
                  },
                  tooltip: 'Logout',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 8,
              ),
              child: FutureBuilder<StudentModel?>(
                future: databaseService.getStudentById(
                  authService.currentUser!.uid,
                ),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const _DashboardSkeleton();
                  }

                  if (studentSnapshot.hasError || !studentSnapshot.hasData) {
                    return const _ErrorCard();
                  }

                  final student = studentSnapshot.data!;
                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enhanced Welcome Card
                            _EnhancedWelcomeCard(student: student),
                            const SizedBox(height: 24),

                            // Quick Actions Grid
                            SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Actions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmallScreen =
                                          constraints.maxWidth < 400;
                                      final crossAxisCount =
                                          isSmallScreen ? 1 : 2;
                                      final aspectRatio =
                                          isSmallScreen ? 2.5 : 1.1;

                                      return GridView.count(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: aspectRatio,
                                        children: [
                                          _StudentActionCard(
                                            title: "Assignments",
                                            subtitle: "Submit & View",
                                            icon: Icons.assignment,
                                            color: Colors.orange,
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const StudentAssignmentScreen(),
                                                  ),
                                                ),
                                            count: "3 New",
                                          ),
                                          _StudentActionCard(
                                            title: "Announcements",
                                            subtitle: "Latest Updates",
                                            icon: Icons.campaign,
                                            color: Colors.blue,
                                            onTap: () {
                                              // Navigate to announcements
                                            },
                                            count: "2 Today",
                                          ),
                                          _StudentActionCard(
                                            title: "Offline Material",
                                            subtitle: "Download & Study",
                                            icon: Icons.offline_pin,
                                            color: Colors.green,
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            const StudentDashboardScreen(),
                                                  ),
                                                ),
                                            count: "Available",
                                          ),
                                          _StudentActionCard(
                                            title: "Monthly Report",
                                            subtitle: "Track Progress",
                                            icon: Icons.analytics,
                                            color: Colors.purple,
                                            onTap:
                                                () =>
                                                    _showMonthlyReport(context),
                                            count: "View Now",
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Performance Stats
                            FutureBuilder<String?>(
                              future: databaseService.getStudentPrimaryClassId(
                                student.uid,
                              ),
                              builder: (context, classSnapshot) {
                                final classId = classSnapshot.data ?? '';
                                return _PerformanceStatsGrid(
                                  studentId: student.uid,
                                  classId: classId,
                                  isTablet: isTablet,
                                  attendancePercentage: _attendancePercentage,
                                  averageScore: _averageScore,
                                  completedAssignments: _completedAssignments,
                                  pendingAssignments: _pendingAssignments,
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Student Ranking
                            FutureBuilder<String?>(
                              future: databaseService.getStudentPrimaryClassId(
                                student.uid,
                              ),
                              builder: (context, classSnapshot) {
                                final classId = classSnapshot.data ?? '';
                                return _StudentRanking(
                                  studentId: student.uid,
                                  classId: classId,
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Recent Announcements
                            Text(
                              'Recent Announcements',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _AnnouncementsList(studentId: student.uid),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDoubtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Ask a Doubt'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type your question here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.class_),
                        label: const Text('Ask in Class'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.person),
                        label: const Text('Message Teacher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _showMonthlyReport(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Monthly Report'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _ReportCard(
                    title: 'Attendance',
                    value: '${_attendancePercentage.toStringAsFixed(1)}%',
                    color: Colors.green,
                  ),
                  _ReportCard(
                    title: 'Average Marks',
                    value: '${_averageScore.toStringAsFixed(1)}%',
                    color: Colors.blue,
                  ),
                  _ReportCard(
                    title: 'Rank in Class',
                    value:
                        _classRank > 0
                            ? '${_classRank}${_getOrdinalSuffix(_classRank)}'
                            : 'N/A',
                    color: Colors.orange,
                  ),
                  _ReportCard(
                    title: 'Assignments Completed',
                    value:
                        '$_completedAssignments/${_completedAssignments + _pendingAssignments}',
                    color: Colors.purple,
                  ),
                ],
              ),
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

  static void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Profile'),
            content: const Text('Profile screen coming soon!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

class _EnhancedWelcomeCard extends StatelessWidget {
  final StudentModel student;

  const _EnhancedWelcomeCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isCompact ? 60 : 70,
                height: isCompact ? 60 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: isCompact ? 30 : 35,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: const NetworkImage(
                    'https://api.dicebear.com/7.x/avataaars/png?seed=student&backgroundColor=transparent',
                  ),
                  onBackgroundImageError: (_, __) {},
                  child:
                      student.name.isEmpty
                          ? Icon(
                            Icons.person,
                            color: Colors.white,
                            size: isCompact ? 30 : 36,
                          )
                          : null,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hello Student!',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 18 : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isCompact ? 14 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isCompact ? 6 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 12,
                        vertical: isCompact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school,
                            color: Colors.white,
                            size: isCompact ? 14 : 16,
                          ),
                          SizedBox(width: isCompact ? 4 : 6),
                          Flexible(
                            child: Text(
                              'Roll No: ${student.rollNumber}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isCompact ? 11 : 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String count;

  const _StudentActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 120;

            return Container(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    color.withOpacity(0.08),
                  ],
                ),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 8 : 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8,
                          vertical: isCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          count,
                          style: TextStyle(
                            color: color,
                            fontSize: isCompact ? 9 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isCompact) const Spacer(),
                  if (isCompact) const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: isCompact ? 14 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: isCompact ? 11 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PerformanceStatsGrid extends StatelessWidget {
  final String studentId;
  final String classId;
  final bool isTablet;
  final double attendancePercentage;
  final double averageScore;
  final int completedAssignments;
  final int pendingAssignments;

  const _PerformanceStatsGrid({
    required this.studentId,
    required this.classId,
    required this.isTablet,
    required this.attendancePercentage,
    required this.averageScore,
    required this.completedAssignments,
    required this.pendingAssignments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Performance',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            final crossAxisCount = isSmallScreen ? 1 : 2;
            final aspectRatio = isSmallScreen ? 3.0 : 1.4;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: aspectRatio,
              children: [
                _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Attendance',
                  value: '${attendancePercentage.toStringAsFixed(1)}%',
                  color: const Color(0xFF10B981),
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _StatCard(
                  icon: Icons.grade,
                  label: 'Average Score',
                  value: '${averageScore.toStringAsFixed(1)}%',
                  color: const Color(0xFF3B82F6),
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                _StatCard(
                  icon: Icons.assignment_turned_in,
                  label: 'Completed',
                  value: '$completedAssignments',
                  color: const Color(0xFF10B981),
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
                _StatCard(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  value: '$pendingAssignments',
                  color: const Color(0xFFEF4444),
                  gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentRanking extends StatelessWidget {
  final String studentId;
  final String classId;

  const _StudentRanking({required this.studentId, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber[700],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Rank',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You are performing great!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '3rd',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.analytics, color: color, size: 20),
          ),
          title: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class StudentStats {
  final int averageScore;
  final int completedAssignments;
  final int pendingAssignments;

  StudentStats({
    required this.averageScore,
    required this.completedAssignments,
    required this.pendingAssignments,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  final String studentId;

  const _AnnouncementsList({required this.studentId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<AnnouncementModel>>(
      stream: databaseService.getStudentAnnouncements(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AnnouncementsSkeleton();
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return _EmptyAnnouncements();
        }

        final recentAnnouncements = announcements.take(3).toList();

        return Column(
          children:
              recentAnnouncements.map((announcement) {
                return _AnnouncementCard(announcement: announcement);
              }).toList(),
        );
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAnnouncementDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.campaign,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.content,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(announcement.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(announcement.title)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    announcement.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Posted: ${DateFormat('MMMM dd, yyyy').format(announcement.createdAt)}',
                      ),
                    ],
                  ),
                ],
              ),
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
}

class _EmptyAnnouncements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for updates from your teachers',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Welcome card skeleton
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        // Stats grid skeleton
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.1,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: List.generate(4, (index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnnouncementsSkeleton extends StatelessWidget {
  const _AnnouncementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please check your connection and try again',
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
