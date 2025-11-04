import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/class_model.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../assignments/assignment_management_screen.dart';
import '../quizzes/quiz_management_screen.dart';
import '../attendance/attendance_management_screen.dart';
import '../announcements/announcement_management_screen.dart';
import '../courses/course_content_screen.dart';
import '../classes/class_management_screen.dart';
import '../students/student_management_screen.dart';
import '../students/student_list_screen_placeholder.dart' as placeholder;
import '../reports/reports_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TeacherDashboardScreen(),
    const ClassManagementScreen(),
    const StudentManagementScreen(),
  ];

  final List<DrawerItem> _drawerItems = [
    DrawerItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      index: 0,
    ),
    DrawerItem(
      title: 'Classes',
      icon: Icons.class_outlined,
      selectedIcon: Icons.class_,
      index: 1,
    ),
    DrawerItem(
      title: 'Students',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      index: 2,
    ),
  ];

  final List<DrawerItem> _additionalItems = [
    DrawerItem(
      title: 'Courses',
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
      index: -1,
      screen: CourseContentScreen(),
    ),
    DrawerItem(
      title: 'Assignments',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      index: -2,
      screen: AssignmentManagementScreen(),
    ),
    DrawerItem(
      title: 'Quizzes',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
      index: -3,
      screen: QuizManagementScreen(),
    ),
    DrawerItem(
      title: 'Attendance',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      index: -4,
      screen: AttendanceManagementScreen(),
    ),
    DrawerItem(
      title: 'Announcements',
      icon: Icons.announcement_outlined,
      selectedIcon: Icons.announcement,
      index: -5,
      screen: AnnouncementManagementScreen(),
    ),
    DrawerItem(
      title: 'Reports',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      index: -6,
      screen: ReportsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          appBar:
              isDesktop
                  ? null
                  : AppBar(
                    title: const Text('Teacher Portal'),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () {},
                        tooltip: 'Profile',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await authService.signOut();
                        },
                        tooltip: 'Logout',
                        color: Colors.red.shade600,
                      ),
                    ],
                  ),
          // drawer: isDesktop ? null : _buildDrawer(authService),
          body: Row(
            children: [
              if (isDesktop)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  // child: _buildDrawer(authService),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              isDesktop
                  ? null
                  : NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.class_outlined),
                        selectedIcon: Icon(Icons.class_),
                        label: 'Classes',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: 'Students',
                      ),
                    ],
                  ),
        );
      },
    );
  }

  // Widget _buildDrawer(AuthService authService) {
  //   return Drawer(
  //     elevation: 0,
  //     backgroundColor: Theme.of(context).colorScheme.surface,
  //     child: Column(
  //       children: [
  //         DrawerHeader(
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [
  //                 Theme.of(context).colorScheme.primary,
  //                 Theme.of(context).colorScheme.primary.withOpacity(0.8),
  //               ],
  //             ),
  //           ),
  //           child: Row(
  //             children: [
  //               CircleAvatar(
  //                 radius: 30,
  //                 backgroundColor: Colors.white,
  //                 child: Icon(Icons.school, size: 35, color: Colors.blueAccent),
  //               ),
  //               const SizedBox(width: 16),
  //               const Expanded(
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Gramshikshika',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 22,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     Text(
  //                       'Teacher Portal',
  //                       style: TextStyle(color: Colors.white70),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Expanded(
  //           child: ListView(
  //             padding: EdgeInsets.zero,
  //             children: [
  //               ..._drawerItems.map(_buildDrawerTile),
  //               const Divider(),
  //               ..._additionalItems.map(_buildDrawerTile),
  //               const Divider(),
  //               ListTile(
  //                 leading: Icon(
  //                   Icons.settings_outlined,
  //                   color: Colors.grey[700],
  //                 ),
  //                 title: const Text('Settings'),
  //                 onTap: () {},
  //               ),
  //               ListTile(
  //                 leading: const Icon(Icons.logout, color: Colors.red),
  //                 title: const Text(
  //                   'Logout',
  //                   style: TextStyle(color: Colors.red),
  //                 ),
  //                 onTap: () async {
  //                   await authService.signOut();
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildDrawer(AuthService authService) {
  //   return Drawer(
  //     elevation: 0,
  //     backgroundColor: Theme.of(context).colorScheme.surface,
  //     child: SafeArea(
  //       child: Column(
  //         children: [
  //           // Flexible header to avoid overflow
  //           Container(
  //             width: double.infinity,
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [
  //                   Theme.of(context).colorScheme.primary,
  //                   Theme.of(context).colorScheme.primary.withOpacity(0.85),
  //                 ],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //             ),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.center,
  //               children: [
  //                 CircleAvatar(
  //                   radius: 28,
  //                   backgroundColor: Colors.white,
  //                   child: Icon(
  //                     Icons.school,
  //                     size: 32,
  //                     color: Theme.of(context).colorScheme.primary,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 // Expanded(
  //                 //   child: Column(
  //                 //     crossAxisAlignment: CrossAxisAlignment.start,
  //                 //     mainAxisAlignment: MainAxisAlignment.center,
  //                 //     children: [
  //                 //       Text(
  //                 //         'Gramshikshika',
  //                 //         style: Theme.of(
  //                 //           context,
  //                 //         ).textTheme.titleLarge?.copyWith(
  //                 //           color: Colors.white,
  //                 //           fontWeight: FontWeight.bold,
  //                 //         ),
  //                 //       ),
  //                 //       Text(
  //                 //         'Teacher Portal',
  //                 //         style: Theme.of(context).textTheme.bodyMedium
  //                 //             ?.copyWith(color: Colors.white70),
  //                 //       ),
  //                 //     ],
  //                 //   ),
  //                 // ),
  //               ],
  //             ),
  //           ),

  //           // Scrollable content
  //           Expanded(
  //             child: ListView(
  //               padding: EdgeInsets.zero,
  //               // children: [
  //               //   const SizedBox(height: 4),
  //               //   ..._drawerItems.map(_buildDrawerTile),
  //               //   const Divider(),
  //               //   ..._additionalItems.map(_buildDrawerTile),
  //               //   const Divider(),
  //               //   ListTile(
  //               //     leading: Icon(
  //               //       Icons.settings_outlined,
  //               //       color: Colors.grey[700],
  //               //     ),
  //               //     title: const Text('Settings'),
  //               //     onTap: () {},
  //               //   ),
  //               //   ListTile(
  //               //     leading: const Icon(Icons.logout, color: Colors.red),
  //               //     title: const Text(
  //               //       'Logout',
  //               //       style: TextStyle(color: Colors.red),
  //               //     ),
  //               //     onTap: () async {
  //               //       await authService.signOut();
  //               //     },
  //               //   ),
  //               //   const SizedBox(height: 20),
  //               // ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDrawerTile(DrawerItem item) {
    final isSelected = _selectedIndex == item.index;
    return ListTile(
      leading: Icon(
        isSelected ? item.selectedIcon : item.icon,
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700],
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        Navigator.pop(context);
        if (item.index >= 0) {
          setState(() => _selectedIndex = item.index);
        } else if (item.screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item.screen!),
          );
        }
      },
    );
  }
}

class DrawerItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final Widget? screen;

  DrawerItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.index,
    this.screen,
  });
}

// ----------------------------------------------------------------------
// Teacher Dashboard - Modern, Responsive Layout
// ----------------------------------------------------------------------

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin {
  late AnimationController _welcomeAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _totalQuizzes = 0;
  int _totalAssignments = 0;

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
    _loadTeacherStats();
  }

  Future<void> _loadTeacherStats() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(
        context,
        listen: false,
      );
      final teacherId = authService.currentUser!.uid;

      // Get real counts from database
      final quizzes = await databaseService.getTeacherQuizzes(teacherId).first;
      final assignments =
          await databaseService.getTeacherAssignments(teacherId).first;

      if (mounted) {
        setState(() {
          _totalQuizzes = quizzes.length;
          _totalAssignments = assignments.length;
        });
      }
    } catch (e) {
      // Handle error silently or show a message
      print('Error loading teacher stats: $e');
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

    return StreamBuilder<List<ClassModel>>(
      stream: databaseService.getTeacherClasses(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 3));
        }
        final classes = snapshot.data ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Welcome Card with Animation
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 400;

                              return Padding(
                                padding: EdgeInsets.all(isCompact ? 16 : 24),
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
                                        backgroundColor: Colors.white
                                            .withOpacity(0.2),
                                        backgroundImage: const NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=teacher&backgroundColor=transparent&accessories=eyepatch,wayfarers,prescription01&clothingGraphic=skullOutline,skull',
                                        ),
                                        onBackgroundImageError: (_, __) {},
                                        child: Icon(
                                          Icons.person,
                                          size: isCompact ? 36 : 42,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 12 : 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Hello Teacher!",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isCompact ? 18 : null,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            authService.currentUser!.email ??
                                                'Teacher',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontSize: isCompact ? 14 : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: isCompact ? 4 : 6),
                                          Text(
                                            "Ready to inspire minds today?",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: isCompact ? 12 : null,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Responsive Grid Layout for Main Actions
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _cardAnimationController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quick Actions",
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Determine grid layout based on screen width
                              final isSmallScreen = constraints.maxWidth < 400;
                              final crossAxisCount = isSmallScreen ? 1 : 2;
                              final aspectRatio = isSmallScreen ? 2.5 : 1.1;

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: aspectRatio,
                                children: [
                                  _EnhancedActionCard(
                                    title: "Attendance",
                                    subtitle: "Mark & Track",
                                    icon: Icons.check_circle,
                                    color: Colors.green,
                                    onTap:
                                        () => _navigateToScreen(
                                          context,
                                          const AttendanceManagementScreen(),
                                        ),
                                    stats: "Today's Classes",
                                    statsValue: "${classes.length}",
                                  ),
                                  _EnhancedActionCard(
                                    title: "Assignments",
                                    subtitle: "Create & Review",
                                    icon: Icons.assignment,
                                    color: Colors.orange,
                                    onTap:
                                        () => _navigateToScreen(
                                          context,
                                          const AssignmentManagementScreen(),
                                        ),
                                    stats: "Total Assignments",
                                    statsValue: "$_totalAssignments",
                                  ),
                                  _EnhancedActionCard(
                                    title: "Marks",
                                    subtitle: "Grade & Analyze",
                                    icon: Icons.grade,
                                    color: Colors.purple,
                                    onTap:
                                        () => _navigateToScreen(
                                          context,
                                          const ReportsScreen(),
                                        ),
                                    stats: "Latest Scores",
                                    statsValue: "85%",
                                  ),
                                  _EnhancedActionCard(
                                    title: "Students",
                                    subtitle: "Manage & Monitor",
                                    icon: Icons.people,
                                    color: Colors.blue,
                                    onTap:
                                        () => _navigateToScreen(
                                          context,
                                          const placeholder.StudentListScreen(),
                                        ),
                                    stats: "Total Students",
                                    statsValue:
                                        "${classes.fold<int>(0, (a, c) => a + c.studentIds.length)}",
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Overview Stats
                  Text(
                    "Overview",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 400) {
                        // Stack vertically on small screens
                        return Column(
                          children: [
                            _StatCard(
                              icon: Icons.class_,
                              label: "Classes",
                              value: "${classes.length}",
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            _StatCard(
                              icon: Icons.quiz,
                              label: "Quizzes",
                              value: "$_totalQuizzes",
                              color: Colors.teal,
                            ),
                          ],
                        );
                      } else {
                        // Side by side on larger screens
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.class_,
                                label: "Classes",
                                value: "${classes.length}",
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.quiz,
                                label: "Quizzes",
                                value: "$_totalQuizzes",
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Recent Classes
                  Text(
                    "Your Classes",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ...classes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final classModel = entry.value;
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _EnhancedClassCard(classModel: classModel),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

class _EnhancedActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String stats;
  final String statsValue;

  const _EnhancedActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.stats,
    required this.statsValue,
  });

  @override
  State<_EnhancedActionCard> createState() => _EnhancedActionCardState();
}

class _EnhancedActionCardState extends State<_EnhancedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 8,
            shadowColor: widget.color.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) => _controller.reverse(),
              onTapCancel: () => _controller.reverse(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 120;

                  return Container(
                    padding: EdgeInsets.all(isCompact ? 12 : 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, widget.color.withOpacity(0.05)],
                      ),
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
                                color: widget.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: isCompact ? 18 : 22,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 14,
                            ),
                          ],
                        ),
                        if (!isCompact) const Spacer(),
                        if (isCompact) const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: isCompact ? 14 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            widget.subtitle,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: isCompact ? 11 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: isCompact ? 4 : 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                widget.stats,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: isCompact ? 10 : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.statsValue,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.color,
                                fontSize: isCompact ? 12 : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EnhancedClassCard extends StatelessWidget {
  final ClassModel classModel;

  const _EnhancedClassCard({required this.classModel});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Theme.of(context).colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  classModel.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${classModel.subject} • ${classModel.section}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${classModel.studentIds.length} students",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Active",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 150;

            return Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 8 : 10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: isCompact ? 20 : 22),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 18 : null,
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                              fontSize: isCompact ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
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
