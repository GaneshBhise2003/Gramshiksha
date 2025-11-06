// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../../services/database_service.dart';
// import '../../services/auth_service.dart';
// import '../../models/teacher_model.dart';
// import '../../models/class_model.dart';
// import '../../models/student_model.dart';
// import '../../models/attendance_model.dart';
// import '../../utils/responsive_helper.dart';

// class AttendanceManagementScreen extends StatefulWidget {
//   const AttendanceManagementScreen({super.key});

//   @override
//   State<AttendanceManagementScreen> createState() =>
//       _AttendanceManagementScreenState();
// }

// class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String? _selectedClassId;
//   DateTime _selectedDate = DateTime.now();
//   final Map<String, bool> _attendanceMap = {};
//   bool _allMarked = false;
//   String? _markAllType;
//   bool _isLoading = false;
//   bool _isSubmitting = false;
//   List<StudentModel> _currentStudents = [];
//   bool _attendanceLoaded = false;

//   // View Records variables
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedCalendarDate;
//   Map<DateTime, List<AttendanceModel>> _attendanceEvents = {};
//   Map<String, Map<DateTime, AttendanceStatus>> _studentAttendanceHistory = {};
//   CalendarFormat _calendarFormat = CalendarFormat.month;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _selectedCalendarDate = DateTime.now();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   void _setAttendance(String studentId, bool value) {
//     setState(() {
//       _attendanceMap[studentId] = value;
//     });
//   }

//   bool _getAttendance(String studentId) {
//     return _attendanceMap[studentId] ?? false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     final databaseService = Provider.of<DatabaseService>(context);
//     final isTablet = ResponsiveHelper.isTablet(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Attendance Management'),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Mark Attendance', icon: Icon(Icons.how_to_reg)),
//             Tab(text: 'View Records', icon: Icon(Icons.history)),
//           ],
//         ),
//       ),
//       body: FutureBuilder<TeacherModel?>(
//         future: databaseService.getTeacher(authService.currentUser!.uid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData) {
//             return const Center(child: Text('Teacher data not found'));
//           }

//           final teacher = snapshot.data!;
//           return TabBarView(
//             controller: _tabController,
//             children: [
//               _buildMarkAttendanceTab(teacher, databaseService, isTablet),
//               _buildViewRecordsTab(teacher, databaseService, isTablet),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMarkAttendanceTab(
//     TeacherModel teacher,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Column(
//       children: [
//         // Class selection and date picker section
//         _buildHeaderSection(databaseService, teacher, isTablet),

//         // Students list section - Separated to prevent unnecessary rebuilds
//         if (_selectedClassId != null)
//           Expanded(
//             child: _buildStudentsListSection(databaseService, isTablet),
//           )
//         else
//           _buildEmptyState(),
//       ],
//     );
//   }

//   Widget _buildHeaderSection(
//     DatabaseService databaseService,
//     TeacherModel teacher,
//     bool isTablet,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(isTablet ? 20 : 16),
//       child: Column(
//         children: [
//           StreamBuilder<List<ClassModel>>(
//             stream: databaseService.getTeacherClasses(teacher.uid),
//             builder: (context, classSnapshot) {
//               if (!classSnapshot.hasData) {
//                 return const SizedBox();
//               }

//               final classes = classSnapshot.data!;

//               if (classes.isEmpty) {
//                 return _buildNoClassesWarning();
//               }

//               return DropdownButtonFormField<String>(
//                 value: _selectedClassId,
//                 decoration: const InputDecoration(
//                   labelText: 'Select Class',
//                   prefixIcon: Icon(Icons.class_),
//                 ),
//                 items: classes
//                     .map(
//                       (classModel) => DropdownMenuItem(
//                         value: classModel.id,
//                         child: Text(classModel.name),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedClassId = value;
//                     _attendanceMap.clear();
//                     _allMarked = false;
//                     _markAllType = null;
//                     _attendanceLoaded = false;
//                     _currentStudents.clear();
//                   });
//                 },
//               );
//             },
//           ),
//           const SizedBox(height: 16),
//           _buildDatePicker(isTablet),
//         ],
//       ),
//     );
//   }

//   Widget _buildNoClassesWarning() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Colors.orange.withOpacity(0.3),
//         ),
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.info_outline, color: Colors.orange),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'No classes available. Please create a class first or contact your administrator.',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDatePicker(bool isTablet) {
//     return ListTile(
//       leading: const Icon(Icons.calendar_today),
//       title: Text(
//         'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
//       ),
//       trailing: const Icon(Icons.arrow_drop_down),
//       onTap: () async {
//         final date = await showDatePicker(
//           context: context,
//           initialDate: _selectedDate,
//           firstDate: DateTime.now().subtract(const Duration(days: 365)),
//           lastDate: DateTime.now(),
//         );
//         if (date != null) {
//           setState(() {
//             _selectedDate = date;
//             _attendanceMap.clear();
//             _allMarked = false;
//             _markAllType = null;
//             _attendanceLoaded = false;
//           });
//         }
//       },
//     );
//   }

//   Widget _buildStudentsListSection(
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return StreamBuilder<List<StudentModel>>(
//       stream: databaseService.getClassStudents(_selectedClassId!),
//       builder: (context, studentSnapshot) {
//         if (studentSnapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
//           return _buildNoStudentsState();
//         }

//         final students = studentSnapshot.data!;

//         // Store current students and load attendance only once
//         if (_currentStudents != students) {
//           _currentStudents = students;
//           if (!_attendanceLoaded) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               _loadExistingAttendance(students, databaseService);
//             });
//           }
//         }

//         return Column(
//           children: [
//             // Control buttons section
//             _buildControlButtons(students, isTablet),

//             // Students list - This is where we prevent unnecessary rebuilds
//             Expanded(
//               child: _buildStudentsListView(students, isTablet),
//             ),

//             // Submit button
//             _buildSubmitButton(students, databaseService, isTablet),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildControlButtons(List<StudentModel> students, bool isTablet) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: _isLoading || _isSubmitting
//                   ? null
//                   : () => _markAllStudents(students, true),
//               icon: const Icon(Icons.done_all),
//               label: const Text('Mark All Present'),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: _markAllType == 'present'
//                     ? Colors.green.withOpacity(0.1)
//                     : null,
//                 side: BorderSide(
//                   color: _markAllType == 'present'
//                       ? Colors.green
//                       : Theme.of(context).colorScheme.outline,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: _isLoading || _isSubmitting
//                   ? null
//                   : () => _markAllStudents(students, false),
//               icon: const Icon(Icons.clear_all),
//               label: const Text('Mark All Absent'),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: _markAllType == 'absent'
//                     ? Colors.red.withOpacity(0.1)
//                     : null,
//                 side: BorderSide(
//                   color: _markAllType == 'absent'
//                       ? Colors.red
//                       : Theme.of(context).colorScheme.outline,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentsListView(List<StudentModel> students, bool isTablet) {
//     return ListView.builder(
//       padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//       itemCount: students.length,
//       itemBuilder: (context, index) {
//         final student = students[index];
//         return _StudentAttendanceCard(
//           student: student,
//           isPresent: _getAttendance(student.uid),
//           isToggleEnabled: !_allMarked && !_isSubmitting,
//           isTablet: isTablet,
//           markAllType: _markAllType,
//           onAttendanceChanged: (bool value) {
//             _setAttendance(student.uid, value);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildSubmitButton(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(isTablet ? 20 : 16),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: (_isLoading || _isSubmitting || _attendanceMap.isEmpty)
//               ? null
//               : () => _submitAttendance(students, databaseService),
//           icon: _isSubmitting
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//               : const Icon(Icons.save),
//           label: _isSubmitting
//               ? const Text('Submitting...')
//               : const Text('Submit Attendance'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Theme.of(context).colorScheme.primary,
//             foregroundColor: Theme.of(context).colorScheme.onPrimary,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoStudentsState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.people_outlined,
//             size: 64,
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No students found',
//             style: TextStyle(
//               fontSize: 18,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Expanded(
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.class_,
//               size: 64,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Select a class to mark attendance',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildViewRecordsTab(
//     TeacherModel teacher,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(isTablet ? 20 : 16),
//           child: StreamBuilder<List<ClassModel>>(
//             stream: databaseService.getTeacherClasses(teacher.uid),
//             builder: (context, classSnapshot) {
//               if (!classSnapshot.hasData) return const SizedBox();
//               final classes = classSnapshot.data!;
//               if (classes.isEmpty) return _buildNoClassesWarning();

//               return DropdownButtonFormField<String>(
//                 value: _selectedClassId,
//                 decoration: const InputDecoration(
//                   labelText: 'Select Class to View Records',
//                   prefixIcon: Icon(Icons.class_),
//                 ),
//                 items: classes
//                     .map(
//                       (classModel) => DropdownMenuItem(
//                         value: classModel.id,
//                         child: Text(classModel.name),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedClassId = value;
//                     _selectedCalendarDate = DateTime.now();
//                     _focusedDay = DateTime.now();
//                     _attendanceEvents = {};
//                     _studentAttendanceHistory = {};
//                   });
//                 },
//               );
//             },
//           ),
//         ),
//         if (_selectedClassId != null)
//           Expanded(
//             child: _buildRecordsList(isTablet, databaseService),
//           )
//         else
//           _buildEmptyState(),
//       ],
//     );
//   }

//   Widget _buildRecordsList(bool isTablet, DatabaseService databaseService) {
//     return Column(
//       children: [
//         // 📅 Calendar Section (auto height)
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//           child: Card(
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min, // ✅ auto-fit height
//                 children: [
//                   Text(
//                     'Monthly Attendance Calendar',
//                     style: TextStyle(
//                       fontSize: isTablet ? 14 : 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   StreamBuilder<List<AttendanceModel>>(
//                     stream: databaseService.getAttendanceForClass(
//                       _selectedClassId!,
//                       DateTime(_focusedDay.year, _focusedDay.month, 1),
//                       DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
//                     ),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       if (snapshot.hasData) {
//                         _processAttendanceData(snapshot.data!);
//                       } else if (snapshot.hasError) {
//                         return _buildIndexErrorWidget();
//                       }

//                       return TableCalendar(
//                         firstDay:
//                             DateTime.now().subtract(const Duration(days: 365)),
//                         lastDay: DateTime.now(),
//                         focusedDay: _focusedDay,
//                         calendarFormat: _calendarFormat,
//                         onFormatChanged: (format) {
//                           setState(() => _calendarFormat = format);
//                         },
//                         selectedDayPredicate: (day) =>
//                             isSameDay(_selectedCalendarDate, day),
//                         onDaySelected: (selectedDay, focusedDay) {
//                           setState(() {
//                             _selectedCalendarDate = selectedDay;
//                             _focusedDay = focusedDay;
//                           });
//                         },
//                         onPageChanged: (focusedDay) =>
//                             setState(() => _focusedDay = focusedDay),
//                         eventLoader: (day) =>
//                             _attendanceEvents[
//                                 DateTime(day.year, day.month, day.day)] ??
//                             [],
//                         calendarBuilders: CalendarBuilders(
//                           markerBuilder: (context, date, events) {
//                             if (events.isEmpty) return const SizedBox();

//                             int presentCount = 0;
//                             for (final event in events) {
//                               if (event is AttendanceModel) {
//                                 presentCount += event.studentAttendance.values
//                                     .where((status) =>
//                                         status == AttendanceStatus.present)
//                                     .length;
//                               }
//                             }

//                             // ✅ Small colored dot instead of number
//                             return Positioned(
//                               bottom: 4,
//                               child: Container(
//                                 width: 6,
//                                 height: 6,
//                                 decoration: BoxDecoration(
//                                   color: presentCount > 0
//                                       ? Colors.green
//                                       : Colors.red,
//                                   shape: BoxShape.circle,
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                         // ✅ Slightly smaller sizes to fit comfortably
//                         rowHeight: 32,
//                         daysOfWeekHeight: 24,
//                         calendarStyle: CalendarStyle(
//                           todayDecoration: BoxDecoration(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .primary
//                                 .withOpacity(0.3),
//                             shape: BoxShape.circle,
//                           ),
//                           selectedDecoration: BoxDecoration(
//                             color: Theme.of(context).colorScheme.primary,
//                             shape: BoxShape.circle,
//                           ),
//                           markerDecoration: const BoxDecoration(
//                             color: Colors.transparent,
//                             shape: BoxShape.circle,
//                           ),
//                           outsideDaysVisible: false,
//                         ),
//                         headerStyle: HeaderStyle(
//                           formatButtonVisible: true,
//                           titleCentered: true,
//                           formatButtonShowsNext: false,
//                           formatButtonDecoration: BoxDecoration(
//                             border: Border.all(
//                               color: Theme.of(context).colorScheme.outline,
//                             ),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           formatButtonTextStyle: TextStyle(
//                             color: Theme.of(context).colorScheme.primary,
//                             fontSize: 12,
//                           ),
//                           leftChevronIcon: Icon(
//                             Icons.chevron_left,
//                             color: Theme.of(context).colorScheme.primary,
//                             size: 22,
//                           ),
//                           rightChevronIcon: Icon(
//                             Icons.chevron_right,
//                             color: Theme.of(context).colorScheme.primary,
//                             size: 22,
//                           ),
//                           headerMargin: const EdgeInsets.only(bottom: 4),
//                           titleTextStyle: TextStyle(
//                             fontSize: isTablet ? 14 : 12,
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.onSurface,
//                           ),
//                         ),
//                         daysOfWeekStyle: DaysOfWeekStyle(
//                           weekdayStyle: TextStyle(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .onSurface
//                                 .withOpacity(0.7),
//                             fontWeight: FontWeight.w500,
//                             fontSize: 11,
//                           ),
//                           weekendStyle: TextStyle(
//                             color: Theme.of(context)
//                                 .colorScheme
//                                 .onSurface
//                                 .withOpacity(0.7),
//                             fontWeight: FontWeight.w500,
//                             fontSize: 11,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),

//         const SizedBox(height: 8),

//         // 👇 Student Records Section (scrollable list)
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Student Attendance Records',
//                   style: TextStyle(
//                     fontSize: isTablet ? 16 : 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               if (_selectedCalendarDate != null)
//                 Text(
//                   DateFormat('MMM dd, yyyy').format(_selectedCalendarDate!),
//                   style: TextStyle(
//                     fontSize: isTablet ? 11 : 9,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 8),

//         Expanded(
//           child: StreamBuilder<List<StudentModel>>(
//             stream: databaseService.getClassStudents(_selectedClassId!),
//             builder: (context, studentSnapshot) {
//               if (studentSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
//                 return const Center(
//                     child: Text('No students found in this class'));
//               }

//               final students = studentSnapshot.data!;
//               return ListView.builder(
//                 padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//                 itemCount: students.length,
//                 itemBuilder: (context, index) =>
//                     _buildStudentRecordCard(students[index], isTablet),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildIndexErrorWidget() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           Icons.error_outline,
//           color: Colors.orange,
//           size: 48,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Index Required',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.orange,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Text(
//             'Please create the Firestore index to view attendance records.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                     'Please check the console for the index creation link'),
//               ),
//             );
//           },
//           child: const Text('Create Index'),
//         ),
//       ],
//     );
//   }

//   void _processAttendanceData(List<AttendanceModel> attendanceRecords) {
//     _attendanceEvents.clear();
//     _studentAttendanceHistory.clear();

//     for (final record in attendanceRecords) {
//       // Normalize date to remove time component
//       final date =
//           DateTime(record.date.year, record.date.month, record.date.day);

//       if (!_attendanceEvents.containsKey(date)) {
//         _attendanceEvents[date] = [];
//       }
//       _attendanceEvents[date]!.add(record);

//       // Process student attendance history
//       for (final entry in record.studentAttendance.entries) {
//         final studentId = entry.key;
//         final status = entry.value;

//         if (!_studentAttendanceHistory.containsKey(studentId)) {
//           _studentAttendanceHistory[studentId] = {};
//         }
//         _studentAttendanceHistory[studentId]![date] = status;
//       }
//     }
//   }

//   void _submitAttendance(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//   ) {
//     final presentCount =
//         _attendanceMap.values.where((present) => present).length;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Submit Attendance'),
//         content: Text(
//           'Submit attendance for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}?\n\n'
//           'Present: $presentCount\n'
//           'Absent: ${students.length - presentCount}\n'
//           'Total: ${students.length}',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _submitAttendanceToDatabase(students, databaseService);
//             },
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitAttendanceToDatabase(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//   ) async {
//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final teacher =
//           await databaseService.getTeacher(authService.currentUser!.uid);
//       if (teacher == null) throw Exception('Teacher not found');

//       final teacherClasses =
//           await databaseService.getTeacherClasses(teacher.uid).first;
//       final selectedClass = teacherClasses.firstWhere(
//         (cls) => cls.id == _selectedClassId,
//         orElse: () => throw Exception('Selected class not found'),
//       );

//       final Map<String, AttendanceStatus> studentAttendanceMap = {};
//       for (final student in students) {
//         final isPresent = _getAttendance(student.uid);
//         studentAttendanceMap[student.uid] =
//             isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
//       }

//       final attendanceRecord = AttendanceModel(
//         id: const Uuid().v4(),
//         institutionId: teacher.institutionId,
//         divisionId: selectedClass.divisionId,
//         classId: _selectedClassId!,
//         date: _selectedDate,
//         studentAttendance: studentAttendanceMap,
//         markedBy: teacher.uid,
//         createdAt: DateTime.now(),
//       );

//       final result = await databaseService.markAttendance(attendanceRecord);

//       if (result == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Attendance submitted for ${_attendanceMap.values.where((present) => present).length}/${students.length} students',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );

//         setState(() {
//           _attendanceMap.clear();
//           _allMarked = false;
//           _markAllType = null;
//           _isSubmitting = false;
//         });
//       } else {
//         throw Exception(result);
//       }
//     } catch (e) {
//       setState(() {
//         _isSubmitting = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting attendance: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Widget _buildStudentRecordCard(StudentModel student, bool isTablet) {
//     final monthlyStats = _calculateMonthlyStats(student.uid);
//     final dailyStatus = _getDailyAttendanceStatus(student.uid);

//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           child: Text(
//             student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
//             style: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         title: Text(
//           student.name,
//           style: TextStyle(
//             fontSize: isTablet ? 16 : 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         subtitle: Text(
//           'Roll No: ${student.rollNumber}',
//           style: TextStyle(fontSize: isTablet ? 14 : 12),
//         ),
//         trailing: dailyStatus != null
//             ? Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(dailyStatus).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _getStatusColor(dailyStatus),
//                   ),
//                 ),
//                 child: Text(
//                   dailyStatus.toString().split('.').last.toUpperCase(),
//                   style: TextStyle(
//                     color: _getStatusColor(dailyStatus),
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             : null,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Text(
//                   'Monthly Summary (${DateFormat('MMM yyyy').format(_focusedDay)})',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildAttendanceStat(
//                         'Present', monthlyStats['present'] ?? 0, Colors.green),
//                     _buildAttendanceStat(
//                         'Absent', monthlyStats['absent'] ?? 0, Colors.red),
//                     _buildAttendanceStat(
//                         'Late', monthlyStats['late'] ?? 0, Colors.orange),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 _buildDailyAttendanceDetails(student.uid),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttendanceStat(String label, int count, Color color) {
//     return Column(
//       children: [
//         Text(
//           count.toString(),
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 10, color: color),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildDailyAttendanceDetails(String studentId) {
//     final status = _getDailyAttendanceStatus(studentId);

//     if (_selectedCalendarDate == null) {
//       return Text(
//         'Select a date to view attendance',
//         style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
//       );
//     }

//     if (status == null) {
//       return Text(
//         'No attendance recorded for ${DateFormat('MMM dd, yyyy').format(_selectedCalendarDate!)}',
//         style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
//       );
//     }

//     return Column(
//       children: [
//         Text(
//           'Attendance on ${DateFormat('MMM dd, yyyy').format(_selectedCalendarDate!)}:',
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: _getStatusColor(status).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             status.toString().split('.').last.toUpperCase(),
//             style: TextStyle(
//               color: _getStatusColor(status),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Map<String, int> _calculateMonthlyStats(String studentId) {
//     final stats = {'present': 0, 'absent': 0, 'late': 0};

//     final studentHistory = _studentAttendanceHistory[studentId];
//     if (studentHistory == null) return stats;

//     final currentMonth = DateTime(_focusedDay.year, _focusedDay.month);

//     for (final entry in studentHistory.entries) {
//       final date = entry.key;
//       final status = entry.value;

//       if (date.year == currentMonth.year && date.month == currentMonth.month) {
//         switch (status) {
//           case AttendanceStatus.present:
//             stats['present'] = stats['present']! + 1;
//             break;
//           case AttendanceStatus.absent:
//             stats['absent'] = stats['absent']! + 1;
//             break;
//           case AttendanceStatus.late:
//             stats['late'] = stats['late']! + 1;
//             break;
//         }
//       }
//     }

//     return stats;
//   }

//   AttendanceStatus? _getDailyAttendanceStatus(String studentId) {
//     if (_selectedCalendarDate == null) return null;

//     final studentHistory = _studentAttendanceHistory[studentId];
//     if (studentHistory == null) return null;

//     final dateKey = DateTime(
//       _selectedCalendarDate!.year,
//       _selectedCalendarDate!.month,
//       _selectedCalendarDate!.day,
//     );

//     return studentHistory[dateKey];
//   }

//   Color _getStatusColor(AttendanceStatus status) {
//     switch (status) {
//       case AttendanceStatus.present:
//         return Colors.green;
//       case AttendanceStatus.absent:
//         return Colors.red;
//       case AttendanceStatus.late:
//         return Colors.orange;
//     }
//   }

//   Future<void> _loadExistingAttendance(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//   ) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final teacher =
//           await databaseService.getTeacher(authService.currentUser!.uid);
//       if (teacher == null) return;

//       final teacherClasses =
//           await databaseService.getTeacherClasses(teacher.uid).first;
//       final selectedClass = teacherClasses.firstWhere(
//         (cls) => cls.id == _selectedClassId,
//         orElse: () => throw Exception('Selected class not found'),
//       );

//       final existingAttendance = await databaseService.getAttendanceByDate(
//         selectedClass.divisionId,
//         _selectedDate,
//       );

//       if (existingAttendance != null) {
//         for (final student in students) {
//           final status = existingAttendance.studentAttendance[student.uid];
//           final isPresent = status == AttendanceStatus.present;
//           _setAttendance(student.uid, isPresent);
//         }
//       } else {
//         for (final student in students) {
//           _setAttendance(student.uid, false);
//         }
//       }

//       _attendanceLoaded = true;
//     } catch (e) {
//       for (final student in students) {
//         _setAttendance(student.uid, false);
//       }
//       _attendanceLoaded = true;
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _markAllStudents(List<StudentModel> students, bool isPresent) {
//     setState(() {
//       for (final student in students) {
//         _setAttendance(student.uid, isPresent);
//       }
//       _allMarked = true;
//       _markAllType = isPresent ? 'present' : 'absent';
//     });
//   }
// }

// // Separate widget for student card to prevent unnecessary rebuilds
// class _StudentAttendanceCard extends StatelessWidget {
//   final StudentModel student;
//   final bool isPresent;
//   final bool isToggleEnabled;
//   final bool isTablet;
//   final String? markAllType;
//   final ValueChanged<bool> onAttendanceChanged;

//   const _StudentAttendanceCard({
//     required this.student,
//     required this.isPresent,
//     required this.isToggleEnabled,
//     required this.isTablet,
//     required this.markAllType,
//     required this.onAttendanceChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           child: Text(
//             student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
//             style: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         title: Text(
//           student.name,
//           style: TextStyle(
//             fontSize: isTablet ? 16 : 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         subtitle: Text(
//           'Roll No: ${student.rollNumber}',
//           style: TextStyle(fontSize: isTablet ? 14 : 12),
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (!isToggleEnabled)
//               Icon(
//                 isPresent ? Icons.check_circle : Icons.cancel,
//                 color: isPresent ? Colors.green : Colors.red,
//                 size: 28,
//               ),
//             if (isToggleEnabled)
//               Switch(
//                 value: isPresent,
//                 onChanged: (value) => onAttendanceChanged(value),
//                 activeColor: Theme.of(context).colorScheme.primary,
//               ),
//           ],
//         ),
//         onTap: isToggleEnabled ? () => onAttendanceChanged(!isPresent) : null,
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '../../services/database_service.dart';
// import '../../services/auth_service.dart';
// import '../../models/teacher_model.dart';
// import '../../models/class_model.dart';
// import '../../models/student_model.dart';
// import '../../models/attendance_model.dart';
// import '../../utils/responsive_helper.dart';

// // State management classes
// class AttendanceState extends ChangeNotifier {
//   String? _selectedClassId;
//   DateTime _selectedDate = DateTime.now();
//   final Map<String, bool> _attendanceMap = {};
//   bool _allMarked = false;
//   String? _markAllType;
//   bool _isLoading = false;
//   bool _isSubmitting = false;
//   List<StudentModel> _currentStudents = [];
//   bool _attendanceLoaded = false;

//   // Getters
//   String? get selectedClassId => _selectedClassId;
//   DateTime get selectedDate => _selectedDate;
//   Map<String, bool> get attendanceMap => _attendanceMap;
//   bool get allMarked => _allMarked;
//   String? get markAllType => _markAllType;
//   bool get isLoading => _isLoading;
//   bool get isSubmitting => _isSubmitting;
//   List<StudentModel> get currentStudents => _currentStudents;
//   bool get attendanceLoaded => _attendanceLoaded;

//   // Setters with safe notification
//   void setSelectedClassId(String? value, {bool notify = true}) {
//     _selectedClassId = value;
//     _attendanceMap.clear();
//     _allMarked = false;
//     _markAllType = null;
//     _attendanceLoaded = false;
//     _currentStudents.clear();
//     if (notify) _safeNotify();
//   }

//   void setSelectedDate(DateTime value, {bool notify = true}) {
//     _selectedDate = value;
//     _attendanceMap.clear();
//     _allMarked = false;
//     _markAllType = null;
//     _attendanceLoaded = false;
//     if (notify) _safeNotify();
//   }

//   void setIsLoading(bool value, {bool notify = true}) {
//     _isLoading = value;
//     if (notify) _safeNotify();
//   }

//   void setIsSubmitting(bool value, {bool notify = true}) {
//     _isSubmitting = value;
//     if (notify) _safeNotify();
//   }

//   void setAttendanceLoaded(bool value, {bool notify = true}) {
//     _attendanceLoaded = value;
//     if (notify) _safeNotify();
//   }

//   // Safe notification method
//   void _safeNotify() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (hasListeners) {
//         notifyListeners();
//       }
//     });
//   }

//   // Methods
//   void setAttendance(String studentId, bool value, {bool notify = true}) {
//     _attendanceMap[studentId] = value;
//     if (notify) _safeNotify();
//   }

//   bool getAttendance(String studentId) {
//     return _attendanceMap[studentId] ?? false;
//   }

//   void markAllStudents(List<StudentModel> students, bool isPresent,
//       {bool notify = true}) {
//     for (final student in students) {
//       _attendanceMap[student.uid] = isPresent;
//     }
//     _allMarked = true;
//     _markAllType = isPresent ? 'present' : 'absent';
//     if (notify) _safeNotify();
//   }

//   void setCurrentStudents(List<StudentModel> students, {bool notify = true}) {
//     _currentStudents = students;
//     if (notify) _safeNotify();
//   }

//   void clearAttendance({bool notify = true}) {
//     _attendanceMap.clear();
//     _allMarked = false;
//     _markAllType = null;
//     if (notify) _safeNotify();
//   }

//   // Batch update method to reduce notifications
//   void batchUpdate(void Function() updates, {bool notify = true}) {
//     updates();
//     if (notify) _safeNotify();
//   }
// }

// class CalendarState extends ChangeNotifier {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedCalendarDate = DateTime.now();
//   Map<DateTime, List<AttendanceModel>> _attendanceEvents = {};
//   Map<String, Map<DateTime, AttendanceStatus>> _studentAttendanceHistory = {};
//   CalendarFormat _calendarFormat = CalendarFormat.month;

//   // Getters
//   DateTime get focusedDay => _focusedDay;
//   DateTime? get selectedCalendarDate => _selectedCalendarDate;
//   Map<DateTime, List<AttendanceModel>> get attendanceEvents =>
//       _attendanceEvents;
//   Map<String, Map<DateTime, AttendanceStatus>> get studentAttendanceHistory =>
//       _studentAttendanceHistory;
//   CalendarFormat get calendarFormat => _calendarFormat;

//   // Safe notification method
//   void _safeNotify() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (hasListeners) {
//         notifyListeners();
//       }
//     });
//   }

//   // Setters with safe notification
//   void setFocusedDay(DateTime value, {bool notify = true}) {
//     _focusedDay = value;
//     if (notify) _safeNotify();
//   }

//   void setSelectedCalendarDate(DateTime? value, {bool notify = true}) {
//     _selectedCalendarDate = value;
//     if (notify) _safeNotify();
//   }

//   void setCalendarFormat(CalendarFormat value, {bool notify = true}) {
//     _calendarFormat = value;
//     if (notify) _safeNotify();
//   }

//   // Methods
//   void processAttendanceData(List<AttendanceModel> attendanceRecords,
//       {bool notify = true}) {
//     _attendanceEvents.clear();
//     _studentAttendanceHistory.clear();

//     for (final record in attendanceRecords) {
//       final date =
//           DateTime(record.date.year, record.date.month, record.date.day);

//       if (!_attendanceEvents.containsKey(date)) {
//         _attendanceEvents[date] = [];
//       }
//       _attendanceEvents[date]!.add(record);

//       for (final entry in record.studentAttendance.entries) {
//         final studentId = entry.key;
//         final status = entry.value;

//         if (!_studentAttendanceHistory.containsKey(studentId)) {
//           _studentAttendanceHistory[studentId] = {};
//         }
//         _studentAttendanceHistory[studentId]![date] = status;
//       }
//     }
//     if (notify) _safeNotify();
//   }

//   Map<String, int> calculateMonthlyStats(String studentId) {
//     final stats = {'present': 0, 'absent': 0, 'late': 0};

//     final studentHistory = _studentAttendanceHistory[studentId];
//     if (studentHistory == null) return stats;

//     final currentMonth = DateTime(_focusedDay.year, _focusedDay.month);

//     for (final entry in studentHistory.entries) {
//       final date = entry.key;
//       final status = entry.value;

//       if (date.year == currentMonth.year && date.month == currentMonth.month) {
//         switch (status) {
//           case AttendanceStatus.present:
//             stats['present'] = stats['present']! + 1;
//             break;
//           case AttendanceStatus.absent:
//             stats['absent'] = stats['absent']! + 1;
//             break;
//           case AttendanceStatus.late:
//             stats['late'] = stats['late']! + 1;
//             break;
//         }
//       }
//     }

//     return stats;
//   }

//   AttendanceStatus? getDailyAttendanceStatus(String studentId) {
//     if (_selectedCalendarDate == null) return null;

//     final studentHistory = _studentAttendanceHistory[studentId];
//     if (studentHistory == null) return null;

//     final dateKey = DateTime(
//       _selectedCalendarDate!.year,
//       _selectedCalendarDate!.month,
//       _selectedCalendarDate!.day,
//     );

//     return studentHistory[dateKey];
//   }
// }

// class AttendanceManagementScreen extends StatefulWidget {
//   const AttendanceManagementScreen({super.key});

//   @override
//   State<AttendanceManagementScreen> createState() =>
//       _AttendanceManagementScreenState();
// }

// class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final ValueNotifier<String?> _selectedClassNotifier =
//       ValueNotifier<String?>(null);

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _selectedClassNotifier.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AttendanceState()),
//         ChangeNotifierProvider(create: (_) => CalendarState()),
//       ],
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Attendance Management'),
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           bottom: TabBar(
//             controller: _tabController,
//             tabs: const [
//               Tab(text: 'Mark Attendance', icon: Icon(Icons.how_to_reg)),
//               Tab(text: 'View Records', icon: Icon(Icons.history)),
//             ],
//           ),
//         ),
//         body: FutureBuilder<TeacherModel?>(
//           future: Provider.of<DatabaseService>(context, listen: false)
//               .getTeacher(Provider.of<AuthService>(context).currentUser!.uid),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (!snapshot.hasData) {
//               return const Center(child: Text('Teacher data not found'));
//             }

//             final teacher = snapshot.data!;
//             return TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildMarkAttendanceTab(teacher),
//                 _buildViewRecordsTab(teacher),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildMarkAttendanceTab(TeacherModel teacher) {
//     final databaseService = Provider.of<DatabaseService>(context);
//     final isTablet = ResponsiveHelper.isTablet(context);

//     return Column(
//       children: [
//         // Class selection and date picker section
//         _buildHeaderSection(databaseService, teacher, isTablet),

//         // Students list section
//         Consumer<AttendanceState>(
//           builder: (context, attendanceState, child) {
//             if (attendanceState.selectedClassId != null) {
//               return Expanded(
//                 child: _buildStudentsListSection(databaseService, isTablet),
//               );
//             } else {
//               return _buildEmptyState();
//             }
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderSection(
//     DatabaseService databaseService,
//     TeacherModel teacher,
//     bool isTablet,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(isTablet ? 20 : 16),
//       child: Column(
//         children: [
//           StreamBuilder<List<ClassModel>>(
//             stream: databaseService.getTeacherClasses(teacher.uid),
//             builder: (context, classSnapshot) {
//               if (!classSnapshot.hasData) {
//                 return const SizedBox();
//               }

//               final classes = classSnapshot.data!;

//               if (classes.isEmpty) {
//                 return _buildNoClassesWarning();
//               }

//               return Consumer<AttendanceState>(
//                 builder: (context, attendanceState, child) {
//                   return DropdownButtonFormField<String>(
//                     value: attendanceState.selectedClassId,
//                     decoration: const InputDecoration(
//                       labelText: 'Select Class',
//                       prefixIcon: Icon(Icons.class_),
//                     ),
//                     items: classes
//                         .map(
//                           (classModel) => DropdownMenuItem(
//                             value: classModel.id,
//                             child: Text(classModel.name),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (value) {
//                       // Use post-frame callback to avoid setState during build
//                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                         attendanceState.setSelectedClassId(value);
//                       });
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//           const SizedBox(height: 16),
//           _buildDatePicker(isTablet),
//         ],
//       ),
//     );
//   }

//   Widget _buildNoClassesWarning() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: Colors.orange.withOpacity(0.3),
//         ),
//       ),
//       child: const Row(
//         children: [
//           Icon(Icons.info_outline, color: Colors.orange),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'No classes available. Please create a class first or contact your administrator.',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDatePicker(bool isTablet) {
//     return Consumer<AttendanceState>(
//       builder: (context, attendanceState, child) {
//         return ListTile(
//           leading: const Icon(Icons.calendar_today),
//           title: Text(
//             'Date: ${DateFormat('MMM dd, yyyy').format(attendanceState.selectedDate)}',
//           ),
//           trailing: const Icon(Icons.arrow_drop_down),
//           onTap: () async {
//             final date = await showDatePicker(
//               context: context,
//               initialDate: attendanceState.selectedDate,
//               firstDate: DateTime.now().subtract(const Duration(days: 365)),
//               lastDate: DateTime.now(),
//             );
//             if (date != null) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 attendanceState.setSelectedDate(date);
//               });
//             }
//           },
//         );
//       },
//     );
//   }

//   Widget _buildStudentsListSection(
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Consumer<AttendanceState>(
//       builder: (context, attendanceState, child) {
//         return StreamBuilder<List<StudentModel>>(
//           stream: databaseService
//               .getClassStudents(attendanceState.selectedClassId!),
//           builder: (context, studentSnapshot) {
//             if (studentSnapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
//               return _buildNoStudentsState();
//             }

//             final students = studentSnapshot.data!;

//             // Load attendance only when students change, using post-frame callback
//             if (attendanceState.currentStudents != students) {
//               WidgetsBinding.instance.addPostFrameCallback((_) {
//                 attendanceState.setCurrentStudents(students, notify: false);
//                 if (!attendanceState.attendanceLoaded) {
//                   _loadExistingAttendance(
//                       students, databaseService, attendanceState);
//                 }
//               });
//             }

//             return Column(
//               children: [
//                 // Control buttons section
//                 _buildControlButtons(students, isTablet, attendanceState),

//                 // Students list
//                 Expanded(
//                   child: _buildStudentsListView(
//                       students, isTablet, attendanceState),
//                 ),

//                 // Submit button
//                 _buildSubmitButton(
//                     students, databaseService, isTablet, attendanceState),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildControlButtons(
//     List<StudentModel> students,
//     bool isTablet,
//     AttendanceState attendanceState,
//   ) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//       child: Row(
//         children: [
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed:
//                   attendanceState.isLoading || attendanceState.isSubmitting
//                       ? null
//                       : () {
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             attendanceState.markAllStudents(students, true);
//                           });
//                         },
//               icon: const Icon(Icons.done_all),
//               label: const Text('Mark All Present'),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: attendanceState.markAllType == 'present'
//                     ? Colors.green.withOpacity(0.1)
//                     : null,
//                 side: BorderSide(
//                   color: attendanceState.markAllType == 'present'
//                       ? Colors.green
//                       : Theme.of(context).colorScheme.outline,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed:
//                   attendanceState.isLoading || attendanceState.isSubmitting
//                       ? null
//                       : () {
//                           WidgetsBinding.instance.addPostFrameCallback((_) {
//                             attendanceState.markAllStudents(students, false);
//                           });
//                         },
//               icon: const Icon(Icons.clear_all),
//               label: const Text('Mark All Absent'),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: attendanceState.markAllType == 'absent'
//                     ? Colors.red.withOpacity(0.1)
//                     : null,
//                 side: BorderSide(
//                   color: attendanceState.markAllType == 'absent'
//                       ? Colors.red
//                       : Theme.of(context).colorScheme.outline,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentsListView(
//     List<StudentModel> students,
//     bool isTablet,
//     AttendanceState attendanceState,
//   ) {
//     return ListView.builder(
//       padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//       itemCount: students.length,
//       itemBuilder: (context, index) {
//         final student = students[index];
//         return _StudentAttendanceCard(
//           student: student,
//           isPresent: attendanceState.getAttendance(student.uid),
//           isToggleEnabled:
//               !attendanceState.allMarked && !attendanceState.isSubmitting,
//           isTablet: isTablet,
//           markAllType: attendanceState.markAllType,
//           onAttendanceChanged: (bool value) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               attendanceState.setAttendance(student.uid, value);
//             });
//           },
//         );
//       },
//     );
//   }

//   Widget _buildSubmitButton(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//     bool isTablet,
//     AttendanceState attendanceState,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(isTablet ? 20 : 16),
//       child: SizedBox(
//         width: double.infinity,
//         child: ElevatedButton.icon(
//           onPressed: (attendanceState.isLoading ||
//                   attendanceState.isSubmitting ||
//                   attendanceState.attendanceMap.isEmpty)
//               ? null
//               : () =>
//                   _submitAttendance(students, databaseService, attendanceState),
//           icon: attendanceState.isSubmitting
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//               : const Icon(Icons.save),
//           label: attendanceState.isSubmitting
//               ? const Text('Submitting...')
//               : const Text('Submit Attendance'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Theme.of(context).colorScheme.primary,
//             foregroundColor: Theme.of(context).colorScheme.onPrimary,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoStudentsState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.people_outlined,
//             size: 64,
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No students found',
//             style: TextStyle(
//               fontSize: 18,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Expanded(
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.class_,
//               size: 64,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Select a class to mark attendance',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildViewRecordsTab(TeacherModel teacher) {
//     final databaseService = Provider.of<DatabaseService>(context);
//     final isTablet = ResponsiveHelper.isTablet(context);

//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(isTablet ? 20 : 16),
//           child: StreamBuilder<List<ClassModel>>(
//             stream: databaseService.getTeacherClasses(teacher.uid),
//             builder: (context, classSnapshot) {
//               if (!classSnapshot.hasData) return const SizedBox();
//               final classes = classSnapshot.data!;
//               if (classes.isEmpty) return _buildNoClassesWarning();

//               return Consumer<AttendanceState>(
//                 builder: (context, attendanceState, child) {
//                   return DropdownButtonFormField<String>(
//                     value: attendanceState.selectedClassId,
//                     decoration: const InputDecoration(
//                       labelText: 'Select Class to View Records',
//                       prefixIcon: Icon(Icons.class_),
//                     ),
//                     items: classes
//                         .map(
//                           (classModel) => DropdownMenuItem(
//                             value: classModel.id,
//                             child: Text(classModel.name),
//                           ),
//                         )
//                         .toList(),
//                     onChanged: (value) {
//                       WidgetsBinding.instance.addPostFrameCallback((_) {
//                         attendanceState.setSelectedClassId(value);
//                         final calendarState =
//                             Provider.of<CalendarState>(context, listen: false);
//                         calendarState.setSelectedCalendarDate(DateTime.now());
//                         calendarState.setFocusedDay(DateTime.now());
//                       });
//                     },
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//         Consumer<AttendanceState>(
//           builder: (context, attendanceState, child) {
//             if (attendanceState.selectedClassId != null) {
//               return Expanded(
//                 child: _buildRecordsList(isTablet, databaseService),
//               );
//             } else {
//               return _buildEmptyState();
//             }
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildRecordsList(bool isTablet, DatabaseService databaseService) {
//     return Consumer2<AttendanceState, CalendarState>(
//       builder: (context, attendanceState, calendarState, child) {
//         return Column(
//           children: [
//             // 📅 Calendar Section
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//               child: Card(
//                 elevation: 2,
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         'Monthly Attendance Calendar',
//                         style: TextStyle(
//                           fontSize: isTablet ? 14 : 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       StreamBuilder<List<AttendanceModel>>(
//                         stream: databaseService.getAttendanceForClass(
//                           attendanceState.selectedClassId!,
//                           DateTime(calendarState.focusedDay.year,
//                               calendarState.focusedDay.month, 1),
//                           DateTime(calendarState.focusedDay.year,
//                               calendarState.focusedDay.month + 1, 0),
//                         ),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return const Center(
//                                 child: CircularProgressIndicator());
//                           }

//                           if (snapshot.hasData) {
//                             WidgetsBinding.instance.addPostFrameCallback((_) {
//                               calendarState
//                                   .processAttendanceData(snapshot.data!);
//                             });
//                           } else if (snapshot.hasError) {
//                             return _buildIndexErrorWidget();
//                           }

//                           return TableCalendar(
//                             firstDay: DateTime.now()
//                                 .subtract(const Duration(days: 365)),
//                             lastDay: DateTime.now(),
//                             focusedDay: calendarState.focusedDay,
//                             calendarFormat: calendarState.calendarFormat,
//                             onFormatChanged: (format) {
//                               WidgetsBinding.instance.addPostFrameCallback((_) {
//                                 calendarState.setCalendarFormat(format);
//                               });
//                             },
//                             selectedDayPredicate: (day) => isSameDay(
//                                 calendarState.selectedCalendarDate, day),
//                             onDaySelected: (selectedDay, focusedDay) {
//                               WidgetsBinding.instance.addPostFrameCallback((_) {
//                                 calendarState
//                                     .setSelectedCalendarDate(selectedDay);
//                                 calendarState.setFocusedDay(focusedDay);
//                               });
//                             },
//                             onPageChanged: (focusedDay) {
//                               WidgetsBinding.instance.addPostFrameCallback((_) {
//                                 calendarState.setFocusedDay(focusedDay);
//                               });
//                             },
//                             eventLoader: (day) =>
//                                 calendarState.attendanceEvents[
//                                     DateTime(day.year, day.month, day.day)] ??
//                                 [],
//                             calendarBuilders: CalendarBuilders(
//                               markerBuilder: (context, date, events) {
//                                 if (events.isEmpty) return const SizedBox();

//                                 int presentCount = 0;
//                                 for (final event in events) {
//                                   if (event is AttendanceModel) {
//                                     presentCount += event
//                                         .studentAttendance.values
//                                         .where((status) =>
//                                             status == AttendanceStatus.present)
//                                         .length;
//                                   }
//                                 }

//                                 return Positioned(
//                                   bottom: 4,
//                                   child: Container(
//                                     width: 6,
//                                     height: 6,
//                                     decoration: BoxDecoration(
//                                       color: presentCount > 0
//                                           ? Colors.green
//                                           : Colors.red,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                             rowHeight: 32,
//                             daysOfWeekHeight: 24,
//                             calendarStyle: CalendarStyle(
//                               todayDecoration: BoxDecoration(
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .primary
//                                     .withOpacity(0.3),
//                                 shape: BoxShape.circle,
//                               ),
//                               selectedDecoration: BoxDecoration(
//                                 color: Theme.of(context).colorScheme.primary,
//                                 shape: BoxShape.circle,
//                               ),
//                               markerDecoration: const BoxDecoration(
//                                 color: Colors.transparent,
//                                 shape: BoxShape.circle,
//                               ),
//                               outsideDaysVisible: false,
//                             ),
//                             headerStyle: HeaderStyle(
//                               formatButtonVisible: true,
//                               titleCentered: true,
//                               formatButtonShowsNext: false,
//                               formatButtonDecoration: BoxDecoration(
//                                 border: Border.all(
//                                   color: Theme.of(context).colorScheme.outline,
//                                 ),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               formatButtonTextStyle: TextStyle(
//                                 color: Theme.of(context).colorScheme.primary,
//                                 fontSize: 12,
//                               ),
//                               leftChevronIcon: Icon(
//                                 Icons.chevron_left,
//                                 color: Theme.of(context).colorScheme.primary,
//                                 size: 22,
//                               ),
//                               rightChevronIcon: Icon(
//                                 Icons.chevron_right,
//                                 color: Theme.of(context).colorScheme.primary,
//                                 size: 22,
//                               ),
//                               headerMargin: const EdgeInsets.only(bottom: 4),
//                               titleTextStyle: TextStyle(
//                                 fontSize: isTablet ? 14 : 12,
//                                 fontWeight: FontWeight.bold,
//                                 color: Theme.of(context).colorScheme.onSurface,
//                               ),
//                             ),
//                             daysOfWeekStyle: DaysOfWeekStyle(
//                               weekdayStyle: TextStyle(
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .onSurface
//                                     .withOpacity(0.7),
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 11,
//                               ),
//                               weekendStyle: TextStyle(
//                                 color: Theme.of(context)
//                                     .colorScheme
//                                     .onSurface
//                                     .withOpacity(0.7),
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 11,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 8),

//             // 👇 Student Records Section
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Student Attendance Records',
//                       style: TextStyle(
//                         fontSize: isTablet ? 16 : 14,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   if (calendarState.selectedCalendarDate != null)
//                     Text(
//                       DateFormat('MMM dd, yyyy')
//                           .format(calendarState.selectedCalendarDate!),
//                       style: TextStyle(
//                         fontSize: isTablet ? 11 : 9,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),

//             Expanded(
//               child: StreamBuilder<List<StudentModel>>(
//                 stream: databaseService
//                     .getClassStudents(attendanceState.selectedClassId!),
//                 builder: (context, studentSnapshot) {
//                   if (studentSnapshot.connectionState ==
//                       ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!studentSnapshot.hasData ||
//                       studentSnapshot.data!.isEmpty) {
//                     return const Center(
//                         child: Text('No students found in this class'));
//                   }

//                   final students = studentSnapshot.data!;
//                   return ListView.builder(
//                     padding:
//                         EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
//                     itemCount: students.length,
//                     itemBuilder: (context, index) => _buildStudentRecordCard(
//                         students[index], isTablet, calendarState),
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildIndexErrorWidget() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           Icons.error_outline,
//           color: Colors.orange,
//           size: 48,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Index Required',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: Colors.orange,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Text(
//             'Please create the Firestore index to view attendance records.',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         ElevatedButton(
//           onPressed: () {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                     'Please check the console for the index creation link'),
//               ),
//             );
//           },
//           child: const Text('Create Index'),
//         ),
//       ],
//     );
//   }

//   Widget _buildStudentRecordCard(
//       StudentModel student, bool isTablet, CalendarState calendarState) {
//     final monthlyStats = calendarState.calculateMonthlyStats(student.uid);
//     final dailyStatus = calendarState.getDailyAttendanceStatus(student.uid);

//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           child: Text(
//             student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
//             style: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         title: Text(
//           student.name,
//           style: TextStyle(
//             fontSize: isTablet ? 16 : 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         subtitle: Text(
//           'Roll No: ${student.rollNumber}',
//           style: TextStyle(fontSize: isTablet ? 14 : 12),
//         ),
//         trailing: dailyStatus != null
//             ? Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: _getStatusColor(dailyStatus).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _getStatusColor(dailyStatus),
//                   ),
//                 ),
//                 child: Text(
//                   dailyStatus.toString().split('.').last.toUpperCase(),
//                   style: TextStyle(
//                     color: _getStatusColor(dailyStatus),
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               )
//             : null,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 Text(
//                   'Monthly Summary (${DateFormat('MMM yyyy').format(calendarState.focusedDay)})',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildAttendanceStat(
//                         'Present', monthlyStats['present'] ?? 0, Colors.green),
//                     _buildAttendanceStat(
//                         'Absent', monthlyStats['absent'] ?? 0, Colors.red),
//                     _buildAttendanceStat(
//                         'Late', monthlyStats['late'] ?? 0, Colors.orange),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 _buildDailyAttendanceDetails(student.uid, calendarState),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttendanceStat(String label, int count, Color color) {
//     return Column(
//       children: [
//         Text(
//           count.toString(),
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 10, color: color),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildDailyAttendanceDetails(
//       String studentId, CalendarState calendarState) {
//     final status = calendarState.getDailyAttendanceStatus(studentId);

//     if (calendarState.selectedCalendarDate == null) {
//       return Text(
//         'Select a date to view attendance',
//         style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
//       );
//     }

//     if (status == null) {
//       return Text(
//         'No attendance recorded for ${DateFormat('MMM dd, yyyy').format(calendarState.selectedCalendarDate!)}',
//         style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
//       );
//     }

//     return Column(
//       children: [
//         Text(
//           'Attendance on ${DateFormat('MMM dd, yyyy').format(calendarState.selectedCalendarDate!)}:',
//           style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: _getStatusColor(status).withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Text(
//             status.toString().split('.').last.toUpperCase(),
//             style: TextStyle(
//               color: _getStatusColor(status),
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getStatusColor(AttendanceStatus status) {
//     switch (status) {
//       case AttendanceStatus.present:
//         return Colors.green;
//       case AttendanceStatus.absent:
//         return Colors.red;
//       case AttendanceStatus.late:
//         return Colors.orange;
//     }
//   }

//   Future<void> _loadExistingAttendance(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//     AttendanceState attendanceState,
//   ) async {
//     attendanceState.setIsLoading(true, notify: false);

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final teacher =
//           await databaseService.getTeacher(authService.currentUser!.uid);
//       if (teacher == null) return;

//       final teacherClasses =
//           await databaseService.getTeacherClasses(teacher.uid).first;
//       final selectedClass = teacherClasses.firstWhere(
//         (cls) => cls.id == attendanceState.selectedClassId,
//         orElse: () => throw Exception('Selected class not found'),
//       );

//       final existingAttendance = await databaseService.getAttendanceByDate(
//         selectedClass.divisionId,
//         attendanceState.selectedDate,
//       );

//       // Use batch update to reduce notifications
//       attendanceState.batchUpdate(() {
//         if (existingAttendance != null) {
//           for (final student in students) {
//             final status = existingAttendance.studentAttendance[student.uid];
//             final isPresent = status == AttendanceStatus.present;
//             attendanceState.setAttendance(student.uid, isPresent,
//                 notify: false);
//           }
//         } else {
//           for (final student in students) {
//             attendanceState.setAttendance(student.uid, false, notify: false);
//           }
//         }
//         attendanceState.setAttendanceLoaded(true, notify: false);
//       });
//     } catch (e) {
//       attendanceState.batchUpdate(() {
//         for (final student in students) {
//           attendanceState.setAttendance(student.uid, false, notify: false);
//         }
//         attendanceState.setAttendanceLoaded(true, notify: false);
//       });
//     } finally {
//       if (mounted) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           attendanceState.setIsLoading(false);
//         });
//       }
//     }
//   }

//   void _submitAttendance(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//     AttendanceState attendanceState,
//   ) {
//     final presentCount =
//         attendanceState.attendanceMap.values.where((present) => present).length;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Submit Attendance'),
//         content: Text(
//           'Submit attendance for ${DateFormat('MMM dd, yyyy').format(attendanceState.selectedDate)}?\n\n'
//           'Present: $presentCount\n'
//           'Absent: ${students.length - presentCount}\n'
//           'Total: ${students.length}',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await _submitAttendanceToDatabase(
//                   students, databaseService, attendanceState);
//             },
//             child: const Text('Submit'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _submitAttendanceToDatabase(
//     List<StudentModel> students,
//     DatabaseService databaseService,
//     AttendanceState attendanceState,
//   ) async {
//     attendanceState.setIsSubmitting(true);

//     try {
//       final authService = Provider.of<AuthService>(context, listen: false);
//       final teacher =
//           await databaseService.getTeacher(authService.currentUser!.uid);
//       if (teacher == null) throw Exception('Teacher not found');

//       final teacherClasses =
//           await databaseService.getTeacherClasses(teacher.uid).first;
//       final selectedClass = teacherClasses.firstWhere(
//         (cls) => cls.id == attendanceState.selectedClassId,
//         orElse: () => throw Exception('Selected class not found'),
//       );

//       final Map<String, AttendanceStatus> studentAttendanceMap = {};
//       for (final student in students) {
//         final isPresent = attendanceState.getAttendance(student.uid);
//         studentAttendanceMap[student.uid] =
//             isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
//       }

//       final attendanceRecord = AttendanceModel(
//         id: const Uuid().v4(),
//         institutionId: teacher.institutionId,
//         divisionId: selectedClass.divisionId,
//         classId: attendanceState.selectedClassId!,
//         date: attendanceState.selectedDate,
//         studentAttendance: studentAttendanceMap,
//         markedBy: teacher.uid,
//         createdAt: DateTime.now(),
//       );

//       final result = await databaseService.markAttendance(attendanceRecord);

//       if (result == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'Attendance submitted for ${attendanceState.attendanceMap.values.where((present) => present).length}/${students.length} students',
//             ),
//             backgroundColor: Colors.green,
//           ),
//         );

//         attendanceState.clearAttendance();
//         attendanceState.setIsSubmitting(false);
//       } else {
//         throw Exception(result);
//       }
//     } catch (e) {
//       attendanceState.setIsSubmitting(false);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error submitting attendance: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

// // Separate widget for student card to prevent unnecessary rebuilds
// class _StudentAttendanceCard extends StatelessWidget {
//   final StudentModel student;
//   final bool isPresent;
//   final bool isToggleEnabled;
//   final bool isTablet;
//   final String? markAllType;
//   final ValueChanged<bool> onAttendanceChanged;

//   const _StudentAttendanceCard({
//     required this.student,
//     required this.isPresent,
//     required this.isToggleEnabled,
//     required this.isTablet,
//     required this.markAllType,
//     required this.onAttendanceChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Theme.of(context).colorScheme.primary,
//           child: Text(
//             student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
//             style: TextStyle(
//               color: Theme.of(context).colorScheme.onPrimary,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         title: Text(
//           student.name,
//           style: TextStyle(
//             fontSize: isTablet ? 16 : 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         subtitle: Text(
//           'Roll No: ${student.rollNumber}',
//           style: TextStyle(fontSize: isTablet ? 14 : 12),
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (!isToggleEnabled)
//               Icon(
//                 isPresent ? Icons.check_circle : Icons.cancel,
//                 color: isPresent ? Colors.green : Colors.red,
//                 size: 28,
//               ),
//             if (isToggleEnabled)
//               Switch(
//                 value: isPresent,
//                 onChanged: (value) => onAttendanceChanged(value),
//                 activeColor: Theme.of(context).colorScheme.primary,
//               ),
//           ],
//         ),
//         onTap: isToggleEnabled ? () => onAttendanceChanged(!isPresent) : null,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/responsive_helper.dart';

// State management classes
class AttendanceState extends ChangeNotifier {
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  final Map<String, bool> _attendanceMap = {};
  bool _allMarked = false;
  String? _markAllType;
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<StudentModel> _currentStudents = [];
  bool _attendanceLoaded = false;

  // Getters
  String? get selectedClassId => _selectedClassId;
  DateTime get selectedDate => _selectedDate;
  Map<String, bool> get attendanceMap => _attendanceMap;
  bool get allMarked => _allMarked;
  String? get markAllType => _markAllType;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<StudentModel> get currentStudents => _currentStudents;
  bool get attendanceLoaded => _attendanceLoaded;

  // Setters with safe notification
  void setSelectedClassId(String? value, {bool notify = true}) {
    _selectedClassId = value;
    _attendanceMap.clear();
    _allMarked = false;
    _markAllType = null;
    _attendanceLoaded = false;
    _currentStudents.clear();
    if (notify) _safeNotify();
  }

  void setSelectedDate(DateTime value, {bool notify = true}) {
    _selectedDate = value;
    _attendanceMap.clear();
    _allMarked = false;
    _markAllType = null;
    _attendanceLoaded = false;
    if (notify) _safeNotify();
  }

  void setIsLoading(bool value, {bool notify = true}) {
    _isLoading = value;
    if (notify) _safeNotify();
  }

  void setIsSubmitting(bool value, {bool notify = true}) {
    _isSubmitting = value;
    if (notify) _safeNotify();
  }

  void setAttendanceLoaded(bool value, {bool notify = true}) {
    _attendanceLoaded = value;
    if (notify) _safeNotify();
  }

  // Safe notification method
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Methods
  void setAttendance(String studentId, bool value, {bool notify = true}) {
    _attendanceMap[studentId] = value;
    if (notify) _safeNotify();
  }

  bool getAttendance(String studentId) {
    return _attendanceMap[studentId] ?? false;
  }

  void markAllStudents(List<StudentModel> students, bool isPresent,
      {bool notify = true}) {
    for (final student in students) {
      _attendanceMap[student.uid] = isPresent;
    }
    _allMarked = true;
    _markAllType = isPresent ? 'present' : 'absent';
    if (notify) _safeNotify();
  }

  void setCurrentStudents(List<StudentModel> students, {bool notify = true}) {
    _currentStudents = students;
    if (notify) _safeNotify();
  }

  void clearAttendance({bool notify = true}) {
    _attendanceMap.clear();
    _allMarked = false;
    _markAllType = null;
    if (notify) _safeNotify();
  }

  // Batch update method to reduce notifications
  void batchUpdate(void Function() updates, {bool notify = true}) {
    updates();
    if (notify) _safeNotify();
  }
}

class CalendarState extends ChangeNotifier {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedCalendarDate = DateTime.now();
  Map<DateTime, List<AttendanceModel>> _attendanceEvents = {};
  Map<String, Map<DateTime, AttendanceStatus>> _studentAttendanceHistory = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoadingCalendar = false;

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedCalendarDate => _selectedCalendarDate;
  Map<DateTime, List<AttendanceModel>> get attendanceEvents =>
      _attendanceEvents;
  Map<String, Map<DateTime, AttendanceStatus>> get studentAttendanceHistory =>
      _studentAttendanceHistory;
  CalendarFormat get calendarFormat => _calendarFormat;
  bool get isLoadingCalendar => _isLoadingCalendar;

  // Safe notification method
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Setters with safe notification
  void setFocusedDay(DateTime value, {bool notify = true}) {
    _focusedDay = value;
    if (notify) _safeNotify();
  }

  void setSelectedCalendarDate(DateTime? value, {bool notify = true}) {
    _selectedCalendarDate = value;
    if (notify) _safeNotify();
  }

  void setCalendarFormat(CalendarFormat value, {bool notify = true}) {
    _calendarFormat = value;
    if (notify) _safeNotify();
  }

  void setIsLoadingCalendar(bool value, {bool notify = true}) {
    _isLoadingCalendar = value;
    if (notify) _safeNotify();
  }

  // Methods
  void processAttendanceData(List<AttendanceModel> attendanceRecords,
      {bool notify = true}) {
    _attendanceEvents.clear();
    _studentAttendanceHistory.clear();

    for (final record in attendanceRecords) {
      final date =
          DateTime(record.date.year, record.date.month, record.date.day);

      if (!_attendanceEvents.containsKey(date)) {
        _attendanceEvents[date] = [];
      }
      _attendanceEvents[date]!.add(record);

      for (final entry in record.studentAttendance.entries) {
        final studentId = entry.key;
        final status = entry.value;

        if (!_studentAttendanceHistory.containsKey(studentId)) {
          _studentAttendanceHistory[studentId] = {};
        }
        _studentAttendanceHistory[studentId]![date] = status;
      }
    }
    if (notify) _safeNotify();
  }

  Map<String, int> calculateMonthlyStats(String studentId) {
    final stats = {'present': 0, 'absent': 0, 'late': 0};

    final studentHistory = _studentAttendanceHistory[studentId];
    if (studentHistory == null) return stats;

    final currentMonth = DateTime(_focusedDay.year, _focusedDay.month);

    for (final entry in studentHistory.entries) {
      final date = entry.key;
      final status = entry.value;

      if (date.year == currentMonth.year && date.month == currentMonth.month) {
        switch (status) {
          case AttendanceStatus.present:
            stats['present'] = stats['present']! + 1;
            break;
          case AttendanceStatus.absent:
            stats['absent'] = stats['absent']! + 1;
            break;
          case AttendanceStatus.late:
            stats['late'] = stats['late']! + 1;
            break;
        }
      }
    }

    return stats;
  }

  AttendanceStatus? getDailyAttendanceStatus(String studentId) {
    if (_selectedCalendarDate == null) return null;

    final studentHistory = _studentAttendanceHistory[studentId];
    if (studentHistory == null) return null;

    final dateKey = DateTime(
      _selectedCalendarDate!.year,
      _selectedCalendarDate!.month,
      _selectedCalendarDate!.day,
    );

    return studentHistory[dateKey];
  }

  void clearData() {
    _attendanceEvents.clear();
    _studentAttendanceHistory.clear();
    _safeNotify();
  }
}

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends State<AttendanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AttendanceState()),
        ChangeNotifierProvider(create: (_) => CalendarState()),
      ],
      child: Scaffold(
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
          future: Provider.of<DatabaseService>(context, listen: false)
              .getTeacher(Provider.of<AuthService>(context).currentUser!.uid),
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
                _buildMarkAttendanceTab(teacher),
                _buildViewRecordsTab(teacher),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMarkAttendanceTab(TeacherModel teacher) {
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Column(
      children: [
        // Class selection and date picker section
        _buildHeaderSection(databaseService, teacher, isTablet),

        // Students list section
        Consumer<AttendanceState>(
          builder: (context, attendanceState, child) {
            if (attendanceState.selectedClassId != null) {
              return Expanded(
                child: _buildStudentsListSection(databaseService, isTablet),
              );
            } else {
              return _buildEmptyState();
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeaderSection(
    DatabaseService databaseService,
    TeacherModel teacher,
    bool isTablet,
  ) {
    return Container(
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
                return _buildNoClassesWarning();
              }

              return Consumer<AttendanceState>(
                builder: (context, attendanceState, child) {
                  return DropdownButtonFormField<String>(
                    value: attendanceState.selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: classes
                        .map(
                          (classModel) => DropdownMenuItem(
                            value: classModel.id,
                            child: Text(classModel.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        attendanceState.setSelectedClassId(value);
                      });
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _buildDatePicker(isTablet),
        ],
      ),
    );
  }

  Widget _buildNoClassesWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No classes available. Please create a class first or contact your administrator.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isTablet) {
    return Consumer<AttendanceState>(
      builder: (context, attendanceState, child) {
        return ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(
            'Date: ${DateFormat('MMM dd, yyyy').format(attendanceState.selectedDate)}',
          ),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: attendanceState.selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                attendanceState.setSelectedDate(date);
              });
            }
          },
        );
      },
    );
  }

  Widget _buildStudentsListSection(
    DatabaseService databaseService,
    bool isTablet,
  ) {
    return Consumer<AttendanceState>(
      builder: (context, attendanceState, child) {
        return StreamBuilder<List<StudentModel>>(
          stream: databaseService
              .getClassStudents(attendanceState.selectedClassId!),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
              return _buildNoStudentsState();
            }

            final students = studentSnapshot.data!;

            // Load attendance only when students change, using post-frame callback
            if (attendanceState.currentStudents != students) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                attendanceState.setCurrentStudents(students, notify: false);
                if (!attendanceState.attendanceLoaded) {
                  _loadExistingAttendance(
                      students, databaseService, attendanceState);
                }
              });
            }

            return Column(
              children: [
                // Control buttons section
                _buildControlButtons(students, isTablet, attendanceState),

                // Students list
                Expanded(
                  child: _buildStudentsListView(
                      students, isTablet, attendanceState),
                ),

                // Submit button
                _buildSubmitButton(
                    students, databaseService, isTablet, attendanceState),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControlButtons(
    List<StudentModel> students,
    bool isTablet,
    AttendanceState attendanceState,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  attendanceState.isLoading || attendanceState.isSubmitting
                      ? null
                      : () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            attendanceState.markAllStudents(students, true);
                          });
                        },
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All Present'),
              style: OutlinedButton.styleFrom(
                backgroundColor: attendanceState.markAllType == 'present'
                    ? Colors.green.withOpacity(0.1)
                    : null,
                side: BorderSide(
                  color: attendanceState.markAllType == 'present'
                      ? Colors.green
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  attendanceState.isLoading || attendanceState.isSubmitting
                      ? null
                      : () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            attendanceState.markAllStudents(students, false);
                          });
                        },
              icon: const Icon(Icons.clear_all),
              label: const Text('Mark All Absent'),
              style: OutlinedButton.styleFrom(
                backgroundColor: attendanceState.markAllType == 'absent'
                    ? Colors.red.withOpacity(0.1)
                    : null,
                side: BorderSide(
                  color: attendanceState.markAllType == 'absent'
                      ? Colors.red
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsListView(
    List<StudentModel> students,
    bool isTablet,
    AttendanceState attendanceState,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return _StudentAttendanceCard(
          student: student,
          isPresent: attendanceState.getAttendance(student.uid),
          isToggleEnabled:
              !attendanceState.allMarked && !attendanceState.isSubmitting,
          isTablet: isTablet,
          markAllType: attendanceState.markAllType,
          onAttendanceChanged: (bool value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              attendanceState.setAttendance(student.uid, value);
            });
          },
        );
      },
    );
  }

  Widget _buildSubmitButton(
    List<StudentModel> students,
    DatabaseService databaseService,
    bool isTablet,
    AttendanceState attendanceState,
  ) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (attendanceState.isLoading ||
                  attendanceState.isSubmitting ||
                  attendanceState.attendanceMap.isEmpty)
              ? null
              : () =>
                  _submitAttendance(students, databaseService, attendanceState),
          icon: attendanceState.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: attendanceState.isSubmitting
              ? const Text('Submitting...')
              : const Text('Submit Attendance'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildNoStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outlined,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a class to mark attendance',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRecordsTab(TeacherModel teacher) {
    final databaseService = Provider.of<DatabaseService>(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: StreamBuilder<List<ClassModel>>(
            stream: databaseService.getTeacherClasses(teacher.uid),
            builder: (context, classSnapshot) {
              if (!classSnapshot.hasData) return const SizedBox();
              final classes = classSnapshot.data!;
              if (classes.isEmpty) return _buildNoClassesWarning();

              return Consumer<AttendanceState>(
                builder: (context, attendanceState, child) {
                  return DropdownButtonFormField<String>(
                    value: attendanceState.selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Select Class to View Records',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: classes
                        .map(
                          (classModel) => DropdownMenuItem(
                            value: classModel.id,
                            child: Text(classModel.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        attendanceState.setSelectedClassId(value);
                        final calendarState =
                            Provider.of<CalendarState>(context, listen: false);
                        calendarState.clearData();
                        calendarState.setSelectedCalendarDate(DateTime.now());
                        calendarState.setFocusedDay(DateTime.now());
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        Consumer<AttendanceState>(
          builder: (context, attendanceState, child) {
            if (attendanceState.selectedClassId != null) {
              return Expanded(
                child: _buildRecordsList(isTablet, databaseService),
              );
            } else {
              return _buildEmptyState();
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecordsList(bool isTablet, DatabaseService databaseService) {
    return Consumer2<AttendanceState, CalendarState>(
      builder: (context, attendanceState, calendarState, child) {
        return Column(
          children: [
            // 📅 Calendar Section
            _buildCalendarSection(
                isTablet, databaseService, attendanceState, calendarState),

            const SizedBox(height: 8),

            // 👇 Student Records Section
            _buildStudentRecordsHeader(isTablet, calendarState),
            const SizedBox(height: 8),

            // Student List
            _buildStudentRecordsList(
                isTablet, databaseService, attendanceState, calendarState),
          ],
        );
      },
    );
  }

  Widget _buildCalendarSection(
    bool isTablet,
    DatabaseService databaseService,
    AttendanceState attendanceState,
    CalendarState calendarState,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Monthly Attendance Calendar',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildCalendarStreamBuilder(
                  databaseService, attendanceState, calendarState, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarStreamBuilder(
    DatabaseService databaseService,
    AttendanceState attendanceState,
    CalendarState calendarState,
    bool isTablet,
  ) {
    return StreamBuilder<List<AttendanceModel>>(
      stream: databaseService.getAttendanceForClass(
        attendanceState.selectedClassId!,
        DateTime(
            calendarState.focusedDay.year, calendarState.focusedDay.month, 1),
        DateTime(calendarState.focusedDay.year,
            calendarState.focusedDay.month + 1, 0),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Process data only if it's different from current data
          final newData = snapshot.data!;
          final shouldUpdate = _shouldUpdateCalendarData(
              calendarState.attendanceEvents, newData);

          if (shouldUpdate) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              calendarState.processAttendanceData(newData);
            });
          }
        } else if (snapshot.hasError) {
          return _buildIndexErrorWidget();
        }

        return _buildCalendarWidget(calendarState, isTablet);
      },
    );
  }

  bool _shouldUpdateCalendarData(
    Map<DateTime, List<AttendanceModel>> currentEvents,
    List<AttendanceModel> newData,
  ) {
    // Simple check to avoid unnecessary updates
    if (currentEvents.isEmpty && newData.isNotEmpty) return true;
    if (currentEvents.isNotEmpty && newData.isEmpty) return true;

    // Check if the data has actually changed
    final newEventsCount = newData.length;
    final currentEventsCount =
        currentEvents.values.fold(0, (sum, events) => sum + events.length);

    return newEventsCount != currentEventsCount;
  }

  Widget _buildCalendarWidget(CalendarState calendarState, bool isTablet) {
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now(),
      focusedDay: calendarState.focusedDay,
      calendarFormat: calendarState.calendarFormat,
      onFormatChanged: (format) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          calendarState.setCalendarFormat(format);
        });
      },
      selectedDayPredicate: (day) =>
          isSameDay(calendarState.selectedCalendarDate, day),
      onDaySelected: (selectedDay, focusedDay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          calendarState.setSelectedCalendarDate(selectedDay);
          calendarState.setFocusedDay(focusedDay);
        });
      },
      onPageChanged: (focusedDay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          calendarState.setFocusedDay(focusedDay);
        });
      },
      eventLoader: (day) =>
          calendarState
              .attendanceEvents[DateTime(day.year, day.month, day.day)] ??
          [],
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return const SizedBox();

          int presentCount = 0;
          for (final event in events) {
            if (event is AttendanceModel) {
              presentCount += event.studentAttendance.values
                  .where((status) => status == AttendanceStatus.present)
                  .length;
            }
          }

          return Positioned(
            bottom: 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: presentCount > 0 ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
      rowHeight: 32,
      daysOfWeekHeight: 24,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        formatButtonTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        headerMargin: const EdgeInsets.only(bottom: 4),
        titleTextStyle: TextStyle(
          fontSize: isTablet ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        weekendStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStudentRecordsHeader(
      bool isTablet, CalendarState calendarState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Student Attendance Records',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (calendarState.selectedCalendarDate != null)
            Text(
              DateFormat('MMM dd, yyyy')
                  .format(calendarState.selectedCalendarDate!),
              style: TextStyle(
                fontSize: isTablet ? 11 : 9,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentRecordsList(
    bool isTablet,
    DatabaseService databaseService,
    AttendanceState attendanceState,
    CalendarState calendarState,
  ) {
    return Expanded(
      child: StreamBuilder<List<StudentModel>>(
        stream:
            databaseService.getClassStudents(attendanceState.selectedClassId!),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!studentSnapshot.hasData || studentSnapshot.data!.isEmpty) {
            return const Center(child: Text('No students found in this class'));
          }

          final students = studentSnapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16),
            itemCount: students.length,
            itemBuilder: (context, index) => _buildStudentRecordCard(
                students[index], isTablet, calendarState),
          );
        },
      ),
    );
  }

  Widget _buildIndexErrorWidget() {
    return SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Index Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Please create the Firestore index to view attendance records.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Please check the console for the index creation link'),
                ),
              );
            },
            child: const Text('Create Index'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRecordCard(
      StudentModel student, bool isTablet, CalendarState calendarState) {
    final monthlyStats = calendarState.calculateMonthlyStats(student.uid);
    final dailyStatus = calendarState.getDailyAttendanceStatus(student.uid);

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
        trailing: dailyStatus != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(dailyStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(dailyStatus),
                  ),
                ),
                child: Text(
                  dailyStatus.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(dailyStatus),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Monthly Summary (${DateFormat('MMM yyyy').format(calendarState.focusedDay)})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat(
                        'Present', monthlyStats['present'] ?? 0, Colors.green),
                    _buildAttendanceStat(
                        'Absent', monthlyStats['absent'] ?? 0, Colors.red),
                    _buildAttendanceStat(
                        'Late', monthlyStats['late'] ?? 0, Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDailyAttendanceDetails(student.uid, calendarState),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDailyAttendanceDetails(
      String studentId, CalendarState calendarState) {
    final status = calendarState.getDailyAttendanceStatus(studentId);

    if (calendarState.selectedCalendarDate == null) {
      return Text(
        'Select a date to view attendance',
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    if (status == null) {
      return Text(
        'No attendance recorded for ${DateFormat('MMM dd, yyyy').format(calendarState.selectedCalendarDate!)}',
        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: [
        Text(
          'Attendance on ${DateFormat('MMM dd, yyyy').format(calendarState.selectedCalendarDate!)}:',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
    }
  }

  Future<void> _loadExistingAttendance(
    List<StudentModel> students,
    DatabaseService databaseService,
    AttendanceState attendanceState,
  ) async {
    attendanceState.setIsLoading(true, notify: false);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final teacher =
          await databaseService.getTeacher(authService.currentUser!.uid);
      if (teacher == null) return;

      final teacherClasses =
          await databaseService.getTeacherClasses(teacher.uid).first;
      final selectedClass = teacherClasses.firstWhere(
        (cls) => cls.id == attendanceState.selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final existingAttendance = await databaseService.getAttendanceByDate(
        selectedClass.divisionId,
        attendanceState.selectedDate,
      );

      // Use batch update to reduce notifications
      attendanceState.batchUpdate(() {
        if (existingAttendance != null) {
          for (final student in students) {
            final status = existingAttendance.studentAttendance[student.uid];
            final isPresent = status == AttendanceStatus.present;
            attendanceState.setAttendance(student.uid, isPresent,
                notify: false);
          }
        } else {
          for (final student in students) {
            attendanceState.setAttendance(student.uid, false, notify: false);
          }
        }
        attendanceState.setAttendanceLoaded(true, notify: false);
      });
    } catch (e) {
      attendanceState.batchUpdate(() {
        for (final student in students) {
          attendanceState.setAttendance(student.uid, false, notify: false);
        }
        attendanceState.setAttendanceLoaded(true, notify: false);
      });
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          attendanceState.setIsLoading(false);
        });
      }
    }
  }

  void _submitAttendance(
    List<StudentModel> students,
    DatabaseService databaseService,
    AttendanceState attendanceState,
  ) {
    final presentCount =
        attendanceState.attendanceMap.values.where((present) => present).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Attendance'),
        content: Text(
          'Submit attendance for ${DateFormat('MMM dd, yyyy').format(attendanceState.selectedDate)}?\n\n'
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
              await _submitAttendanceToDatabase(
                  students, databaseService, attendanceState);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendanceToDatabase(
    List<StudentModel> students,
    DatabaseService databaseService,
    AttendanceState attendanceState,
  ) async {
    attendanceState.setIsSubmitting(true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final teacher =
          await databaseService.getTeacher(authService.currentUser!.uid);
      if (teacher == null) throw Exception('Teacher not found');

      final teacherClasses =
          await databaseService.getTeacherClasses(teacher.uid).first;
      final selectedClass = teacherClasses.firstWhere(
        (cls) => cls.id == attendanceState.selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final Map<String, AttendanceStatus> studentAttendanceMap = {};
      for (final student in students) {
        final isPresent = attendanceState.getAttendance(student.uid);
        studentAttendanceMap[student.uid] =
            isPresent ? AttendanceStatus.present : AttendanceStatus.absent;
      }

      final attendanceRecord = AttendanceModel(
        id: const Uuid().v4(),
        institutionId: teacher.institutionId,
        divisionId: selectedClass.divisionId,
        classId: attendanceState.selectedClassId!,
        date: attendanceState.selectedDate,
        studentAttendance: studentAttendanceMap,
        markedBy: teacher.uid,
        createdAt: DateTime.now(),
      );

      final result = await databaseService.markAttendance(attendanceRecord);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance submitted for ${attendanceState.attendanceMap.values.where((present) => present).length}/${students.length} students',
            ),
            backgroundColor: Colors.green,
          ),
        );

        attendanceState.clearAttendance();
        attendanceState.setIsSubmitting(false);
      } else {
        throw Exception(result);
      }
    } catch (e) {
      attendanceState.setIsSubmitting(false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Separate widget for student card to prevent unnecessary rebuilds
class _StudentAttendanceCard extends StatelessWidget {
  final StudentModel student;
  final bool isPresent;
  final bool isToggleEnabled;
  final bool isTablet;
  final String? markAllType;
  final ValueChanged<bool> onAttendanceChanged;

  const _StudentAttendanceCard({
    required this.student,
    required this.isPresent,
    required this.isToggleEnabled,
    required this.isTablet,
    required this.markAllType,
    required this.onAttendanceChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isToggleEnabled)
              Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green : Colors.red,
                size: 28,
              ),
            if (isToggleEnabled)
              Switch(
                value: isPresent,
                onChanged: (value) => onAttendanceChanged(value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        onTap: isToggleEnabled ? () => onAttendanceChanged(!isPresent) : null,
      ),
    );
  }
}
