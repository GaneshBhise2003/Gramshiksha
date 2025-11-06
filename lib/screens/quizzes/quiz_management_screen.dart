// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';
// import '../../services/database_service.dart';
// import '../../services/auth_service.dart';
// import '../../models/teacher_model.dart';
// import '../../models/quiz_model.dart';
// import '../../models/class_model.dart';
// import '../../utils/responsive_helper.dart';

 

// class QuizManagementScreen extends StatefulWidget {
//   const QuizManagementScreen({super.key});

//   @override
//   State<QuizManagementScreen> createState() => _QuizManagementScreenState();
// }

// class _QuizManagementScreenState extends State<QuizManagementScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String? _selectedClassId;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     final databaseService = Provider.of<DatabaseService>(context);
//     final isTablet = ResponsiveHelper.isTablet(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Quiz Management'),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'All Quizzes', icon: Icon(Icons.quiz)),
//             Tab(text: 'Create', icon: Icon(Icons.add)),
//             Tab(text: 'Results', icon: Icon(Icons.analytics)),
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
//               _buildQuizzesTab(teacher, databaseService, isTablet),
//               _buildCreateQuizTab(teacher, databaseService, isTablet),
//               _buildResultsTab(teacher, databaseService, isTablet),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildQuizzesTab(
//     TeacherModel teacher,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Column(
//       children: [
//         // Search and Filter Bar
//         Container(
//           padding: EdgeInsets.all(isTablet ? 20 : 16),
//           child: Column(
//             children: [
//               TextField(
//                 controller: _searchController,
//                 onChanged: (value) {
//                   setState(() {
//                     _searchQuery = value.toLowerCase();
//                   });
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'Search quizzes...',
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon:
//                       _searchQuery.isNotEmpty
//                           ? IconButton(
//                             icon: const Icon(Icons.clear),
//                             onPressed: () {
//                               _searchController.clear();
//                               setState(() {
//                                 _searchQuery = '';
//                               }
//                             );
//                             },
//                           )
//                           : null,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               // Class Filter
//               StreamBuilder<List<ClassModel>>(
//                 stream: databaseService.getTeacherClasses(teacher.uid),
//                 builder: (context, classSnapshot) {
//                   if (!classSnapshot.hasData) {
//                     return const SizedBox();
//                   }

//                   final classes = classSnapshot.data!;
//                   return DropdownButtonFormField<String>(
//                     value: _selectedClassId,
//                     decoration: const InputDecoration(
//                       labelText: 'Filter by Class',
//                       prefixIcon: Icon(Icons.class_),
//                     ),
//                     items: [
//                       const DropdownMenuItem(
//                         value: null,
//                         child: Text('All Classes'),
//                       ),
//                       ...classes.map(
//                         (classModel) => DropdownMenuItem(
//                           value: classModel.id,
//                           child: Text(classModel.name),
//                         ),
//                       ),
//                     ],
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedClassId = value;
//                       });
//                     },
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//         // Quizzes List
//         Expanded(
//           child: StreamBuilder<List<QuizModel>>(
//             stream: databaseService.getTeacherQuizzes(teacher.uid),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.quiz_outlined,
//                         size: 64,
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.onSurface.withOpacity(0.5),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No quizzes found',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.7),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Create your first quiz to get started',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Theme.of(
//                             context,
//                           ).colorScheme.onSurface.withOpacity(0.5),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               var quizzes = snapshot.data!;

//               // Apply filters
//               if (_selectedClassId != null) {
//                 quizzes =
//                     quizzes
//                         .where((quiz) => quiz.classId == _selectedClassId)
//                         .toList();
//               }

//               if (_searchQuery.isNotEmpty) {
//                 quizzes =
//                     quizzes.where((quiz) {
//                       return quiz.title.toLowerCase().contains(_searchQuery);
//                     }).toList();
//               }

//               return RefreshIndicator(
//                 onRefresh: () async {
//                   setState(() {});
//                 },
//                 child: ListView.builder(
//                   padding: EdgeInsets.all(isTablet ? 20 : 16),
//                   itemCount: quizzes.length,
//                   itemBuilder: (context, index) {
//                     final quiz = quizzes[index];
//                     return _buildQuizCard(quiz, databaseService, isTablet);
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuizCard(
//     QuizModel quiz,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Card(
//       margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
//       child: InkWell(
//         onTap: () => _showQuizDetails(quiz, databaseService),
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
//                           '${quiz.questions.length} Questions',
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
//                   PopupMenuButton(
//                     itemBuilder:
//                         (context) => [
//                           const PopupMenuItem(
//                             value: 'edit',
//                             child: ListTile(
//                               leading: Icon(Icons.edit),
//                               title: Text('Edit'),
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                           const PopupMenuItem(
//                             value: 'results',
//                             child: ListTile(
//                               leading: Icon(Icons.analytics),
//                               title: Text('View Results'),
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                           const PopupMenuItem(
//                             value: 'delete',
//                             child: ListTile(
//                               leading: Icon(Icons.delete),
//                               title: Text('Delete'),
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                         ],
//                     onSelected: (value) {
//                       switch (value) {
//                         case 'edit':
//                           _editQuiz(quiz, databaseService);
//                           break;
//                         case 'results':
//                           _viewResults(quiz, databaseService);
//                           break;
//                         case 'delete':
//                           _deleteQuiz(quiz, databaseService);
//                           break;
//                       }
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.schedule,
//                     size: 16,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${quiz.timeLimit} minutes',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                   const Spacer(),
//                   Text(
//                     '${quiz.totalMarks} marks',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.onSurface.withOpacity(0.6),
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

//   Widget _buildCreateQuizTab(
//     TeacherModel teacher,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return _CreateQuizForm(
//       teacher: teacher,
//       databaseService: databaseService,
//       isTablet: isTablet,
//     );
//   }

//   Widget _buildResultsTab(
//     TeacherModel teacher,
//     DatabaseService databaseService,
//     bool isTablet,
//   ) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.analytics,
//             size: 64,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'Quiz Results & Analytics',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Detailed analytics and results coming soon!',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showQuizDetails(QuizModel quiz, DatabaseService databaseService) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             child: Container(
//               width: ResponsiveHelper.isDesktop(context) ? 600 : null,
//               constraints: const BoxConstraints(maxHeight: 600),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   AppBar(
//                     title: Text(quiz.title),
//                     automaticallyImplyLeading: false,
//                     actions: [
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Time Limit',
//                                       style:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.titleSmall,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text('${quiz.timeLimit} minutes'),
//                                   ],
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       'Total Marks',
//                                       style:
//                                           Theme.of(
//                                             context,
//                                           ).textTheme.titleSmall,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text('${quiz.totalMarks}'),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 20),
//                           Text(
//                             'Questions (${quiz.questions.length})',
//                             style: Theme.of(context).textTheme.titleMedium,
//                           ),
//                           const SizedBox(height: 12),
//                           if (quiz.questions.isEmpty)
//                             const Text('No questions added yet')
//                           else
//                             ...quiz.questions.asMap().entries.map((entry) {
//                               final index = entry.key;
//                               final question = entry.value;
//                               return Card(
//                                 margin: const EdgeInsets.only(bottom: 8),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(12),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Q${index + 1}. ${question.question}',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         'Type: ${question.type.toString().split('.').last}',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Theme.of(context)
//                                               .colorScheme
//                                               .onSurface
//                                               .withOpacity(0.6),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }),
//                           const SizedBox(height: 20),
//                           Text(
//                             'Created',
//                             style: Theme.of(context).textTheme.titleSmall,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             DateFormat(
//                               'MMM dd, yyyy hh:mm a',
//                             ).format(quiz.createdAt),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   void _editQuiz(QuizModel quiz, DatabaseService databaseService) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Edit quiz feature coming soon!')),
//     );
//   }

//   void _viewResults(QuizModel quiz, DatabaseService databaseService) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Quiz results feature coming soon!')),
//     );
//   }

//   void _deleteQuiz(QuizModel quiz, DatabaseService databaseService) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Delete Quiz'),
//             content: Text(
//               'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Delete quiz feature coming soon!'),
//                     ),
//                   );
//                 },
//                 child: const Text(
//                   'Delete',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }
// }

// // Quiz Creation Form
// class _CreateQuizForm extends StatefulWidget {
//   final TeacherModel teacher;
//   final DatabaseService databaseService;
//   final bool isTablet;

//   const _CreateQuizForm({
//     required this.teacher,
//     required this.databaseService,
//     required this.isTablet,
//   });

//   @override
//   State<_CreateQuizForm> createState() => __CreateQuizFormState();
// }

// class __CreateQuizFormState extends State<_CreateQuizForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _titleController = TextEditingController();
//   final _timeLimitController = TextEditingController(text: '30');
//   final _totalMarksController = TextEditingController(text: '100');
//   String? _selectedClassId;
//   List<QuizQuestion> _questions = [];
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _timeLimitController.dispose();
//     _totalMarksController.dispose();
//     super.dispose();
//   }

//   void _addQuestion() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => _QuestionDialog(
//             onSave: (question) {
//               setState(() {
//                 _questions.add(question);
//               });
//               // Dialog is popped inside _QuestionDialog._saveQuestion
//             },
//           ),
//     );
//   }

//   void _editQuestion(int index) {
//     showDialog(
//       context: context,
//       builder:
//           (context) => _QuestionDialog(
//             initialQuestion: _questions[index],
//             onSave: (question) {
//               setState(() {
//                 _questions[index] = question;
//               });
//               // Dialog is popped inside _QuestionDialog._saveQuestion
//             },
//           ),
//     );
//   }

//   void _deleteQuestion(int index) {
//     setState(() {
//       _questions.removeAt(index);
//     });
//   }

//  Future<void> _createQuiz() async {
//   if (!_formKey.currentState!.validate()) return;

//   if (_selectedClassId == null) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Please select a class')));
//     return;
//   }

//   if (_questions.isEmpty) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Please add at least one question')),
//     );
//     return;
//   }

//   setState(() => _isLoading = true);

//   try {
//     // Get the selected class to retrieve its division ID
//     // Note: The `.first` on the stream ensures we await the first emission.
//     final classes =
//         await widget.databaseService
//             .getTeacherClasses(widget.teacher.uid)
//             .first;

//     if (classes.isEmpty) {
//       throw Exception('No classes available. Please create a class first.');
//     }

//     final selectedClass = classes.firstWhere(
//       (c) => c.id == _selectedClassId,
//       orElse: () => throw Exception('Selected class not found'),
//     );

//     final quizId = const Uuid().v4();
//     final quiz = QuizModel(
//       id: quizId,
//       title: _titleController.text.trim(),
//       institutionId: widget.teacher.institutionId,
//       divisionId: selectedClass.divisionId,
//       classId: _selectedClassId!,
//       teacherId: widget.teacher.uid,
//       totalMarks: int.parse(_totalMarksController.text.trim()),
//       timeLimit: int.parse(_timeLimitController.text.trim()),
//       createdAt: DateTime.now(),
//       questions: _questions, description: '', isActive: true,
//     );

//     // This call is now safe because QuizModel.toMap() and nested methods are corrected.
//     final result = await widget.databaseService.createQuiz(quiz);

//     if (result == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Quiz created successfully!')),
//         );

//         // Clear form
//         _titleController.clear();
//         _timeLimitController.text = '30';
//         _totalMarksController.text = '100';
//         setState(() {
//           _selectedClassId = null;
//           _questions = [];
//         });
//       }
//     } else {
//       if (mounted) {
//         // Displays error message returned by DatabaseService
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(result)));
//       }
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error creating quiz: $e')));
//     }
//   } finally {
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
// }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Create New Quiz',
//               style: TextStyle(
//                 fontSize: widget.isTablet ? 24 : 20,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 24),

//             // Quiz Title
//             TextFormField(
//               controller: _titleController,
//               decoration: const InputDecoration(
//                 labelText: 'Quiz Title',
//                 hintText: 'e.g., Biology Quiz - Chapter 3',
//                 prefixIcon: Icon(Icons.quiz),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter a quiz title';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),

//             // Class Selection
//             StreamBuilder<List<ClassModel>>(
//               stream: widget.databaseService.getTeacherClasses(
//                 widget.teacher.uid,
//               ),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const CircularProgressIndicator();
//                 }

//                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                   return Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Text(
//                         'No classes available',
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.error,
//                         ),
//                       ),
//                     ),
//                   );
//                 }

//                 final classes = snapshot.data!;
//                 return DropdownButtonFormField<String>(
//                   value: _selectedClassId,
//                   decoration: const InputDecoration(
//                     labelText: 'Select Class',
//                     prefixIcon: Icon(Icons.class_),
//                   ),
//                   items:
//                       classes
//                           .map(
//                             (classModel) => DropdownMenuItem(
//                               value: classModel.id,
//                               child: Text(classModel.name),
//                             ),
//                           )
//                           .toList(),
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedClassId = value;
//                     });
//                   },
//                 );
//               },
//             ),
//             const SizedBox(height: 16),

//             // Time Limit
//             TextFormField(
//               controller: _timeLimitController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Time Limit (minutes)',
//                 hintText: 'e.g., 30',
//                 prefixIcon: Icon(Icons.schedule),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter time limit';
//                 }
//                 final time = int.tryParse(value);
//                 if (time == null || time <= 0) {
//                   return 'Please enter a valid number';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),

//             // Total Marks
//             TextFormField(
//               controller: _totalMarksController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Total Marks',
//                 hintText: 'e.g., 100',
//                 prefixIcon: Icon(Icons.grade),
//               ),
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter total marks';
//                 }
//                 final marks = int.tryParse(value);
//                 if (marks == null || marks <= 0) {
//                   return 'Please enter a valid number';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 32),

//             // Questions Section
//             Text(
//               'Questions (${_questions.length})',
//               style: TextStyle(
//                 fontSize: widget.isTablet ? 18 : 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Questions List
//             if (_questions.isEmpty)
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Center(
//                     child: Text(
//                       'No questions added yet',
//                       style: TextStyle(
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.onSurface.withOpacity(0.6),
//                       ),
//                     ),
//                   ),
//                 ),
//               )
//             else
//               ...List.generate(_questions.length, (index) {
//                 final question = _questions[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Q${index + 1}. ${question.question}',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     'Marks: ${question.marks}',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: Theme.of(
//                                         context,
//                                       ).colorScheme.onSurface.withOpacity(0.6),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             PopupMenuButton<String>(
//                               onSelected: (value) {
//                                 if (value == 'edit') {
//                                   _editQuestion(index);
//                                 } else if (value == 'delete') {
//                                   _deleteQuestion(index);
//                                 }
//                               },
//                               itemBuilder:
//                                   (BuildContext context) => [
//                                     const PopupMenuItem(
//                                       value: 'edit',
//                                       child: Text('Edit'),
//                                     ),
//                                     const PopupMenuItem(
//                                       value: 'delete',
//                                       child: Text(
//                                         'Delete',
//                                         style: TextStyle(color: Colors.red),
//                                       ),
//                                     ),
//                                   ],
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }),

//             const SizedBox(height: 16),

//             // Add Question Button
//             SizedBox(
//               width: double.infinity,
//               child: OutlinedButton.icon(
//                 onPressed: _addQuestion,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Question'),
//               ),
//             ),

//             const SizedBox(height: 32),

//             // Create Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _createQuiz,
//                 child:
//                     _isLoading
//                         ? const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(strokeWidth: 2),
//                             ),
//                             SizedBox(width: 12),
//                             Text('Creating...'),
//                           ],
//                         )
//                         : const Text('Create Quiz'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Question Dialog - CORRECTED LOGIC
// class _QuestionDialog extends StatefulWidget {
//   final QuizQuestion? initialQuestion;
//   final Function(QuizQuestion) onSave;

//   const _QuestionDialog({this.initialQuestion, required this.onSave});

//   @override
//   State<_QuestionDialog> createState() => __QuestionDialogState();
// }

// class __QuestionDialogState extends State<_QuestionDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _questionController;
//   late TextEditingController _marksController;
//   late TextEditingController _optionController;
//   late QuestionType _selectedType;
//   List<String> _options = [];
//   String _correctAnswer = '';
//   // Fixed list for True/False options
//   final List<String> _trueFalseOptions = ['True', 'False'];

//   @override
//   void initState() {
//     super.initState();
//     _questionController = TextEditingController(
//       text: widget.initialQuestion?.question ?? '',
//     );
//     _marksController = TextEditingController(
//       text: widget.initialQuestion?.marks.toString() ?? '1',
//     );
//     _optionController = TextEditingController();

//     if (widget.initialQuestion != null) {
//       _selectedType = widget.initialQuestion!.type;
//       // Load options, which will be empty for ShortAnswer/TrueFalse unless specifically saved that way
//       _options = List.from(widget.initialQuestion!.options);
//       _correctAnswer = widget.initialQuestion!.correctAnswer;
//     } else {
//       _selectedType = QuestionType.multipleChoice;
//     }
    
//     // Set default correct answer for new True/False questions
//     if (_selectedType == QuestionType.trueFalse && _correctAnswer.isEmpty) {
//         _correctAnswer = 'True';
//     }
//   }

//   @override
//   void dispose() {
//     _questionController.dispose();
//     _marksController.dispose();
//     _optionController.dispose();
//     super.dispose();
//   }

//   void _addOption() {
//     if (_optionController.text.isNotEmpty) {
//       setState(() {
//         _options.add(_optionController.text.trim());
//         _optionController.clear();
//       });
//     }
//   }

//   void _removeOption(int index) {
//     setState(() {
//       if (_correctAnswer == _options[index]) {
//         _correctAnswer = '';
//       }
//       _options.removeAt(index);
//     });
//   }

//   void _saveQuestion() {
//     if (!_formKey.currentState!.validate()) return;
    
//     // --- Validation Checks ---
//     if (_selectedType == QuestionType.multipleChoice && _options.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('MCQ: Please add at least one option')),
//       );
//       return;
//     }

//     if (_correctAnswer.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select/enter the correct answer')),
//       );
//       return;
//     }
//     // --- End Validation Checks ---

//     // Determine the final options list for the model based on type
//     List<String> finalOptions;
//     if (_selectedType == QuestionType.multipleChoice) {
//       finalOptions = _options;
//     } else if (_selectedType == QuestionType.trueFalse) {
//       // T/F questions must always save 'True' and 'False' as options
//       finalOptions = _trueFalseOptions;
//     } else {
//       // Short Answer type has no options
//       finalOptions = [];
//     }

//     final question = QuizQuestion(
//       id: widget.initialQuestion?.id ?? const Uuid().v4(),
//       question: _questionController.text.trim(),
//       type: _selectedType,
//       options: finalOptions,
//       correctAnswer: _correctAnswer,
//       marks: int.parse(_marksController.text.trim()),
//     );

//     widget.onSave(question);
//     Navigator.pop(context); // Close the dialog after successful save
//   }
  
//   // Helper to get a cleaner display name for the Dropdown
//   String _getQuestionTypeName(QuestionType type) {
//     switch (type) {
//       case QuestionType.multipleChoice:
//         return 'Multiple Choice (MCQ)';
//       case QuestionType.shortAnswer:
//         return 'Short Answer';
//       case QuestionType.trueFalse:
//         return 'True/False';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   widget.initialQuestion == null
//                       ? 'Add Question'
//                       : 'Edit Question',
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Question Text
//                 TextFormField(
//                   controller: _questionController,
//                   maxLines: 3,
//                   decoration: const InputDecoration(
//                     labelText: 'Question',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter a question';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Question Type Dropdown
//                 DropdownButtonFormField<QuestionType>(
//                   value: _selectedType,
//                   decoration: const InputDecoration(
//                     labelText: 'Question Type',
//                     border: OutlineInputBorder(),
//                   ),
//                   items:
//                       QuestionType.values
//                           .map(
//                             (type) => DropdownMenuItem(
//                               value: type,
//                               child: Text(_getQuestionTypeName(type)),
//                             ),
//                           )
//                           .toList(),
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         _selectedType = value;
//                         // Reset dynamic state based on new type
//                         _options = []; 
//                         _correctAnswer = '';

//                         if (value == QuestionType.trueFalse) {
//                           _correctAnswer = 'True'; // Default T/F selection
//                         }
//                       });
//                     }
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Marks
//                 TextFormField(
//                   controller: _marksController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                     labelText: 'Marks',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter marks';
//                     }
//                     final marks = int.tryParse(value);
//                     if (marks == null || marks <= 0) {
//                       return 'Please enter a valid number';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // ---------------------------------------------
//                 // Options (for multiple choice)
//                 // ---------------------------------------------
//                 if (_selectedType == QuestionType.multipleChoice) ...[
//                   Text(
//                     'Options',
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   const SizedBox(height: 12),

//                   // Option Input
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _optionController,
//                           decoration: const InputDecoration(
//                             labelText: 'Add option',
//                             border: OutlineInputBorder(),
//                           ),
//                           onFieldSubmitted: (_) => _addOption(),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: _addOption,
//                         child: const Icon(Icons.add),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // Options List (Use Radio for single correct answer clarity)
//                   if (_options.isNotEmpty)
//                     Column(
//                       children: List.generate(_options.length, (index) {
//                         final option = _options[index];
//                         final isCorrect = option == _correctAnswer;
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           color:
//                               isCorrect ? Colors.green.withOpacity(0.2) : null,
//                           child: ListTile(
//                             title: Text(option),
//                             leading: Radio<String>(
//                               value: option,
//                               groupValue: _correctAnswer,
//                               onChanged: (value) {
//                                 setState(() {
//                                   _correctAnswer = value!;
//                                 });
//                               },
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(
//                                 Icons.delete,
//                                 color: Colors.red,
//                               ),
//                               onPressed: () => _removeOption(index),
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//                   const SizedBox(height: 16),
//                 ],

//                 // ---------------------------------------------
//                 // Correct Answer (for short answer)
//                 // ---------------------------------------------
//                // ---------------------------------------------
// // Correct Answer (for short answer)
// // ---------------------------------------------
// if (_selectedType == QuestionType.shortAnswer)
//   Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         'Correct Answer',
//         style: Theme.of(context).textTheme.titleMedium,
//       ),
//       const SizedBox(height: 12),
//       TextFormField(
//         initialValue: _correctAnswer,
//         decoration: const InputDecoration(
//           labelText: 'Correct Answer',
//           hintText: 'Enter the exact correct answer',
//           border: OutlineInputBorder(),
//         ),
//         onChanged: (value) {
//           setState(() {
//             _correctAnswer = value.trim();
//           });
//         },
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return 'Please enter the correct answer';
//           }
//           return null;
//         },
//       ),
//       const SizedBox(height: 16),
//     ],
//   ),
                
//                 // ---------------------------------------------
//                 // Correct Answer (for true/false)
//                 // ---------------------------------------------
//                 if (_selectedType == QuestionType.trueFalse) ...[
//                   Text(
//                     'Select Correct Answer:',
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   const SizedBox(height: 12),
//                   // Radio buttons for True/False
//                   Row(
//                     children: _trueFalseOptions.map((option) {
//                       return Expanded(
//                         child: RadioListTile<String>(
//                           title: Text(option),
//                           value: option,
//                           groupValue: _correctAnswer,
//                           onChanged: (String? value) {
//                             setState(() {
//                               _correctAnswer = value!;
//                             });
//                           },
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ],
                
//                 const SizedBox(height: 24),

//                 // Buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel'),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _saveQuestion,
//                       child: const Text('Save'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../models/teacher_model.dart';
import '../../models/quiz_model.dart';
import '../../models/class_model.dart';
import '../../utils/responsive_helper.dart';

class QuizManagementScreen extends StatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TeacherModel? _cachedTeacher;
  bool _isLoadingTeacher = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeacherData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final teacher = await databaseService.getTeacher(authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _cachedTeacher = teacher;
          _isLoadingTeacher = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTeacher = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'Create', icon: Icon(Icons.add)),
            Tab(text: 'Results', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _buildBody(isTablet),
    );
  }

  Widget _buildBody(bool isTablet) {
    if (_isLoadingTeacher) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedTeacher == null) {
      return const Center(child: Text('Teacher data not found'));
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _QuizzesListTab(teacher: _cachedTeacher!),
        _CreateQuizTab(teacher: _cachedTeacher!, isTablet: isTablet),
        _ResultsTab(teacher: _cachedTeacher!, isTablet: isTablet),
      ],
    );
  }
}

class _QuizzesListTab extends StatefulWidget {
  final TeacherModel teacher;

  const _QuizzesListTab({required this.teacher});

  @override
  State<_QuizzesListTab> createState() => _QuizzesListTabState();
}

class _QuizzesListTabState extends State<_QuizzesListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _QuizzesListContent(teacher: widget.teacher);
  }
}

class _QuizzesListContent extends StatefulWidget {
  final TeacherModel teacher;

  const _QuizzesListContent({required this.teacher});

  @override
  State<_QuizzesListContent> createState() => _QuizzesListContentState();
}

class _QuizzesListContentState extends State<_QuizzesListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search quizzes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // Class Filter
              StreamBuilder<List<ClassModel>>(
                stream: databaseService.getTeacherClasses(widget.teacher.uid),
                builder: (context, classSnapshot) {
                  if (!classSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final classes = classSnapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Class',
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ...classes.map(
                        (classModel) => DropdownMenuItem(
                          value: classModel.id,
                          child: Text(classModel.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClassId = value;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        ),
        // Quizzes List
        Expanded(
          child: _QuizzesList(
            teacher: widget.teacher,
            searchQuery: _searchQuery,
            selectedClassId: _selectedClassId,
          ),
        ),
      ],
    );
  }
}

class _QuizzesList extends StatefulWidget {
  final TeacherModel teacher;
  final String searchQuery;
  final String? selectedClassId;

  const _QuizzesList({
    required this.teacher,
    required this.searchQuery,
    required this.selectedClassId,
  });

  @override
  State<_QuizzesList> createState() => _QuizzesListState();
}

class _QuizzesListState extends State<_QuizzesList> {
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final quizzes = await databaseService.getTeacherQuizzes(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _quizzes = quizzes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    var quizzes = _quizzes;

    // Apply filters
    if (widget.selectedClassId != null) {
      quizzes = quizzes
          .where((quiz) => quiz.classId == widget.selectedClassId)
          .toList();
    }

    if (widget.searchQuery.isNotEmpty) {
      quizzes = quizzes.where((quiz) {
        return quiz.title.toLowerCase().contains(widget.searchQuery);
      }).toList();
    }

    if (quizzes.isEmpty) {
      return _EmptyQuizzesState(
        searchQuery: widget.searchQuery,
        hasSelectedClass: widget.selectedClassId != null,
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    final databaseService = Provider.of<DatabaseService>(context);

    return RefreshIndicator(
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) => _QuizCard(
          quiz: quizzes[index],
          databaseService: databaseService,
        ),
      ),
    );
  }
}

class _EmptyQuizzesState extends StatelessWidget {
  final String searchQuery;
  final bool hasSelectedClass;

  const _EmptyQuizzesState({
    required this.searchQuery,
    required this.hasSelectedClass,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateTitle() {
    if (searchQuery.isNotEmpty) return 'No matching quizzes';
    if (hasSelectedClass) return 'No quizzes for selected class';
    return 'No quizzes found';
  }

  String _getEmptyStateSubtitle() {
    if (searchQuery.isNotEmpty) return 'Try a different search term';
    if (hasSelectedClass) return 'Create a quiz for this class';
    return 'Create your first quiz to get started';
  }
}

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final DatabaseService databaseService;

  const _QuizCard({
    required this.quiz,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);

    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: InkWell(
        onTap: () => _showQuizDetails(context, quiz),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.questions.length} Questions',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'results',
                        child: ListTile(
                          leading: Icon(Icons.analytics),
                          title: Text('View Results'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editQuiz(context, quiz);
                          break;
                        case 'results':
                          _viewResults(context, quiz);
                          break;
                        case 'delete':
                          _deleteQuiz(context, quiz);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.timeLimit} minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${quiz.totalMarks} marks',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizDetails(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: ResponsiveHelper.isDesktop(context) ? 600 : null,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(quiz.title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Limit',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text('${quiz.timeLimit} minutes'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Marks',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text('${quiz.totalMarks}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Questions (${quiz.questions.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (quiz.questions.isEmpty)
                        const Text('No questions added yet')
                      else
                        ...quiz.questions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final question = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${index + 1}. ${question.question}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Type: ${question.type.toString().split('.').last}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy hh:mm a').format(quiz.createdAt),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editQuiz(BuildContext context, QuizModel quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit quiz feature coming soon!')),
    );
  }

  void _viewResults(BuildContext context, QuizModel quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz results feature coming soon!')),
    );
  }

  void _deleteQuiz(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete quiz feature coming soon!'),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateQuizTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateQuizTab({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateQuizTab> createState() => _CreateQuizTabState();
}

class _CreateQuizTabState extends State<_CreateQuizTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _CreateQuizForm(
      teacher: widget.teacher,
      isTablet: widget.isTablet,
    );
  }
}

class _CreateQuizForm extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _CreateQuizForm({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_CreateQuizForm> createState() => __CreateQuizFormState();
}

class __CreateQuizFormState extends State<_CreateQuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');
  final _totalMarksController = TextEditingController(text: '100');
  String? _selectedClassId;
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;
  List<ClassModel> _classes = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    _totalMarksController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final classes = await databaseService.getTeacherClasses(widget.teacher.uid).first;
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        onSave: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        initialQuestion: _questions[index],
        onSave: (question) {
          setState(() {
            _questions[index] = question;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _createQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      final classes = await databaseService.getTeacherClasses(widget.teacher.uid).first;

      if (classes.isEmpty) {
        throw Exception('No classes available. Please create a class first.');
      }

      final selectedClass = classes.firstWhere(
        (c) => c.id == _selectedClassId,
        orElse: () => throw Exception('Selected class not found'),
      );

      final quizId = const Uuid().v4();
      final quiz = QuizModel(
        id: quizId,
        title: _titleController.text.trim(),
        institutionId: widget.teacher.institutionId,
        divisionId: selectedClass.divisionId,
        classId: _selectedClassId!,
        teacherId: widget.teacher.uid,
        totalMarks: int.parse(_totalMarksController.text.trim()),
        timeLimit: int.parse(_timeLimitController.text.trim()),
        createdAt: DateTime.now(),
        questions: _questions,
        description: '',
        isActive: true,
      );

      final result = await databaseService.createQuiz(quiz);

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz created successfully!')),
          );

          // Clear form
          _titleController.clear();
          _timeLimitController.text = '30';
          _totalMarksController.text = '100';
          setState(() {
            _selectedClassId = null;
            _questions = [];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating quiz: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isTablet ? 24 : 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Quiz',
              style: TextStyle(
                fontSize: widget.isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Quiz Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'e.g., Biology Quiz - Chapter 3',
                prefixIcon: Icon(Icons.quiz),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quiz title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Class Selection
            _buildClassSelection(),

            const SizedBox(height: 16),

            // Time Limit
            TextFormField(
              controller: _timeLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Time Limit (minutes)',
                hintText: 'e.g., 30',
                prefixIcon: Icon(Icons.schedule),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter time limit';
                }
                final time = int.tryParse(value);
                if (time == null || time <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total Marks
            TextFormField(
              controller: _totalMarksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Marks',
                hintText: 'e.g., 100',
                prefixIcon: Icon(Icons.grade),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter total marks';
                }
                final marks = int.tryParse(value);
                if (marks == null || marks <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Questions Section
            Text(
              'Questions (${_questions.length})',
              style: TextStyle(
                fontSize: widget.isTablet ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Questions List
            if (_questions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No questions added yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_questions.length, (index) {
                final question = _questions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${index + 1}. ${question.question}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Marks: ${question.marks}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editQuestion(index);
                                } else if (value == 'delete') {
                                  _deleteQuestion(index);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // Add Question Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
              ),
            ),

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createQuiz,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Creating...'),
                        ],
                      )
                    : const Text('Create Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelection() {
    if (_isLoadingClasses) {
      return const CircularProgressIndicator();
    }

    if (_classes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No classes available',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedClassId,
      decoration: const InputDecoration(
        labelText: 'Select Class',
        prefixIcon: Icon(Icons.class_),
      ),
      items: _classes
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
  }
}

class _ResultsTab extends StatefulWidget {
  final TeacherModel teacher;
  final bool isTablet;

  const _ResultsTab({
    required this.teacher,
    required this.isTablet,
  });

  @override
  State<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<_ResultsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Quiz Results & Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detailed analytics and results coming soon!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Question Dialog - CORRECTED LOGIC
class _QuestionDialog extends StatefulWidget {
  final QuizQuestion? initialQuestion;
  final Function(QuizQuestion) onSave;

  const _QuestionDialog({this.initialQuestion, required this.onSave});

  @override
  State<_QuestionDialog> createState() => __QuestionDialogState();
}

class __QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _marksController;
  late TextEditingController _optionController;
  late QuestionType _selectedType;
  List<String> _options = [];
  String _correctAnswer = '';
  // Fixed list for True/False options
  final List<String> _trueFalseOptions = ['True', 'False'];

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.initialQuestion?.question ?? '',
    );
    _marksController = TextEditingController(
      text: widget.initialQuestion?.marks.toString() ?? '1',
    );
    _optionController = TextEditingController();

    if (widget.initialQuestion != null) {
      _selectedType = widget.initialQuestion!.type;
      // Load options, which will be empty for ShortAnswer/TrueFalse unless specifically saved that way
      _options = List.from(widget.initialQuestion!.options);
      _correctAnswer = widget.initialQuestion!.correctAnswer;
    } else {
      _selectedType = QuestionType.multipleChoice;
    }
    
    // Set default correct answer for new True/False questions
    if (_selectedType == QuestionType.trueFalse && _correctAnswer.isEmpty) {
        _correctAnswer = 'True';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionController.text.isNotEmpty) {
      setState(() {
        _options.add(_optionController.text.trim());
        _optionController.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      if (_correctAnswer == _options[index]) {
        _correctAnswer = '';
      }
      _options.removeAt(index);
    });
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) return;
    
    // --- Validation Checks ---
    if (_selectedType == QuestionType.multipleChoice && _options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MCQ: Please add at least one option')),
      );
      return;
    }

    if (_correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select/enter the correct answer')),
      );
      return;
    }
    // --- End Validation Checks ---

    // Determine the final options list for the model based on type
    List<String> finalOptions;
    if (_selectedType == QuestionType.multipleChoice) {
      finalOptions = _options;
    } else if (_selectedType == QuestionType.trueFalse) {
      // T/F questions must always save 'True' and 'False' as options
      finalOptions = _trueFalseOptions;
    } else {
      // Short Answer type has no options
      finalOptions = [];
    }

    final question = QuizQuestion(
      id: widget.initialQuestion?.id ?? const Uuid().v4(),
      question: _questionController.text.trim(),
      type: _selectedType,
      options: finalOptions,
      correctAnswer: _correctAnswer,
      marks: int.parse(_marksController.text.trim()),
    );

    widget.onSave(question);
    Navigator.pop(context); // Close the dialog after successful save
  }
  
  // Helper to get a cleaner display name for the Dropdown
  String _getQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice (MCQ)';
      case QuestionType.shortAnswer:
        return 'Short Answer';
      case QuestionType.trueFalse:
        return 'True/False';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.initialQuestion == null
                      ? 'Add Question'
                      : 'Edit Question',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Question Text
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Question Type Dropdown
                DropdownButtonFormField<QuestionType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                  ),
                  items: QuestionType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getQuestionTypeName(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                        // Reset dynamic state based on new type
                        _options = []; 
                        _correctAnswer = '';

                        if (value == QuestionType.trueFalse) {
                          _correctAnswer = 'True'; // Default T/F selection
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Marks
                TextFormField(
                  controller: _marksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter marks';
                    }
                    final marks = int.tryParse(value);
                    if (marks == null || marks <= 0) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ---------------------------------------------
                // Options (for multiple choice)
                // ---------------------------------------------
                if (_selectedType == QuestionType.multipleChoice) ...[
                  Text(
                    'Options',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  // Option Input
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionController,
                          decoration: const InputDecoration(
                            labelText: 'Add option',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addOption,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Options List (Use Radio for single correct answer clarity)
                  if (_options.isNotEmpty)
                    Column(
                      children: List.generate(_options.length, (index) {
                        final option = _options[index];
                        final isCorrect = option == _correctAnswer;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isCorrect ? Colors.green.withOpacity(0.2) : null,
                          child: ListTile(
                            title: Text(option),
                            leading: Radio<String>(
                              value: option,
                              groupValue: _correctAnswer,
                              onChanged: (value) {
                                setState(() {
                                  _correctAnswer = value!;
                                });
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeOption(index),
                            ),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 16),
                ],

                // ---------------------------------------------
                // Correct Answer (for short answer)
                // ---------------------------------------------
                if (_selectedType == QuestionType.shortAnswer)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Correct Answer',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _correctAnswer,
                        decoration: const InputDecoration(
                          labelText: 'Correct Answer',
                          hintText: 'Enter the exact correct answer',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _correctAnswer = value.trim();
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the correct answer';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                
                // ---------------------------------------------
                // Correct Answer (for true/false)
                // ---------------------------------------------
                if (_selectedType == QuestionType.trueFalse) ...[
                  Text(
                    'Select Correct Answer:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  // Radio buttons for True/False
                  Row(
                    children: _trueFalseOptions.map((option) {
                      return Expanded(
                        child: RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: _correctAnswer,
                          onChanged: (String? value) {
                            setState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveQuestion,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}