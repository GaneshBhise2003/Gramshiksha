import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/class_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view reports')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReports,
            tooltip: 'Export Reports',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    text: 'Overview',
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'Attendance',
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    text: 'Performance',
                    isSelected: _selectedTab == 2,
                    onTap: () => setState(() => _selectedTab = 2),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOverviewTab(currentUser.uid),
                _buildAttendanceTab(currentUser.uid),
                _buildPerformanceTab(currentUser.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(String teacherId) {
    final databaseService = Provider.of<DatabaseService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Statistics Cards
          StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(teacherId),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final classes = classSnapshot.data ?? [];
              final totalStudents = classes.fold<int>(
                0,
                (sum, classModel) => sum + classModel.studentIds.length,
              );

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    title: 'Total Classes',
                    value: classes.length.toString(),
                    icon: Icons.class_,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Total Students',
                    value: totalStudents.toString(),
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Active Assignments',
                    value: '0', // TODO: Get from database
                    icon: Icons.assignment,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Completed Quizzes',
                    value: '0', // TODO: Get from database
                    icon: Icons.quiz,
                    color: Colors.purple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Class Distribution',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Pie Chart for Class Distribution
          StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(teacherId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final classes = snapshot.data ?? [];

              if (classes.isEmpty) {
                return Card(
                  child: Container(
                    height: 200,
                    child: const Center(child: Text('No classes to display')),
                  ),
                );
              }

              return Card(
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections:
                                classes.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final classModel = entry.value;
                                  final colors = [
                                    Colors.blue,
                                    Colors.green,
                                    Colors.orange,
                                    Colors.purple,
                                    Colors.red,
                                  ];

                                  return PieChartSectionData(
                                    value:
                                        classModel.studentIds.length.toDouble(),
                                    title: '${classModel.studentIds.length}',
                                    color: colors[index % colors.length],
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              classes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final classModel = entry.value;
                                final colors = [
                                  Colors.blue,
                                  Colors.green,
                                  Colors.orange,
                                  Colors.purple,
                                  Colors.red,
                                ];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: colors[index % colors.length],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          classModel.name,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(String teacherId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Attendance Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Coming Soon', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          const Text(
            '• Attendance trends over time\n'
            '• Student attendance patterns\n'
            '• Class-wise attendance comparison\n'
            '• Absenteeism alerts',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(String teacherId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Performance Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text('Coming Soon', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          const Text(
            '• Assignment submission rates\n'
            '• Grade distribution charts\n'
            '• Quiz performance trends\n'
            '• Student progress tracking',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _exportReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
