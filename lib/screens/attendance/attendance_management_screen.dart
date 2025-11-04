import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/responsive_helper.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _attendanceMap = {};

  void _setAttendance(String studentId, dynamic value) {
    print('Setting attendance for $studentId: $value (${value.runtimeType})');
    bool boolValue = false;

    if (value is bool) {
      boolValue = value;
    } else if (value?.toString().contains('present') == true) {
      print('Converting AttendanceStatus.present to true');
      boolValue = true;
    } else if (value?.toString().contains('absent') == true) {
      print('Converting AttendanceStatus.absent to false');
      boolValue = false;
    } else {
      boolValue = value == true;
    }

    (_attendanceMap as dynamic)[studentId] = boolValue;
    print(
      'Attendance set: ${_attendanceMap[studentId]} (${_attendanceMap[studentId].runtimeType})',
    );
  }

  bool _getAttendance(String studentId) {
    final value = (_attendanceMap as dynamic)[studentId] as dynamic;
    print('Getting attendance for $studentId: $value (${value?.runtimeType})');

    if (value is bool) {
      return value;
    } else if (value == null) {
      return false;
    } else if (value?.toString().contains('present') == true) {
      print('CORRUPTION: Found AttendanceStatus.present, converting to true');
      _setAttendance(studentId, true);
      return true;
    } else if (value?.toString().contains('absent') == true) {
      print('CORRUPTION: Found AttendanceStatus.absent, converting to false');
      _setAttendance(studentId, false);
      return false;
    } else {
      print('UNKNOWN VALUE: $value, defaulting to false');
      _setAttendance(studentId, false);
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mark Attendance', icon: Icon(Icons.how_to_reg)),
            Tab(text: 'View Records', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: FutureBuilder<TeacherModel?>(
        future: databaseService.getTeacher(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Teacher data not found'));
          }

          final teacher = snapshot.data!;
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMarkAttendanceTab(teacher, databaseService, isTablet),
              _buildViewRecordsTab(teacher, databaseService, isTablet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarkAttendanceTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              StreamBuilder<List<ClassModel>>(
                stream: databaseService.getTeacherClasses(teacher.uid),
                builder: (context, classSnapshot) {
                  if (!classSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final classes = classSnapshot.data!;

                  if (classes.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No classes available. Please create a class first or contact your administrator.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items:
                        classes
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
                        _attendanceMap.clear();
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                      _attendanceMap.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ),
        if (_selectedClassId != null)
          Expanded(
            child: StreamBuilder<List<StudentModel>>(
              stream: databaseService.getClassStudents(_selectedClassId!),
              builder: (context, studentSnapshot) {
                if (studentSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final students = studentSnapshot.data!;

                if (_attendanceMap.isEmpty) {
                  print(
                    'Initializing attendance map for ${students.length} students',
                  );
                  _loadExistingAttendance(students, databaseService, teacher);
                } else {
                  _validateAndCleanAttendanceMap(students);
                }

                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                print('Mark All Present pressed');
                                setState(() {
                                  for (final student in students) {
                                    _setAttendance(student.uid, true);
                                  }
                                });
                                print(
                                  'Final attendance map after Mark All Present: $_attendanceMap',
                                );
                              },
                              icon: const Icon(Icons.done_all),
                              label: const Text('Mark All Present'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                print('Mark All Absent pressed');
                                setState(() {
                                  for (final student in students) {
                                    _setAttendance(student.uid, false);
                                  }
                                });
                                print(
                                  'Final attendance map after Mark All Absent: $_attendanceMap',
                                );
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Mark All Absent'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                        ),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentAttendanceCard(student, isTablet);
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () => _submitAttendance(
                                students,
                                databaseService,
                                teacher,
                              ),
                          icon: const Icon(Icons.save),
                          label: const Text('Submit Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a class to mark attendance',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStudentAttendanceCard(StudentModel student, bool isTablet) {
    final isPresent = _getAttendance(student.uid);
    print(
      'Building card for ${student.name}: isPresent=$isPresent (${isPresent.runtimeType})',
    );

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Roll No: ${student.rollNumber}',
          style: TextStyle(fontSize: isTablet ? 14 : 12),
        ),
        trailing: Switch(
          value: isPresent,
          onChanged: (value) {
            print(
              'Switch changed for student ${student.name}: $value (type: ${value.runtimeType})',
            );
            setState(() {
              _setAttendance(student.uid, value);
            });
            print(
              'Attendance map updated: ${_attendanceMap[student.uid]} (type: ${_attendanceMap[student.uid].runtimeType})',
            );
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        onTap: () {
          print(
            'Card tapped for student ${student.name}: toggling from $isPresent to ${!isPresent}',
          );
          setState(() {
            _setAttendance(student.uid, !isPresent);
          });
          print(
            'Attendance map after tap: ${_attendanceMap[student.uid]} (type: ${_attendanceMap[student.uid].runtimeType})',
          );
        },
      ),
    );
  }

  Widget _buildViewRecordsTab(
    TeacherModel teacher,
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(teacher.uid),
            builder: (context, classSnapshot) {
              if (!classSnapshot.hasData) {
                return const SizedBox();
              }

              final classes = classSnapshot.data!;

              if (classes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No classes available. Please create a class first or contact your administrator.',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedClassId,
                decoration: const InputDecoration(
                  labelText: 'Select Class to View Records',
                  prefixIcon: Icon(Icons.class_),
                ),
                items:
                    classes
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
              );
            },
          ),
        ),
        if (_selectedClassId != null)
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Attendance Records',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Date range filter coming soon!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.date_range),
                        tooltip: 'Filter by date range',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<StudentModel>>(
                    stream: databaseService.getClassStudents(_selectedClassId!),
                    builder: (context, studentSnapshot) {
                      if (studentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!studentSnapshot.hasData ||
                          studentSnapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No students found in this class'),
                        );
                      }

                      final students = studentSnapshot.data!;

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                        ),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentRecordCard(student, isTablet);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a class to view attendance records',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _submitAttendance(
    List<StudentModel> students,
    DatabaseService databaseService,
    TeacherModel teacher,
  ) {
    final presentCount =
        _attendanceMap.values.where((present) => present).length;

    print('=== SUBMITTING ATTENDANCE ===');
    print('Selected Class ID: $_selectedClassId');
    print('Selected Date: $_selectedDate');
    print('Total Students: ${students.length}');
    print('Present Count: $presentCount');
    print('Attendance Map: $_attendanceMap');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Submit Attendance'),
            content: Text(
              'Submit attendance for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}?\n\n'
              'Present: $presentCount\n'
              'Absent: ${students.length - presentCount}\n'
              'Total: ${students.length}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  try {
                    print('Getting class data for ID: $_selectedClassId');

                    _validateAndCleanAttendanceMap(students);

                    final teacherClasses =
                        await databaseService
                            .getTeacherClasses(teacher.uid)
                            .first;
                    final selectedClass = teacherClasses.firstWhere(
                      (cls) => cls.id == _selectedClassId,
                      orElse:
                          () =>
                              throw Exception(
                                'Selected class not found in teacher\'s classes',
                              ),
                    );

                    print('Class data retrieved: $selectedClass');

                    final Map<String, AttendanceStatus> studentAttendanceMap =
                        {};

                    print('Creating student attendance map...');
                    for (final student in students) {
                      final isPresent = _getAttendance(student.uid);
                      final status =
                          isPresent
                              ? AttendanceStatus.present
                              : AttendanceStatus.absent;
                      studentAttendanceMap[student.uid] = status;
                      print(
                        'Student ${student.name} (${student.uid}): boolean=$isPresent -> $status',
                      );
                    }

                    print(
                      'Division ID from class data: ${selectedClass.divisionId}',
                    );
                    print(
                      'Institution ID from teacher: ${teacher.institutionId}',
                    );

                    final attendanceRecord = AttendanceModel(
                      id: const Uuid().v4(),
                      institutionId: teacher.institutionId,
                      divisionId: selectedClass.divisionId,
                      classId: _selectedClassId!,
                      date: _selectedDate,
                      studentAttendance: studentAttendanceMap,
                      markedBy: teacher.uid,
                      createdAt: DateTime.now(),
                    );

                    print(
                      'Attendance record created: ${attendanceRecord.toMap()}',
                    );

                    print('Submitting attendance to database...');
                    final result = await databaseService.markAttendance(
                      attendanceRecord,
                    );
                    print('Database submission result: $result');

                    if (result == null) {
                      print('SUCCESS: Attendance submitted successfully');
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Attendance submitted for $presentCount/${students.length} students',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        setState(() {
                          _attendanceMap.clear();
                        });
                      }
                    } else {
                      print('ERROR from database: $result');
                      throw Exception(result);
                    }
                  } catch (e) {
                    print('EXCEPTION caught: $e');
                    print('Exception type: ${e.runtimeType}');
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error submitting attendance: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  Widget _buildStudentRecordCard(StudentModel student, bool isTablet) {
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Roll No: ${student.rollNumber}',
          style: TextStyle(fontSize: isTablet ? 14 : 12),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat('Present', 0, Colors.green),
                    _buildAttendanceStat('Absent', 0, Colors.red),
                    _buildAttendanceStat('Late', 0, Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Detailed attendance history coming soon!',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  void _validateAndCleanAttendanceMap(List<StudentModel> students) {
    print('=== VALIDATING ATTENDANCE MAP ===');
    bool hasCorruption = false;
    final cleanMap = <String, bool>{};

    final dynamicMap = _attendanceMap as dynamic;

    for (final student in students) {
      final value = dynamicMap[student.uid] as dynamic;
      print('Validating ${student.name}: $value (${value.runtimeType})');

      try {
        if (value is bool) {
          cleanMap[student.uid] = value;
        } else if (value?.toString().contains('AttendanceStatus.present') ==
            true) {
          print(
            'CORRUPTION DETECTED: AttendanceStatus.present found, converting to true',
          );
          cleanMap[student.uid] = true;
          hasCorruption = true;
        } else if (value?.toString().contains('AttendanceStatus.absent') ==
            true) {
          print(
            'CORRUPTION DETECTED: AttendanceStatus.absent found, converting to false',
          );
          cleanMap[student.uid] = false;
          hasCorruption = true;
        } else if (value == null) {
          cleanMap[student.uid] = false;
        } else {
          print(
            'UNKNOWN VALUE TYPE: ${value.runtimeType}, defaulting to false',
          );
          cleanMap[student.uid] = false;
          hasCorruption = true;
        }
      } catch (e) {
        print('Error processing ${student.name}: $e');
        cleanMap[student.uid] = false;
        hasCorruption = true;
      }
    }

    if (hasCorruption) {
      print('FIXING CORRUPTED ATTENDANCE MAP');
      _attendanceMap.clear();
      _attendanceMap.addAll(cleanMap);
      print('Map cleaned. New map: $_attendanceMap');
    } else {
      print('Attendance map is clean');
    }
  }

  Future<void> _loadExistingAttendance(
    List<StudentModel> students,
    DatabaseService databaseService,
    TeacherModel teacher,
  ) async {
    try {
      print('Loading existing attendance for date: $_selectedDate');

      final teacherClasses =
          await databaseService.getTeacherClasses(teacher.uid).first;
      final selectedClass = teacherClasses.firstWhere(
        (cls) => cls.id == _selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final existingAttendance = await databaseService.getAttendanceByDate(
        selectedClass.divisionId,
        _selectedDate,
      );

      if (existingAttendance != null) {
        print(
          'Found existing attendance record: ${existingAttendance.toMap()}',
        );
        for (final student in students) {
          final status = existingAttendance.studentAttendance[student.uid];
          bool isPresent = false;
          if (status != null) {
            isPresent = status == AttendanceStatus.present;
            print('Student ${student.name}: $status -> $isPresent');
          }
          _setAttendance(student.uid, isPresent);
        }
      } else {
        print('No existing attendance found, initializing as absent');
        for (final student in students) {
          _setAttendance(student.uid, false);
        }
      }

      print('Final attendance map: $_attendanceMap');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading existing attendance: $e');
      for (final student in students) {
        _setAttendance(student.uid, false);
      }
      if (mounted) {
        setState(() {});
      }
    }
  }
}
