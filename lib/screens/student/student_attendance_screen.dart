import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/responsive_helper.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final StudentModel student;

  const StudentAttendanceScreen({super.key, required this.student});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<DateTime, AttendanceStatus> _attendanceData = {};
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final days = <DateTime>[];

    // Add leading days from previous month
    final firstWeekday = first.weekday;
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }

    // Add current month days
    for (int i = 0; i < last.day; i++) {
      days.add(DateTime(month.year, month.month, i + 1));
    }

    // Add trailing days from next month to complete the grid
    final totalCells = 42; // 6 weeks * 7 days
    final remaining = totalCells - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(last.add(Duration(days: i)));
    }

    return days;
  }

  Color _getStatusColor(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  IconData _getStatusIcon(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.absent:
        return Icons.close;
      default:
        return Icons.circle_outlined;
    }
  }

  String _getStatusText(AttendanceStatus? status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      default:
        return 'No Record';
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Calendar', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(databaseService, isTablet),
          _buildCalendarTab(databaseService, isTablet),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(DatabaseService databaseService, bool isTablet) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: databaseService.getStudentAttendance(
        widget.student.divisionId,
        widget.student.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceRecords = snapshot.data ?? [];

        if (attendanceRecords.isEmpty) {
          return _buildEmptyState(
            'No attendance records',
            'Your attendance records will appear here once your teacher starts marking attendance.',
            Icons.person_outline,
          );
        }

        final stats = _calculateAttendanceStats(attendanceRecords);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatisticsSection(stats, isTablet),
                const SizedBox(height: 24),
                _buildMonthlyBreakdown(attendanceRecords, isTablet),
                const SizedBox(height: 24),
                _buildRecentAttendance(attendanceRecords, isTablet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarTab(DatabaseService databaseService, bool isTablet) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: databaseService.getStudentAttendance(
        widget.student.divisionId,
        widget.student.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceRecords = snapshot.data ?? [];
        _updateAttendanceData(attendanceRecords);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend(isTablet),
              const SizedBox(height: 16),
              _buildCalendarHeader(),
              const SizedBox(height: 16),
              _buildCalendarGrid(),
              const SizedBox(height: 24),
              if (_selectedDate != null) _buildSelectedDateDetails(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInMonth(_selectedMonth);
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Weekday headers
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                return Center(
                  child: Text(
                    weekdays[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Calendar days
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final date = daysInMonth[index];
                final isCurrentMonth = date.month == _selectedMonth.month;
                final isToday = _isSameDay(date, DateTime.now());
                final isSelected =
                    _selectedDate != null && _isSameDay(date, _selectedDate!);
                final status = _attendanceData[date];
                final hasRecord = status != null;

                return GestureDetector(
                  onTap: () => _selectDate(date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2)
                              : isToday
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : isToday
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3)
                                : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isCurrentMonth
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                        if (hasRecord) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateDetails() {
    final status =
        _selectedDate != null ? _attendanceData[_selectedDate!] : null;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat(
                              'EEEE, MMMM dd, yyyy',
                            ).format(_selectedDate!)
                            : 'No date selected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 16),
              Text(
                _getStatusDescription(status),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'You were marked present on this day. Great job maintaining your attendance!';
      case AttendanceStatus.late:
        return 'You were marked late on this day. Try to arrive on time to make the most of your learning.';
      case AttendanceStatus.absent:
        return 'You were marked absent on this day. Regular attendance is important for academic success.';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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

  Widget _buildStatisticsSection(Map<String, dynamic> stats, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Statistics',
          style: TextStyle(
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats['percentage'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${stats['present']} present, ${stats['late']} late, ${stats['absent']} absent',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
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
                child: const Icon(
                  Icons.analytics,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Present Days',
                stats['present'].toString(),
                Icons.check_circle,
                Colors.green,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Late Days',
                stats['late'].toString(),
                Icons.schedule,
                Colors.orange,
                isTablet,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Absent Days',
                stats['absent'].toString(),
                Icons.cancel,
                Colors.red,
                isTablet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
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
          Icon(icon, size: isTablet ? 32 : 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildMonthlyBreakdown(List<AttendanceModel> records, bool isTablet) {
    final monthlyData = <String, Map<String, int>>{};

    for (final record in records) {
      final monthKey = DateFormat('MMM yyyy').format(record.date);
      monthlyData[monthKey] ??= {'present': 0, 'absent': 0, 'late': 0};

      final status = record.studentAttendance[widget.student.uid];
      switch (status) {
        case AttendanceStatus.present:
          monthlyData[monthKey]!['present'] =
              monthlyData[monthKey]!['present']! + 1;
          break;
        case AttendanceStatus.absent:
          monthlyData[monthKey]!['absent'] =
              monthlyData[monthKey]!['absent']! + 1;
          break;
        case AttendanceStatus.late:
          monthlyData[monthKey]!['late'] = monthlyData[monthKey]!['late']! + 1;
          break;
        case null:
          monthlyData[monthKey]!['absent'] =
              monthlyData[monthKey]!['absent']! + 1;
          break;
      }
    }

    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...monthlyData.entries.map((entry) {
          final month = entry.key;
          final data = entry.value;
          final present = data['present'] ?? 0;
          final absent = data['absent'] ?? 0;
          final late = data['late'] ?? 0;
          final total = present + absent + late;
          final percentage =
              total > 0 ? ((present + late * 0.5) / total * 100) : 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$present present, $absent absent, $late late',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(
                      percentage.toDouble(),
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getPercentageColor(percentage.toDouble()),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentAttendance(List<AttendanceModel> records, bool isTablet) {
    final recentRecords = records.take(10).toList();

    if (recentRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Attendance',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...recentRecords.map((record) {
          final status = record.studentAttendance[widget.student.uid];
          final isPresent = status == AttendanceStatus.present;
          final isLate = status == AttendanceStatus.late;
          final isAbsent = status == AttendanceStatus.absent || status == null;

          Color statusColor;
          IconData statusIcon;
          String statusText;

          if (isPresent) {
            statusColor = Colors.green;
            statusIcon = Icons.check;
            statusText = 'Present';
          } else if (isLate) {
            statusColor = Colors.orange;
            statusIcon = Icons.schedule;
            statusText = 'Late';
          } else {
            statusColor = Colors.red;
            statusIcon = Icons.close;
            statusText = 'Absent';
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(record.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLegend(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            'Present',
            Colors.green,
            Icons.check_circle,
            isTablet,
          ),
          _buildLegendItem('Late', Colors.orange, Icons.schedule, isTablet),
          _buildLegendItem('Absent', Colors.red, Icons.cancel, isTablet),
          _buildLegendItem(
            'No Record',
            Colors.grey,
            Icons.circle_outlined,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    IconData icon,
    bool isTablet,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: isTablet ? 18 : 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateAttendanceStats(
    List<AttendanceModel> records,
  ) {
    int present = 0;
    int absent = 0;
    int late = 0;

    for (final record in records) {
      final status = record.studentAttendance[widget.student.uid];
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case null:
          absent++;
          break;
      }
    }

    final total = present + absent + late;
    final percentage = total > 0 ? ((present + late * 0.5) / total * 100) : 0.0;

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'total': total,
      'percentage': percentage,
    };
  }

  void _updateAttendanceData(List<AttendanceModel> records) {
    _attendanceData.clear();
    for (final record in records) {
      final normalizedDate = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
      );
      final status =
          record.studentAttendance[widget.student.uid] ??
          AttendanceStatus.absent;
      _attendanceData[normalizedDate] = status;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    return Colors.red;
  }
}
