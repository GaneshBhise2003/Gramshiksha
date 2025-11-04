// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../services/database_service.dart';
// import '../../models/student_model.dart';
// import '../../models/quiz_model.dart';
// import '../../models/quiz_attempt_model.dart';
// import '../../utils/responsive_helper.dart';
//
// class StudentQuizzesScreen extends StatefulWidget {
//   final StudentModel student;
//
//   const StudentQuizzesScreen({super.key, required this.student});
//
//   @override
//   State<StudentQuizzesScreen> createState() => _StudentQuizzesScreenState();
// }
//
// class _StudentQuizzesScreenState extends State<StudentQuizzesScreen>
//     with TickerProviderStateMixin {
//   late TabController _tabController;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final databaseService = Provider.of<DatabaseService>(context);
//     final isTablet = ResponsiveHelper.isTablet(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Quizzes'),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         elevation: 0,
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Available', icon: Icon(Icons.quiz_outlined)),
//             Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildAvailableQuizzes(databaseService, isTablet),
//           _buildCompletedQuizzes(databaseService, isTablet),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAvailableQuizzes(
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return StreamBuilder<List<QuizModel>>(
//       stream: databaseService.getClassQuizzes(widget.student.divisionId),
//       builder: (context, quizSnapshot) {
//         if (quizSnapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (!quizSnapshot.hasData || quizSnapshot.data!.isEmpty) {
//           return _buildEmptyState(
//             'No quizzes available',
//             'Your teacher hasn\'t created any quizzes yet.',
//             Icons.quiz_outlined,
//           );
//         }
//
//         return StreamBuilder<List<QuizAttemptModel>>(
//           stream: databaseService.getStudentAllQuizAttempts(widget.student.uid),
//           builder: (context, attemptSnapshot) {
//             final attempts = attemptSnapshot.data ?? [];
//             final completedQuizIds = attempts.map((a) => a.quizId).toSet();
//
//             final availableQuizzes =
//                 quizSnapshot.data!
//                     .where((quiz) => !completedQuizIds.contains(quiz.id))
//                     .toList();
//
//             if (availableQuizzes.isEmpty) {
//               return _buildEmptyState(
//                 'All quizzes completed!',
//                 'Great job! You\'ve completed all available quizzes.',
//                 Icons.task_alt,
//               );
//             }
//
//             return RefreshIndicator(
//               onRefresh: () async => setState(() {}),
//               child: ListView.builder(
//                 padding: EdgeInsets.all(isTablet ? 24 : 16),
//                 itemCount: availableQuizzes.length,
//                 itemBuilder: (context, index) {
//                   return _buildQuizCard(
//                     availableQuizzes[index],
//                     isTablet,
//                     isCompleted: false,
//                   );
//                 },
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildCompletedQuizzes(
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return StreamBuilder<List<QuizAttemptModel>>(
//       stream: databaseService.getStudentAllQuizAttempts(widget.student.uid),
//       builder: (context, attemptSnapshot) {
//         if (attemptSnapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (!attemptSnapshot.hasData || attemptSnapshot.data!.isEmpty) {
//           return _buildEmptyState(
//             'No completed quizzes',
//             'Your completed quiz attempts will appear here.',
//             Icons.history_edu,
//           );
//         }
//
//         return StreamBuilder<List<QuizModel>>(
//           stream: databaseService.getClassQuizzes(widget.student.divisionId),
//           builder: (context, quizSnapshot) {
//             if (!quizSnapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }
//
//             final quizzes = quizSnapshot.data!;
//             final attempts = attemptSnapshot.data!;
//
//             return RefreshIndicator(
//               onRefresh: () async => setState(() {}),
//               child: ListView.builder(
//                 padding: EdgeInsets.all(isTablet ? 24 : 16),
//                 itemCount: attempts.length,
//                 itemBuilder: (context, index) {
//                   final attempt = attempts[index];
//                   final quiz = quizzes.firstWhere(
//                     (q) => q.id == attempt.quizId,
//                     orElse:
//                         () => QuizModel(
//                           id: attempt.quizId,
//                           title: 'Unknown Quiz',
//                           questions: [],
//                           teacherId: '',
//                           divisionId: '',
//                           institutionId: '',
//                           classId: '',
//                           totalMarks: 0,
//                           timeLimit: 0,
//                           isActive: false,
//                           createdAt: DateTime.now(),
//                         ),
//                   );
//
//                   return _buildCompletedQuizCard(quiz, attempt, isTablet);
//                 },
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _buildEmptyState(String title, String subtitle, IconData icon) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             size: 80,
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildQuizCard(
//     QuizModel quiz,
//     bool isTablet, {
//     required bool isCompleted,
//   }) {
//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
//       elevation: 2,
//       child: InkWell(
//         onTap: () => _showQuizDetails(quiz),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: EdgeInsets.all(isTablet ? 20 : 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           quiz.title,
//                           style: TextStyle(
//                             fontSize: isTablet ? 18 : 16,
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.onSurface,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           '${quiz.questions.length} questions • ${quiz.timeLimit} min',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontSize: isTablet ? 14 : 12,
//                             color: Theme.of(
//                               context,
//                             ).colorScheme.onSurface.withOpacity(0.7),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.quiz, size: 14, color: Colors.blue),
//                         SizedBox(width: 4),
//                         Text(
//                           'Available',
//                           style: TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.blue,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   _buildInfoChip(
//                     Icons.help_outline,
//                     '${quiz.questions.length} questions',
//                   ),
//                   const SizedBox(width: 16),
//                   _buildInfoChip(Icons.timer, '${quiz.timeLimit} min'),
//                   const SizedBox(width: 16),
//                   _buildInfoChip(Icons.stars, '${quiz.totalMarks} marks'),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCompletedQuizCard(
//     QuizModel quiz,
//     QuizAttemptModel attempt,
//     bool isTablet,
//   ) {
//     final percentage =
//         quiz.totalMarks > 0
//             ? (attempt.score / quiz.totalMarks * 100).round()
//             : 0;
//
//     Color scoreColor;
//     if (percentage >= 80) {
//       scoreColor = Colors.green;
//     } else if (percentage >= 60) {
//       scoreColor = Colors.orange;
//     } else {
//       scoreColor = Colors.red;
//     }
//
//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
//       elevation: 2,
//       child: InkWell(
//         onTap: () => _showCompletedQuizDetails(quiz, attempt),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: EdgeInsets.all(isTablet ? 20 : 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           quiz.title,
//                           style: TextStyle(
//                             fontSize: isTablet ? 18 : 16,
//                             fontWeight: FontWeight.bold,
//                             color: Theme.of(context).colorScheme.onSurface,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Completed on ${DateFormat('MMM dd, yyyy').format(attempt.completedAt)}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Theme.of(
//                               context,
//                             ).colorScheme.onSurface.withOpacity(0.6),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: scoreColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: scoreColor.withOpacity(0.3)),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           '$percentage%',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: scoreColor,
//                           ),
//                         ),
//                         Text(
//                           '${attempt.score}/${quiz.totalMarks}',
//                           style: TextStyle(fontSize: 10, color: scoreColor),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   _buildInfoChip(
//                     Icons.help_outline,
//                     '${quiz.questions.length} questions',
//                   ),
//                   const SizedBox(width: 16),
//                   _buildInfoChip(Icons.timer, '${quiz.timeLimit} min'),
//                   const Spacer(),
//                   Icon(
//                     Icons.chevron_right,
//                     color: Theme.of(
//                       context,
//                     ).colorScheme.onSurface.withOpacity(0.5),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoChip(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           icon,
//           size: 14,
//           color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
//         ),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 12,
//             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
//           ),
//         ),
//       ],
//     );
//   }
//
//   void _showQuizDetails(QuizModel quiz) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => QuizDetailsDialog(quiz: quiz, student: widget.student),
//     );
//   }
//
//   void _showCompletedQuizDetails(QuizModel quiz, QuizAttemptModel attempt) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => CompletedQuizDetailsDialog(quiz: quiz, attempt: attempt),
//     );
//   }
// }
//
// class QuizDetailsDialog extends StatefulWidget {
//   final QuizModel quiz;
//   final StudentModel student;
//
//   const QuizDetailsDialog({
//     super.key,
//     required this.quiz,
//     required this.student,
//   });
//
//   @override
//   State<QuizDetailsDialog> createState() => _QuizDetailsDialogState();
// }
//
// class _QuizDetailsDialogState extends State<QuizDetailsDialog> {
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         height: MediaQuery.of(context).size.height * 0.7,
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     widget.quiz.title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             // Quiz Details
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildDetailRow(
//                       'Description',
//                       'Interactive quiz with ${widget.quiz.questions.length} questions',
//                     ),
//                     _buildDetailRow(
//                       'Number of Questions',
//                       widget.quiz.questions.length.toString(),
//                     ),
//                     _buildDetailRow(
//                       'Duration',
//                       '${widget.quiz.timeLimit} minutes',
//                     ),
//                     _buildDetailRow(
//                       'Total Marks',
//                       widget.quiz.totalMarks.toString(),
//                     ),
//                     _buildDetailRow(
//                       'Created',
//                       DateFormat('MMM dd, yyyy').format(widget.quiz.createdAt),
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue.withOpacity(0.3)),
//                       ),
//                       child: const Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Icon(Icons.info, color: Colors.blue, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Instructions',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 12),
//                           Text(
//                             '• Answer all questions to the best of your ability\n'
//                             '• You can only take this quiz once\n'
//                             '• Make sure you have a stable internet connection\n'
//                             '• Submit before the time runs out',
//                             style: TextStyle(fontSize: 14),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Start Quiz Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => _startQuiz(),
//                 icon: const Icon(Icons.play_arrow),
//                 label: const Text('Start Quiz'),
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(value, style: const TextStyle(fontSize: 14)),
//         ],
//       ),
//     );
//   }
//
//   void _startQuiz() {
//     Navigator.of(context).pop();
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder:
//             (context) =>
//                 QuizTakingScreen(quiz: widget.quiz, student: widget.student),
//       ),
//     );
//   }
// }
//
// class CompletedQuizDetailsDialog extends StatelessWidget {
//   final QuizModel quiz;
//   final QuizAttemptModel attempt;
//
//   const CompletedQuizDetailsDialog({
//     super.key,
//     required this.quiz,
//     required this.attempt,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final percentage =
//         quiz.totalMarks > 0
//             ? (attempt.score / quiz.totalMarks * 100).round()
//             : 0;
//
//     Color scoreColor;
//     String grade;
//     if (percentage >= 90) {
//       scoreColor = Colors.green;
//       grade = 'A+';
//     } else if (percentage >= 80) {
//       scoreColor = Colors.green;
//       grade = 'A';
//     } else if (percentage >= 70) {
//       scoreColor = Colors.orange;
//       grade = 'B';
//     } else if (percentage >= 60) {
//       scoreColor = Colors.orange;
//       grade = 'C';
//     } else {
//       scoreColor = Colors.red;
//       grade = 'D';
//     }
//
//     return Dialog(
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         height: MediaQuery.of(context).size.height * 0.6,
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     quiz.title,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//
//             // Score Display
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: scoreColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: scoreColor.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '$percentage%',
//                       style: TextStyle(
//                         fontSize: 48,
//                         fontWeight: FontWeight.bold,
//                         color: scoreColor,
//                       ),
//                     ),
//                     Text(
//                       'Grade: $grade',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: scoreColor,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${attempt.score} out of ${quiz.totalMarks} marks',
//                       style: TextStyle(fontSize: 14, color: scoreColor),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Details
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   children: [
//                     _buildDetailRow(
//                       'Submitted On',
//                       DateFormat(
//                         'EEEE, MMMM dd, yyyy at HH:mm',
//                       ).format(attempt.completedAt),
//                     ),
//                     _buildDetailRow(
//                       'Time Taken',
//                       _formatDuration(Duration(seconds: attempt.timeTaken)),
//                     ),
//                     _buildDetailRow(
//                       'Questions',
//                       '${quiz.questions.length} questions',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey,
//               ),
//             ),
//           ),
//           Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }
//
//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes;
//     final seconds = duration.inSeconds % 60;
//     return '${minutes}m ${seconds}s';
//   }
// }
//
// class QuizTakingScreen extends StatefulWidget {
//   final QuizModel quiz;
//   final StudentModel student;
//
//   const QuizTakingScreen({
//     super.key,
//     required this.quiz,
//     required this.student,
//   });
//
//   @override
//   State<QuizTakingScreen> createState() => _QuizTakingScreenState();
// }
//
// class _QuizTakingScreenState extends State<QuizTakingScreen> {
//   PageController _pageController = PageController();
//   Map<String, String> _answers = {};
//   int _currentQuestionIndex = 0;
//
//   bool _isSubmitting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Quiz started at: DateTime.now()
//     _pageController = PageController();
//   }
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final question = widget.quiz.questions[_currentQuestionIndex];
//
//     return WillPopScope(
//       onWillPop: () async {
//         return await _showExitDialog();
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(widget.quiz.title),
//           backgroundColor: Theme.of(context).colorScheme.surface,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () async {
//               if (await _showExitDialog()) {
//                 Navigator.of(context).pop();
//               }
//             },
//           ),
//           actions: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Progress Bar
//               LinearProgressIndicator(
//                 value:
//                     (_currentQuestionIndex + 1) / widget.quiz.questions.length,
//                 backgroundColor: Colors.grey.withOpacity(0.3),
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Question
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         question.question,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//
//                       // Options
//                       ...question.options.asMap().entries.map((entry) {
//                         final index = entry.key;
//                         final option = entry.value;
//                         final optionKey = String.fromCharCode(
//                           65 + index,
//                         ); // A, B, C, D
//                         final isSelected = _answers[question.id] == optionKey;
//
//                         return GestureDetector(
//                           onTap: () => _selectAnswer(question.id, optionKey),
//                           child: Container(
//                             width: double.infinity,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color:
//                                   isSelected
//                                       ? Theme.of(
//                                         context,
//                                       ).colorScheme.primary.withOpacity(0.1)
//                                       : Colors.transparent,
//                               border: Border.all(
//                                 color:
//                                     isSelected
//                                         ? Theme.of(context).colorScheme.primary
//                                         : Colors.grey.withOpacity(0.3),
//                                 width: 2,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 32,
//                                   height: 32,
//                                   decoration: BoxDecoration(
//                                     color:
//                                         isSelected
//                                             ? Theme.of(
//                                               context,
//                                             ).colorScheme.primary
//                                             : Colors.transparent,
//                                     border: Border.all(
//                                       color:
//                                           isSelected
//                                               ? Theme.of(
//                                                 context,
//                                               ).colorScheme.primary
//                                               : Colors.grey,
//                                     ),
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   child: Center(
//                                     child: Text(
//                                       optionKey,
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color:
//                                             isSelected
//                                                 ? Colors.white
//                                                 : Colors.grey,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Text(
//                                     option,
//                                     style: const TextStyle(fontSize: 16),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Navigation Buttons
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   if (_currentQuestionIndex > 0)
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: _previousQuestion,
//                         icon: const Icon(Icons.arrow_back),
//                         label: const Text('Previous'),
//                       ),
//                     ),
//                   if (_currentQuestionIndex > 0) const SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed:
//                           _isSubmitting
//                               ? null
//                               : (_currentQuestionIndex <
//                                       widget.quiz.questions.length - 1
//                                   ? _nextQuestion
//                                   : _submitQuiz),
//                       icon:
//                           _isSubmitting
//                               ? const SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                               : Icon(
//                                 _currentQuestionIndex <
//                                         widget.quiz.questions.length - 1
//                                     ? Icons.arrow_forward
//                                     : Icons.check,
//                               ),
//                       label: Text(
//                         _currentQuestionIndex < widget.quiz.questions.length - 1
//                             ? 'Next'
//                             : 'Submit',
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _selectAnswer(String questionId, String answer) {
//     setState(() {
//       _answers[questionId] = answer;
//     });
//   }
//
//   void _nextQuestion() {
//     if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
//       setState(() {
//         _currentQuestionIndex++;
//       });
//       _pageController.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }
//
//   void _previousQuestion() {
//     if (_currentQuestionIndex > 0) {
//       setState(() {
//         _currentQuestionIndex--;
//       });
//       _pageController.previousPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//     }
//   }
//
//   Future<void> _submitQuiz() async {
//     setState(() => _isSubmitting = true);
//
//     final databaseService = Provider.of<DatabaseService>(
//       context,
//       listen: false,
//     );
//
//     // Calculate score
//     int score = 0;
//     for (final question in widget.quiz.questions) {
//       if (_answers[question.id] == question.correctAnswer) {
//         score += question.marks;
//       }
//     }
//
//     final attemptId = DateTime.now().millisecondsSinceEpoch.toString();
//
//     final error = await databaseService.submitQuiz(attemptId, _answers, score);
//
//     setState(() => _isSubmitting = false);
//
//     if (error == null) {
//       if (context.mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Quiz submitted successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } else {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to submit quiz: $error'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   Future<bool> _showExitDialog() async {
//     return await showDialog<bool>(
//           context: context,
//           builder:
//               (context) => AlertDialog(
//                 title: const Text('Exit Quiz?'),
//                 content: const Text(
//                   'Are you sure you want to exit? Your progress will be lost.',
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(false),
//                     child: const Text('Cancel'),
//                   ),
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(true),
//                     child: const Text(
//                       'Exit',
//                       style: TextStyle(color: Colors.red),
//                     ),
//                   ),
//                 ],
//               ),
//         ) ??
//         false;
//   }
// }


import 'package:flutter/material.dart';
import 'package:gramshiksha/screens/student/quiz_card_components.dart';
import 'package:gramshiksha/screens/student/quiz_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/quiz_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../utils/responsive_helper.dart';
import 'quiz_taking_screen.dart';

class StudentQuizzesScreen extends StatefulWidget {
  final StudentModel student;

  const StudentQuizzesScreen({super.key, required this.student});

  @override
  State<StudentQuizzesScreen> createState() => _StudentQuizzesScreenState();
}

class _StudentQuizzesScreenState extends State<StudentQuizzesScreen>
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
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.quiz_outlined)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AvailableQuizzesTab(student: widget.student, isTablet: isTablet),
          _CompletedQuizzesTab(student: widget.student, isTablet: isTablet),
        ],
      ),
    );
  }
}

class _AvailableQuizzesTab extends StatelessWidget {
  final StudentModel student;
  final bool isTablet;

  const _AvailableQuizzesTab({
    required this.student,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<QuizModel>>(
      stream: databaseService.getClassQuizzes(student.divisionId),
      builder: (context, quizSnapshot) {
        debugPrint("📘 getClassQuizzes called with divisionId: ${student.divisionId}");

        if (quizSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint("⏳ quizSnapshot is still loading...");
          return const Center(child: CircularProgressIndicator());
        }

        if (quizSnapshot.hasError) {
          debugPrint("❌ quizSnapshot error: ${quizSnapshot.error}");
        }

        if (!quizSnapshot.hasData || quizSnapshot.data!.isEmpty) {
          debugPrint("⚠️ No quizzes found for divisionId: ${student.divisionId}");
          return _EmptyState(
            icon: Icons.quiz_outlined,
            title: 'No quizzes available',
            subtitle: 'Your teacher hasn\'t created any quizzes yet.',
          );
        }

        debugPrint("✅ quizSnapshot loaded: ${quizSnapshot.data!.length} quizzes found");

        return StreamBuilder<List<QuizAttemptModel>>(
          stream: databaseService.getStudentQuizAttempts(student.uid),
          builder: (context, attemptSnapshot) {
            debugPrint("📗 getStudentQuizAttempts called with uid: ${student.uid}");

            if (attemptSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint("⏳ attemptSnapshot is still loading...");
              return const Center(child: CircularProgressIndicator());
            }

            if (attemptSnapshot.hasError) {
              debugPrint("❌ attemptSnapshot error: ${attemptSnapshot.error}");
            }

            final attempts = attemptSnapshot.data ?? [];
            debugPrint("✅ attemptSnapshot loaded: ${attempts.length} attempts found");

            final completedQuizIds = attempts.map((a) => a.quizId).toSet();
            debugPrint("🎯 completedQuizIds: $completedQuizIds");

            final availableQuizzes = quizSnapshot.data!
                .where((quiz) => !completedQuizIds.contains(quiz.id))
                .toList();

            debugPrint("🧮 availableQuizzes count: ${availableQuizzes.length}");

            if (availableQuizzes.isEmpty) {
              debugPrint("🏁 All quizzes completed by student: ${student.uid}");
              return _EmptyState(
                icon: Icons.task_alt,
                title: 'All quizzes completed!',
                subtitle: 'Great job! You\'ve completed all available quizzes.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                debugPrint("🔁 Refresh triggered");
              },
              child: ListView.separated(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                itemCount: availableQuizzes.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: isTablet ? 16 : 12),
                itemBuilder: (context, index) {
                  final quiz = availableQuizzes[index];
                  debugPrint("📝 Building QuizCard for quiz: ${quiz.id} (${quiz.title})");

                  return QuizCard(
                    quiz: quiz,
                    isTablet: isTablet,
                    status: QuizStatus.available,
                    onTap: () {
                      debugPrint("👉 Quiz tapped: ${quiz.id}");
                      _showQuizDetails(context, quiz);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );

  }

  void _showQuizDetails(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => QuizDetailsDialog(quiz: quiz, student: student),
    );
  }
}

class _CompletedQuizzesTab extends StatelessWidget {
  final StudentModel student;
  final bool isTablet;

  const _CompletedQuizzesTab({
    required this.student,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<QuizAttemptModel>>(
      stream: databaseService.getStudentQuizAttempts(student.uid),
      builder: (context, attemptSnapshot) {
        debugPrint("📗 getStudentQuizAttempts() called with uid: ${student.uid}");

        if (attemptSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint("⏳ attemptSnapshot loading...");
          return const Center(child: CircularProgressIndicator());
        }

        if (attemptSnapshot.hasError) {
          debugPrint("❌ attemptSnapshot error: ${attemptSnapshot.error}");
        }

        if (!attemptSnapshot.hasData || attemptSnapshot.data!.isEmpty) {
          debugPrint("⚠️ No completed quizzes found for student: ${student.uid}");
          return _EmptyState(
            icon: Icons.history_edu,
            title: 'No completed quizzes',
            subtitle: 'Your completed quiz attempts will appear here.',
          );
        }

        final attempts = attemptSnapshot.data!;
        debugPrint("✅ ${attempts.length} quiz attempts found for student: ${student.uid}");
        debugPrint("🧾 Attempt IDs: ${attempts.map((a) => a.quizId).join(', ')}");

        return StreamBuilder<List<QuizModel>>(
          stream: databaseService.getClassQuizzes(student.divisionId),
          builder: (context, quizSnapshot) {
            debugPrint("📘 getClassQuizzes() called with divisionId: ${student.divisionId}");

            if (quizSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint("⏳ quizSnapshot loading...");
              return const Center(child: CircularProgressIndicator());
            }

            if (quizSnapshot.hasError) {
              debugPrint("❌ quizSnapshot error: ${quizSnapshot.error}");
            }

            final quizzes = quizSnapshot.data ?? [];
            debugPrint("✅ ${quizzes.length} quizzes found for divisionId: ${student.divisionId}");
            debugPrint("🧩 Quiz IDs: ${quizzes.map((q) => q.id).join(', ')}");

            // Create a map for quick lookup
            final quizMap = {for (var q in quizzes) q.id: q};

            return RefreshIndicator(
              onRefresh: () async {
                debugPrint("🔁 Refresh triggered on completed quizzes page");
              },
              child: ListView.separated(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                itemCount: attempts.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: isTablet ? 16 : 12),
                itemBuilder: (context, index) {
                  final attempt = attempts[index];
                  final quiz = quizMap[attempt.quizId] ??
                      QuizModel.unknown(id: attempt.quizId);

                  debugPrint(
                      "🧠 Building CompletedQuizCard → quizId: ${attempt.quizId}, quizTitle: ${quiz.title}, score: ${attempt.score ?? 'N/A'}");

                  return CompletedQuizCard(
                    quiz: quiz,
                    attempt: attempt,
                    isTablet: isTablet,
                    onTap: () {
                      debugPrint(
                          "👉 Quiz tapped: ${quiz.id} | Attempt ID: ${attempt.id}");
                      _showQuizResults(context, quiz, attempt);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );

  }

  void _showQuizResults(
      BuildContext context,
      QuizModel quiz,
      QuizAttemptModel attempt,
      ) {
    showDialog(
      context: context,
      builder: (context) => QuizResultsDialog(quiz: quiz, attempt: attempt),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}