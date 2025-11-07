// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../models/course_model.dart';
// import '../../models/class_model.dart';

// class CourseCreateScreen extends StatefulWidget {
//   final CourseModel? course;

//   const CourseCreateScreen({super.key, this.course});

//   @override
//   State<CourseCreateScreen> createState() => _CourseCreateScreenState();
// }

// class _CourseCreateScreenState extends State<CourseCreateScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _titleController;
//   late final TextEditingController _descriptionController;

//   String? _selectedClassId;
//   bool _isLoading = false;
//   List<CourseMaterial> _materials = [];

//   @override
//   void initState() {
//     super.initState();

//     _titleController = TextEditingController(text: widget.course?.title ?? '');
//     _descriptionController = TextEditingController(
//       text: widget.course?.description ?? '',
//     );
//     _selectedClassId = widget.course?.classId;
//     _materials = List.from(widget.course?.materials ?? []);
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveCourse() async {
//     if (!_formKey.currentState!.validate() || _selectedClassId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     final authService = Provider.of<AuthService>(context, listen: false);
//     final databaseService = Provider.of<DatabaseService>(
//       context,
//       listen: false,
//     );
//     final currentUser = authService.currentUser;

//     if (currentUser == null) {
//       setState(() => _isLoading = false);
//       return;
//     }

//     try {
//       // Get teacher data to access institutionId
//       final teacherData = await authService.getTeacherData(currentUser.uid);
//       if (teacherData == null) {
//         throw Exception('Teacher data not found');
//       }

//       // Get class data to access divisionId
//       final classData = await databaseService.getClassById(_selectedClassId!);
//       if (classData == null) {
//         throw Exception('Class data not found');
//       }

//       final course = CourseModel(
//         id: widget.course?.id ?? const Uuid().v4(),
//         title: _titleController.text.trim(),
//         description: _descriptionController.text.trim(),
//         institutionId: teacherData.institutionId,
//         divisionId: classData.divisionId,
//         classId: _selectedClassId!,
//         teacherId: currentUser.uid,
//         materials: _materials,
//         createdAt: widget.course?.createdAt ?? DateTime.now(),
//         isActive: widget.course?.isActive ?? true,
//       );

//       final error = widget.course == null
//           ? await databaseService.createCourse(course)
//           : await databaseService.updateCourse(course);

//       if (mounted) {
//         if (error != null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(error), backgroundColor: Colors.red),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 widget.course == null
//                     ? 'Course created successfully!'
//                     : 'Course updated successfully!',
//               ),
//               backgroundColor: Colors.green,
//             ),
//           );
//           Navigator.pop(context);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _addMaterial() {
//     showDialog(
//       context: context,
//       builder: (context) => _MaterialDialog(
//         onMaterialAdded: (material) {
//           setState(() {
//             _materials.add(material);
//           });
//         },
//       ),
//     );
//   }

//   void _editMaterial(int index) {
//     showDialog(
//       context: context,
//       builder: (context) => _MaterialDialog(
//         material: _materials[index],
//         onMaterialAdded: (material) {
//           setState(() {
//             _materials[index] = material;
//           });
//         },
//       ),
//     );
//   }

//   void _deleteMaterial(int index) {
//     setState(() {
//       _materials.removeAt(index);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     final databaseService = Provider.of<DatabaseService>(context);
//     final currentUser = authService.currentUser;
//     final isEditing = widget.course != null;

//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please login to continue')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isEditing ? 'Edit Course' : 'Create Course'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         actions: [
//           Container(
//             margin: const EdgeInsets.only(right: 16),
//             child: FilledButton.icon(
//               onPressed: _isLoading ? null : _saveCourse,
//               icon: _isLoading
//                   ? const SizedBox(
//                       width: 16,
//                       height: 16,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.save, size: 18),
//               label: Text(isEditing ? 'Update' : 'Save'),
//               style: FilledButton.styleFrom(
//                 backgroundColor: Theme.of(context).colorScheme.primary,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Course Details',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                       const SizedBox(height: 16),

//                       // Class Selection
//                       StreamBuilder<List<ClassModel>>(
//                         stream: databaseService.getTeacherClasses(
//                           currentUser.uid,
//                         ),
//                         builder: (context, snapshot) {
//                           // if (!snapshot.hasData) {
//                           //   return const CircularProgressIndicator();
//                           // }

//                           final classes = snapshot.data!;

//                           // Handle empty classes
//                           if (classes.isEmpty) {
//                             return Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: Colors.orange.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                     border: Border.all(
//                                       color: Colors.orange.withOpacity(0.3),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Icon(
//                                         Icons.info_outline,
//                                         color: Colors.orange,
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Text(
//                                           'No classes available. Please create a class first or contact your administrator to assign classes to you.',
//                                           style: TextStyle(
//                                             color: Colors.orange.shade900,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 16),
//                               ],
//                             );
//                           }

//                           return DropdownButtonFormField<String>(
//                             value: _selectedClassId,
//                             decoration: const InputDecoration(
//                               labelText: 'Select Class *',
//                               prefixIcon: Icon(Icons.class_),
//                             ),
//                             items: classes.map((classModel) {
//                               return DropdownMenuItem<String>(
//                                 value: classModel.id,
//                                 child: Text(
//                                   '${classModel.name} - ${classModel.subject}',
//                                 ),
//                               );
//                             }).toList(),
//                             onChanged: (value) {
//                               setState(() {
//                                 _selectedClassId = value;
//                               });
//                             },
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please select a class';
//                               }
//                               return null;
//                             },
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Title
//                       TextFormField(
//                         controller: _titleController,
//                         decoration: const InputDecoration(
//                           labelText: 'Course Title *',
//                           prefixIcon: Icon(Icons.title),
//                           hintText: 'Enter course title',
//                         ),
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter course title';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16),

//                       // Description
//                       TextFormField(
//                         controller: _descriptionController,
//                         decoration: const InputDecoration(
//                           labelText: 'Course Description *',
//                           prefixIcon: Icon(Icons.description),
//                           hintText: 'Enter course description',
//                         ),
//                         maxLines: 3,
//                         validator: (value) {
//                           if (value == null || value.trim().isEmpty) {
//                             return 'Please enter course description';
//                           }
//                           return null;
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),

//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             'Course Materials',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .titleLarge
//                                 ?.copyWith(fontWeight: FontWeight.bold),
//                           ),
//                           const Spacer(),
//                           Text(
//                             '${_materials.length} materials',
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 16),
//                       if (_materials.isEmpty)
//                         Container(
//                           padding: const EdgeInsets.all(24),
//                           child: Column(
//                             children: [
//                               Icon(
//                                 Icons.folder_open,
//                                 size: 48,
//                                 color: Colors.grey[400],
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'No materials added yet',
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                             ],
//                           ),
//                         )
//                       else
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: _materials.length,
//                           itemBuilder: (context, index) {
//                             final material = _materials[index];
//                             return Card(
//                               margin: const EdgeInsets.only(bottom: 8),
//                               child: ListTile(
//                                 leading: CircleAvatar(
//                                   backgroundColor: _getMaterialColor(
//                                     material.type,
//                                   ),
//                                   child: Icon(
//                                     _getMaterialIcon(material.type),
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 title: Text(material.title),
//                                 subtitle: Text(material.type.toUpperCase()),
//                                 trailing: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       icon: const Icon(Icons.edit, size: 20),
//                                       onPressed: () => _editMaterial(index),
//                                     ),
//                                     IconButton(
//                                       icon: const Icon(
//                                         Icons.delete,
//                                         size: 20,
//                                         color: Colors.red,
//                                       ),
//                                       onPressed: () => _deleteMaterial(index),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       const SizedBox(height: 16),
//                       ElevatedButton.icon(
//                         onPressed: _addMaterial,
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add Material'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),

//               // Save Button
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _saveCourse,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         height: 20,
//                         width: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : Text(
//                         isEditing ? 'Update Course' : 'Create Course',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getMaterialColor(String type) {
//     switch (type) {
//       case 'video':
//         return Colors.red;
//       case 'document':
//         return Colors.blue;
//       case 'link':
//         return Colors.green;
//       case 'note':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getMaterialIcon(String type) {
//     switch (type) {
//       case 'video':
//         return Icons.play_circle;
//       case 'document':
//         return Icons.description;
//       case 'link':
//         return Icons.link;
//       case 'note':
//         return Icons.note;
//       default:
//         return Icons.folder;
//     }
//   }
// }

// class _MaterialDialog extends StatefulWidget {
//   final CourseMaterial? material;
//   final Function(CourseMaterial) onMaterialAdded;

//   const _MaterialDialog({this.material, required this.onMaterialAdded});

//   @override
//   State<_MaterialDialog> createState() => _MaterialDialogState();
// }

// class _MaterialDialogState extends State<_MaterialDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _titleController;
//   late final TextEditingController _descriptionController;
//   late final TextEditingController _urlController;
//   late String _selectedType;

//   @override
//   void initState() {
//     super.initState();

//     _titleController = TextEditingController(
//       text: widget.material?.title ?? '',
//     );
//     _descriptionController = TextEditingController(
//       text: widget.material?.description ?? '',
//     );
//     _urlController = TextEditingController(text: widget.material?.url ?? '');
//     _selectedType = widget.material?.type ?? 'document';
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _urlController.dispose();
//     super.dispose();
//   }

//   void _saveMaterial() {
//     if (!_formKey.currentState!.validate()) return;

//     final material = CourseMaterial(
//       id: widget.material?.id ?? const Uuid().v4(),
//       title: _titleController.text.trim(),
//       description: _descriptionController.text.trim().isEmpty
//           ? null
//           : _descriptionController.text.trim(),
//       url: _urlController.text.trim().isEmpty
//           ? null
//           : _urlController.text.trim(),
//       type: _selectedType,
//       uploadedAt: widget.material?.uploadedAt ?? DateTime.now(),
//       courseId: '',
//     );

//     widget.onMaterialAdded(material);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Material Type
//                 DropdownButtonFormField<String>(
//                   value: _selectedType,
//                   decoration: const InputDecoration(labelText: 'Material Type'),
//                   items: const [
//                     DropdownMenuItem(
//                       value: 'video',
//                       child: Text('Video (Drive Link)'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'document',
//                       child: Text('Document (PDF)'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'link',
//                       child: Text('External Link'),
//                     ),
//                     DropdownMenuItem(value: 'note', child: Text('Text Note')),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedType = value!;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Title
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Title *',
//                     hintText: 'Enter material title',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter title';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Description
//                 TextFormField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     hintText: 'Enter material description',
//                   ),
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 16),

//                 // URL/Content based on type
//                 if (_selectedType == 'video') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'Google Drive Video Link',
//                       hintText: 'https://drive.google.com/...',
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter video link';
//                       }
//                       if (!value.contains('drive.google.com')) {
//                         return 'Please enter a valid Google Drive link';
//                       }
//                       return null;
//                     },
//                   ),
//                 ] else if (_selectedType == 'document') ...[
//                   const Text(
//                     'Note: PDF upload will be implemented using base64 conversion in the actual implementation.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontStyle: FontStyle.italic,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // TODO: Implement PDF upload with base64 conversion
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'PDF upload feature will be implemented',
//                           ),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.upload_file),
//                     label: const Text('Upload PDF'),
//                   ),
//                 ] else if (_selectedType == 'link') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'External Link',
//                       hintText: 'https://example.com',
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter link';
//                       }
//                       if (!value.startsWith('http')) {
//                         return 'Please enter a valid URL';
//                       }
//                       return null;
//                     },
//                   ),
//                 ] else if (_selectedType == 'note') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'Note Content',
//                       hintText: 'Enter your text note here...',
//                     ),
//                     maxLines: 5,
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter note content';
//                       }
//                       return null;
//                     },
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(onPressed: _saveMaterial, child: const Text('Save')),
//       ],
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../models/course_model.dart';
// import '../../models/class_model.dart';

// // State management class for course creation
// class CourseCreateState extends ChangeNotifier {
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();

//   String? _selectedClassId;
//   bool _isLoading = false;
//   List<CourseMaterial> _materials = [];
//   List<ClassModel> _teacherClasses = [];
//   bool _classesLoaded = false;

//   // Getters
//   TextEditingController get titleController => _titleController;
//   TextEditingController get descriptionController => _descriptionController;
//   String? get selectedClassId => _selectedClassId;
//   bool get isLoading => _isLoading;
//   List<CourseMaterial> get materials => _materials;
//   List<ClassModel> get teacherClasses => _teacherClasses;
//   bool get classesLoaded => _classesLoaded;

//   // Setters with safe notification
//   void setSelectedClassId(String? value, {bool notify = true}) {
//     _selectedClassId = value;
//     if (notify) _safeNotify();
//   }

//   void setIsLoading(bool value, {bool notify = true}) {
//     _isLoading = value;
//     if (notify) _safeNotify();
//   }

//   void setTeacherClasses(List<ClassModel> classes, {bool notify = true}) {
//     _teacherClasses = classes;
//     _classesLoaded = true;
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

//   // Material methods
//   void addMaterial(CourseMaterial material, {bool notify = true}) {
//     _materials.add(material);
//     if (notify) _safeNotify();
//   }

//   void updateMaterial(int index, CourseMaterial material,
//       {bool notify = true}) {
//     if (index >= 0 && index < _materials.length) {
//       _materials[index] = material;
//       if (notify) _safeNotify();
//     }
//   }

//   void removeMaterial(int index, {bool notify = true}) {
//     if (index >= 0 && index < _materials.length) {
//       _materials.removeAt(index);
//       if (notify) _safeNotify();
//     }
//   }

//   void clearMaterials({bool notify = true}) {
//     _materials.clear();
//     if (notify) _safeNotify();
//   }

//   // Initialize from existing course
//   void initializeFromCourse(CourseModel? course) {
//     if (course != null) {
//       _titleController.text = course.title;
//       _descriptionController.text = course.description;
//       _selectedClassId = course.classId;
//       _materials = List.from(course.materials);
//     } else {
//       _titleController.clear();
//       _descriptionController.clear();
//       _selectedClassId = null;
//       _materials.clear();
//     }
//     _safeNotify();
//   }

//   // Validation
//   bool validateForm() {
//     return _titleController.text.trim().isNotEmpty &&
//         _descriptionController.text.trim().isNotEmpty &&
//         _selectedClassId != null;
//   }

//   // Dispose controllers
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//   }
// }

// class CourseCreateScreen extends StatefulWidget {
//   final CourseModel? course;

//   const CourseCreateScreen({super.key, this.course});

//   @override
//   State<CourseCreateScreen> createState() => _CourseCreateScreenState();
// }

// class _CourseCreateScreenState extends State<CourseCreateScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late CourseCreateState _courseState;

//   @override
//   void initState() {
//     super.initState();
//     _courseState = CourseCreateState();
//     _loadInitialData();
//   }

//   void _loadInitialData() {
//     // Initialize from existing course
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _courseState.initializeFromCourse(widget.course);
//     });
//   }

//   @override
//   void dispose() {
//     _courseState.dispose();
//     super.dispose();
//   }

//   Future<void> _saveCourse() async {
//     if (!_formKey.currentState!.validate() || !_courseState.validateForm()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all required fields'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     _courseState.setIsLoading(true);

//     final authService = Provider.of<AuthService>(context, listen: false);
//     final databaseService =
//         Provider.of<DatabaseService>(context, listen: false);
//     final currentUser = authService.currentUser;

//     if (currentUser == null) {
//       _courseState.setIsLoading(false);
//       return;
//     }

//     try {
//       // Get teacher data to access institutionId
//       final teacherData = await authService.getTeacherData(currentUser.uid);
//       if (teacherData == null) {
//         throw Exception('Teacher data not found');
//       }

//       // Get class data to access divisionId
//       final classData =
//           await databaseService.getClassById(_courseState.selectedClassId!);
//       if (classData == null) {
//         throw Exception('Class data not found');
//       }

//       final course = CourseModel(
//         id: widget.course?.id ?? const Uuid().v4(),
//         title: _courseState.titleController.text.trim(),
//         description: _courseState.descriptionController.text.trim(),
//         institutionId: teacherData.institutionId,
//         divisionId: classData.divisionId,
//         classId: _courseState.selectedClassId!,
//         teacherId: currentUser.uid,
//         materials: _courseState.materials,
//         createdAt: widget.course?.createdAt ?? DateTime.now(),
//         isActive: widget.course?.isActive ?? true,
//       );

//       final error = widget.course == null
//           ? await databaseService.createCourse(course)
//           : await databaseService.updateCourse(course);

//       if (mounted) {
//         if (error != null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(error), backgroundColor: Colors.red),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 widget.course == null
//                     ? 'Course created successfully!'
//                     : 'Course updated successfully!',
//               ),
//               backgroundColor: Colors.green,
//             ),
//           );
//           Navigator.pop(context);
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) {
//         _courseState.setIsLoading(false);
//       }
//     }
//   }

//   void _addMaterial() {
//     showDialog(
//       context: context,
//       builder: (context) => ChangeNotifierProvider.value(
//         value: _courseState,
//         child: _MaterialDialog(
//           onMaterialAdded: (material) {
//             _courseState.addMaterial(material);
//           },
//         ),
//       ),
//     );
//   }

//   void _editMaterial(int index) {
//     showDialog(
//       context: context,
//       builder: (context) => ChangeNotifierProvider.value(
//         value: _courseState,
//         child: _MaterialDialog(
//           material: _courseState.materials[index],
//           materialIndex: index,
//           onMaterialAdded: (material) {
//             _courseState.updateMaterial(index, material);
//           },
//         ),
//       ),
//     );
//   }

//   void _deleteMaterial(int index) {
//     _courseState.removeMaterial(index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     final currentUser = authService.currentUser;
//     final isEditing = widget.course != null;

//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please login to continue')),
//       );
//     }

//     return ChangeNotifierProvider.value(
//       value: _courseState,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(isEditing ? 'Edit Course' : 'Create Course'),
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           surfaceTintColor: Colors.transparent,
//           actions: [
//             Consumer<CourseCreateState>(
//               builder: (context, courseState, child) {
//                 return Container(
//                   margin: const EdgeInsets.only(right: 16),
//                   child: FilledButton.icon(
//                     onPressed: courseState.isLoading ? null : _saveCourse,
//                     icon: courseState.isLoading
//                         ? const SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2),
//                           )
//                         : const Icon(Icons.save, size: 18),
//                     label: Text(isEditing ? 'Update' : 'Save'),
//                     style: FilledButton.styleFrom(
//                       backgroundColor: Theme.of(context).colorScheme.primary,
//                       foregroundColor: Colors.white,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//         body: _buildBody(currentUser.uid),
//       ),
//     );
//   }

//   Widget _buildBody(String teacherId) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildCourseDetailsSection(teacherId),
//             const SizedBox(height: 16),
//             _buildMaterialsSection(),
//             const SizedBox(height: 32),
//             _buildSaveButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCourseDetailsSection(String teacherId) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Course Details',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             _buildClassSelection(teacherId),
//             const SizedBox(height: 16),
//             _buildTitleField(),
//             const SizedBox(height: 16),
//             _buildDescriptionField(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildClassSelection(String teacherId) {
//     final databaseService = Provider.of<DatabaseService>(context);

//     return StreamBuilder<List<ClassModel>>(
//       stream: databaseService.getTeacherClasses(teacherId),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const CircularProgressIndicator();
//         }

//         final classes = snapshot.data ?? [];

//         // Handle empty classes
//         if (classes.isEmpty) {
//           return _buildNoClassesWarning();
//         }

//         // Update classes in state only once
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           final courseState =
//               Provider.of<CourseCreateState>(context, listen: false);
//           if (!courseState.classesLoaded) {
//             courseState.setTeacherClasses(classes);
//           }
//         });

//         return Consumer<CourseCreateState>(
//           builder: (context, courseState, child) {
//             return DropdownButtonFormField<String>(
//               value: courseState.selectedClassId,
//               decoration: const InputDecoration(
//                 labelText: 'Select Class *',
//                 prefixIcon: Icon(Icons.class_),
//               ),
//               items: classes.map((classModel) {
//                 return DropdownMenuItem<String>(
//                   value: classModel.id,
//                   child: Text(
//                     '${classModel.name} - ${classModel.subject}',
//                   ),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   courseState.setSelectedClassId(value);
//                 });
//               },
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please select a class';
//                 }
//                 return null;
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildNoClassesWarning() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.orange.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: Colors.orange.withOpacity(0.3),
//             ),
//           ),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.info_outline,
//                 color: Colors.orange,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   'No classes available. Please create a class first or contact your administrator to assign classes to you.',
//                   style: TextStyle(
//                     color: Colors.orange.shade900,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   Widget _buildTitleField() {
//     return Consumer<CourseCreateState>(
//       builder: (context, courseState, child) {
//         return TextFormField(
//           controller: courseState.titleController,
//           decoration: const InputDecoration(
//             labelText: 'Course Title *',
//             prefixIcon: Icon(Icons.title),
//             hintText: 'Enter course title',
//           ),
//           onChanged: (value) {
//             // No need to notify here as the controller already holds the value
//           },
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Please enter course title';
//             }
//             return null;
//           },
//         );
//       },
//     );
//   }

//   Widget _buildDescriptionField() {
//     return Consumer<CourseCreateState>(
//       builder: (context, courseState, child) {
//         return TextFormField(
//           controller: courseState.descriptionController,
//           decoration: const InputDecoration(
//             labelText: 'Course Description *',
//             prefixIcon: Icon(Icons.description),
//             hintText: 'Enter course description',
//           ),
//           maxLines: 3,
//           onChanged: (value) {
//             // No need to notify here as the controller already holds the value
//           },
//           validator: (value) {
//             if (value == null || value.trim().isEmpty) {
//               return 'Please enter course description';
//             }
//             return null;
//           },
//         );
//       },
//     );
//   }

//   Widget _buildMaterialsSection() {
//     return Consumer<CourseCreateState>(
//       builder: (context, courseState, child) {
//         return Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       'Course Materials',
//                       style: Theme.of(context)
//                           .textTheme
//                           .titleLarge
//                           ?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                     const Spacer(),
//                     Text(
//                       '${courseState.materials.length} materials',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 if (courseState.materials.isEmpty)
//                   _buildEmptyMaterialsState()
//                 else
//                   _buildMaterialsList(courseState),
//                 const SizedBox(height: 16),
//                 _buildAddMaterialButton(),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildEmptyMaterialsState() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Icon(
//             Icons.folder_open,
//             size: 48,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No materials added yet',
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMaterialsList(CourseCreateState courseState) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: courseState.materials.length,
//       itemBuilder: (context, index) {
//         final material = courseState.materials[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 8),
//           child: ListTile(
//             leading: CircleAvatar(
//               backgroundColor: _getMaterialColor(material.type),
//               child: Icon(
//                 _getMaterialIcon(material.type),
//                 color: Colors.white,
//               ),
//             ),
//             title: Text(material.title),
//             subtitle: Text(material.type.toUpperCase()),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.edit, size: 20),
//                   onPressed: () => _editMaterial(index),
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.delete,
//                     size: 20,
//                     color: Colors.red,
//                   ),
//                   onPressed: () => _deleteMaterial(index),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAddMaterialButton() {
//     return ElevatedButton.icon(
//       onPressed: _addMaterial,
//       icon: const Icon(Icons.add),
//       label: const Text('Add Material'),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//     );
//   }

//   Widget _buildSaveButton() {
//     return Consumer<CourseCreateState>(
//       builder: (context, courseState, child) {
//         return ElevatedButton(
//           onPressed: courseState.isLoading ? null : _saveCourse,
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: courseState.isLoading
//               ? const SizedBox(
//                   height: 20,
//                   width: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//               : Text(
//                   widget.course == null ? 'Create Course' : 'Update Course',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         );
//       },
//     );
//   }

//   Color _getMaterialColor(String type) {
//     switch (type) {
//       case 'video':
//         return Colors.red;
//       case 'document':
//         return Colors.blue;
//       case 'link':
//         return Colors.green;
//       case 'note':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }

//   IconData _getMaterialIcon(String type) {
//     switch (type) {
//       case 'video':
//         return Icons.play_circle;
//       case 'document':
//         return Icons.description;
//       case 'link':
//         return Icons.link;
//       case 'note':
//         return Icons.note;
//       default:
//         return Icons.folder;
//     }
//   }
// }

// class _MaterialDialog extends StatefulWidget {
//   final CourseMaterial? material;
//   final int? materialIndex;
//   final Function(CourseMaterial) onMaterialAdded;

//   const _MaterialDialog({
//     this.material,
//     this.materialIndex,
//     required this.onMaterialAdded,
//   });

//   @override
//   State<_MaterialDialog> createState() => _MaterialDialogState();
// }

// class _MaterialDialogState extends State<_MaterialDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _titleController;
//   late final TextEditingController _descriptionController;
//   late final TextEditingController _urlController;
//   late String _selectedType;

//   @override
//   void initState() {
//     super.initState();

//     _titleController = TextEditingController(
//       text: widget.material?.title ?? '',
//     );
//     _descriptionController = TextEditingController(
//       text: widget.material?.description ?? '',
//     );
//     _urlController = TextEditingController(text: widget.material?.url ?? '');
//     _selectedType = widget.material?.type ?? 'document';
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _urlController.dispose();
//     super.dispose();
//   }

//   void _saveMaterial() {
//     if (!_formKey.currentState!.validate()) return;

//     final material = CourseMaterial(
//       id: widget.material?.id ?? const Uuid().v4(),
//       title: _titleController.text.trim(),
//       description: _descriptionController.text.trim().isEmpty
//           ? null
//           : _descriptionController.text.trim(),
//       url: _urlController.text.trim().isEmpty
//           ? null
//           : _urlController.text.trim(),
//       type: _selectedType,
//       uploadedAt: widget.material?.uploadedAt ?? DateTime.now(),
//       courseId: '',
//     );

//     widget.onMaterialAdded(material);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Material Type
//                 DropdownButtonFormField<String>(
//                   value: _selectedType,
//                   decoration: const InputDecoration(labelText: 'Material Type'),
//                   items: const [
//                     DropdownMenuItem(
//                       value: 'video',
//                       child: Text('Video (Drive Link)'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'document',
//                       child: Text('Document (PDF)'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'link',
//                       child: Text('External Link'),
//                     ),
//                     DropdownMenuItem(value: 'note', child: Text('Text Note')),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedType = value!;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Title
//                 TextFormField(
//                   controller: _titleController,
//                   decoration: const InputDecoration(
//                     labelText: 'Title *',
//                     hintText: 'Enter material title',
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter title';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),

//                 // Description
//                 TextFormField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     hintText: 'Enter material description',
//                   ),
//                   maxLines: 2,
//                 ),
//                 const SizedBox(height: 16),

//                 // URL/Content based on type
//                 if (_selectedType == 'video') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'Google Drive Video Link',
//                       hintText: 'https://drive.google.com/...',
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter video link';
//                       }
//                       if (!value.contains('drive.google.com')) {
//                         return 'Please enter a valid Google Drive link';
//                       }
//                       return null;
//                     },
//                   ),
//                 ] else if (_selectedType == 'document') ...[
//                   const Text(
//                     'Note: PDF upload will be implemented using base64 conversion in the actual implementation.',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontStyle: FontStyle.italic,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // TODO: Implement PDF upload with base64 conversion
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'PDF upload feature will be implemented',
//                           ),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.upload_file),
//                     label: const Text('Upload PDF'),
//                   ),
//                 ] else if (_selectedType == 'link') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'External Link',
//                       hintText: 'https://example.com',
//                     ),
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter link';
//                       }
//                       if (!value.startsWith('http')) {
//                         return 'Please enter a valid URL';
//                       }
//                       return null;
//                     },
//                   ),
//                 ] else if (_selectedType == 'note') ...[
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: 'Note Content',
//                       hintText: 'Enter your text note here...',
//                     ),
//                     maxLines: 5,
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return 'Please enter note content';
//                       }
//                       return null;
//                     },
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(onPressed: _saveMaterial, child: const Text('Save')),
//       ],
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course_model.dart';
import '../../models/class_model.dart';

// State management class for course creation
class CourseCreateState extends ChangeNotifier {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedClassId;
  bool _isLoading = false;
  List<CourseMaterial> _materials = [];
  List<ClassModel> _teacherClasses = [];
  bool _classesLoaded = false;

  // Getters
  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  String? get selectedClassId => _selectedClassId;
  bool get isLoading => _isLoading;
  List<CourseMaterial> get materials => _materials;
  List<ClassModel> get teacherClasses => _teacherClasses;
  bool get classesLoaded => _classesLoaded;

  // Setters with safe notification
  void setSelectedClassId(String? value, {bool notify = true}) {
    _selectedClassId = value;
    if (notify) notifyListeners();
  }

  void setIsLoading(bool value, {bool notify = true}) {
    _isLoading = value;
    if (notify) notifyListeners();
  }

  void setTeacherClasses(List<ClassModel> classes, {bool notify = true}) {
    _teacherClasses = classes;
    _classesLoaded = true;
    if (notify) notifyListeners();
  }

  // Material methods
  void addMaterial(CourseMaterial material, {bool notify = true}) {
    _materials.add(material);
    if (notify) notifyListeners();
  }

  void updateMaterial(int index, CourseMaterial material,
      {bool notify = true}) {
    if (index >= 0 && index < _materials.length) {
      _materials[index] = material;
      if (notify) notifyListeners();
    }
  }

  void removeMaterial(int index, {bool notify = true}) {
    if (index >= 0 && index < _materials.length) {
      _materials.removeAt(index);
      if (notify) notifyListeners();
    }
  }

  void clearMaterials({bool notify = true}) {
    _materials.clear();
    if (notify) notifyListeners();
  }

  // Initialize from existing course
  void initializeFromCourse(CourseModel? course) {
    if (course != null) {
      _titleController.text = course.title;
      _descriptionController.text = course.description;
      _selectedClassId = course.classId;
      _materials = List.from(course.materials);
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _selectedClassId = null;
      _materials.clear();
    }
    notifyListeners();
  }

  // Validation
  bool validateForm() {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedClassId != null;
  }

  // Dispose controllers
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class CourseCreateScreen extends StatefulWidget {
  final CourseModel? course;

  const CourseCreateScreen({super.key, this.course});

  @override
  State<CourseCreateScreen> createState() => _CourseCreateScreenState();
}

class _CourseCreateScreenState extends State<CourseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  late CourseCreateState _courseState;

  @override
  void initState() {
    super.initState();
    _courseState = CourseCreateState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _courseState.initializeFromCourse(widget.course);
    });
  }

  @override
  void dispose() {
    _courseState.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate() || !_courseState.validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _courseState.setIsLoading(true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService =
        Provider.of<DatabaseService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _courseState.setIsLoading(false);
      return;
    }

    try {
      final teacherData = await authService.getTeacherData(currentUser.uid);
      if (teacherData == null) {
        throw Exception('Teacher data not found');
      }

      final classData =
          await databaseService.getClassById(_courseState.selectedClassId!);
      if (classData == null) {
        throw Exception('Class data not found');
      }

      final course = CourseModel(
        id: widget.course?.id ?? const Uuid().v4(),
        title: _courseState.titleController.text.trim(),
        description: _courseState.descriptionController.text.trim(),
        institutionId: teacherData.institutionId,
        divisionId: classData.divisionId,
        classId: _courseState.selectedClassId!,
        teacherId: currentUser.uid,
        materials: _courseState.materials,
        createdAt: widget.course?.createdAt ?? DateTime.now(),
        isActive: widget.course?.isActive ?? true,
      );

      final error = widget.course == null
          ? await databaseService.createCourse(course)
          : await databaseService.updateCourse(course);

      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.course == null
                    ? 'Course created successfully!'
                    : 'Course updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        _courseState.setIsLoading(false);
      }
    }
  }

  void _addMaterial() {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: _courseState,
        child: _MaterialDialog(
          onMaterialAdded: (material) {
            _courseState.addMaterial(material);
          },
        ),
      ),
    );
  }

  void _editMaterial(int index) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: _courseState,
        child: _MaterialDialog(
          material: _courseState.materials[index],
          materialIndex: index,
          onMaterialAdded: (material) {
            _courseState.updateMaterial(index, material);
          },
        ),
      ),
    );
  }

  void _deleteMaterial(int index) {
    _courseState.removeMaterial(index);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final isEditing = widget.course != null;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to continue')),
      );
    }

    return ChangeNotifierProvider.value(
      value: _courseState,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Course' : 'Create Course'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            _AppBarSaveButton(
              isEditing: isEditing,
              onSave: _saveCourse,
            ),
          ],
        ),
        body: _CourseFormContent(
          formKey: _formKey,
          teacherId: currentUser.uid,
          onAddMaterial: _addMaterial,
          onEditMaterial: _editMaterial,
          onDeleteMaterial: _deleteMaterial,
          onSaveCourse: _saveCourse,
          isEditing: isEditing,
        ),
      ),
    );
  }
}

// AppBar Save Button - Only listens to isLoading
class _AppBarSaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onSave;

  const _AppBarSaveButton({
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<CourseCreateState, bool>((state) => state.isLoading);

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: FilledButton.icon(
        onPressed: isLoading ? null : onSave,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save, size: 18),
        label: Text(isEditing ? 'Update' : 'Save'),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

// Main Form Content - Doesn't listen to any state changes
class _CourseFormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String teacherId;
  final VoidCallback onAddMaterial;
  final Function(int) onEditMaterial;
  final Function(int) onDeleteMaterial;
  final VoidCallback onSaveCourse;
  final bool isEditing;

  const _CourseFormContent({
    required this.formKey,
    required this.teacherId,
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
    required this.onSaveCourse,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CourseDetailsSection(teacherId: teacherId),
            const SizedBox(height: 16),
            _MaterialsSection(
              onAddMaterial: onAddMaterial,
              onEditMaterial: onEditMaterial,
              onDeleteMaterial: onDeleteMaterial,
            ),
            const SizedBox(height: 32),
            _BottomSaveButton(
              onSaveCourse: onSaveCourse,
              isEditing: isEditing,
            ),
          ],
        ),
      ),
    );
  }
}

// Course Details Section - Doesn't listen to state
class _CourseDetailsSection extends StatelessWidget {
  final String teacherId;

  const _CourseDetailsSection({required this.teacherId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _ClassSelection(teacherId: teacherId),
            const SizedBox(height: 16),
            const _TitleField(),
            const SizedBox(height: 16),
            const _DescriptionField(),
          ],
        ),
      ),
    );
  }
}

// Class Selection - Only listens to selectedClassId and teacherClasses
class _ClassSelection extends StatelessWidget {
  final String teacherId;

  const _ClassSelection({required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<ClassModel>>(
      stream: databaseService.getTeacherClasses(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final classes = snapshot.data ?? [];

        if (classes.isEmpty) {
          return _buildNoClassesWarning();
        }

        // Update classes in state only once
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final courseState =
              Provider.of<CourseCreateState>(context, listen: false);
          if (!courseState.classesLoaded) {
            courseState.setTeacherClasses(classes);
          }
        });

        return _ClassDropdown(classes: classes);
      },
    );
  }

  Widget _buildNoClassesWarning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No classes available. Please create a class first or contact your administrator to assign classes to you.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Class Dropdown - Only listens to selectedClassId
class _ClassDropdown extends StatelessWidget {
  final List<ClassModel> classes;

  const _ClassDropdown({required this.classes});

  @override
  Widget build(BuildContext context) {
    final selectedClassId = context
        .select<CourseCreateState, String?>((state) => state.selectedClassId);
    final courseState = Provider.of<CourseCreateState>(context, listen: false);

    return DropdownButtonFormField<String>(
      value: selectedClassId,
      decoration: const InputDecoration(
        labelText: 'Select Class *',
        prefixIcon: Icon(Icons.class_),
      ),
      items: classes.map((classModel) {
        return DropdownMenuItem<String>(
          value: classModel.id,
          child: Text(
            '${classModel.name} - ${classModel.subject}',
          ),
        );
      }).toList(),
      onChanged: (value) {
        courseState.setSelectedClassId(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a class';
        }
        return null;
      },
    );
  }
}

// Title Field - Doesn't listen to any state, uses controller directly
class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    final courseState = Provider.of<CourseCreateState>(context, listen: false);

    return TextFormField(
      controller: courseState.titleController,
      decoration: const InputDecoration(
        labelText: 'Course Title *',
        prefixIcon: Icon(Icons.title),
        hintText: 'Enter course title',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter course title';
        }
        return null;
      },
    );
  }
}

// Description Field - Doesn't listen to any state, uses controller directly
class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    final courseState = Provider.of<CourseCreateState>(context, listen: false);

    return TextFormField(
      controller: courseState.descriptionController,
      decoration: const InputDecoration(
        labelText: 'Course Description *',
        prefixIcon: Icon(Icons.description),
        hintText: 'Enter course description',
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter course description';
        }
        return null;
      },
    );
  }
}

// Materials Section - Only listens to materials list
class _MaterialsSection extends StatelessWidget {
  final VoidCallback onAddMaterial;
  final Function(int) onEditMaterial;
  final Function(int) onDeleteMaterial;

  const _MaterialsSection({
    required this.onAddMaterial,
    required this.onEditMaterial,
    required this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final materials = context.select<CourseCreateState, List<CourseMaterial>>(
        (state) => state.materials);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Course Materials',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${materials.length} materials',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (materials.isEmpty)
              _buildEmptyMaterialsState()
            else
              _buildMaterialsList(materials, onEditMaterial, onDeleteMaterial),
            const SizedBox(height: 16),
            _buildAddMaterialButton(onAddMaterial),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMaterialsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No materials added yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList(
    List<CourseMaterial> materials,
    Function(int) onEditMaterial,
    Function(int) onDeleteMaterial,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getMaterialColor(material.type),
              child: Icon(
                _getMaterialIcon(material.type),
                color: Colors.white,
              ),
            ),
            title: Text(material.title),
            subtitle: Text(material.type.toUpperCase()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => onEditMaterial(index),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red,
                  ),
                  onPressed: () => onDeleteMaterial(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddMaterialButton(VoidCallback onAddMaterial) {
    return ElevatedButton.icon(
      onPressed: onAddMaterial,
      icon: const Icon(Icons.add),
      label: const Text('Add Material'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getMaterialColor(String type) {
    switch (type) {
      case 'video':
        return Colors.red;
      case 'document':
        return Colors.blue;
      case 'link':
        return Colors.green;
      case 'note':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      case 'note':
        return Icons.note;
      default:
        return Icons.folder;
    }
  }
}

// Bottom Save Button - Only listens to isLoading
class _BottomSaveButton extends StatelessWidget {
  final VoidCallback onSaveCourse;
  final bool isEditing;

  const _BottomSaveButton({
    required this.onSaveCourse,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.select<CourseCreateState, bool>((state) => state.isLoading);

    return ElevatedButton(
      onPressed: isLoading ? null : onSaveCourse,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isEditing ? 'Update Course' : 'Create Course',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _MaterialDialog extends StatefulWidget {
  final CourseMaterial? material;
  final int? materialIndex;
  final Function(CourseMaterial) onMaterialAdded;

  const _MaterialDialog({
    this.material,
    this.materialIndex,
    required this.onMaterialAdded,
  });

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.material?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.material?.description ?? '',
    );
    _urlController = TextEditingController(text: widget.material?.url ?? '');
    _selectedType = widget.material?.type ?? 'document';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _saveMaterial() {
    if (!_formKey.currentState!.validate()) return;

    final material = CourseMaterial(
      id: widget.material?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      type: _selectedType,
      uploadedAt: widget.material?.uploadedAt ?? DateTime.now(),
      courseId: '',
    );

    widget.onMaterialAdded(material);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Material Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: 'Material Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'video',
                      child: Text('Video (Drive Link)'),
                    ),
                    DropdownMenuItem(
                      value: 'document',
                      child: Text('Document (PDF)'),
                    ),
                    DropdownMenuItem(
                      value: 'link',
                      child: Text('External Link'),
                    ),
                    DropdownMenuItem(value: 'note', child: Text('Text Note')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter material title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter material description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // URL/Content based on type
                if (_selectedType == 'video') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive Video Link',
                      hintText: 'https://drive.google.com/...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter video link';
                      }
                      if (!value.contains('drive.google.com')) {
                        return 'Please enter a valid Google Drive link';
                      }
                      return null;
                    },
                  ),
                ] else if (_selectedType == 'document') ...[
                  const Text(
                    'Note: PDF upload will be implemented using base64 conversion in the actual implementation.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'PDF upload feature will be implemented',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload PDF'),
                  ),
                ] else if (_selectedType == 'link') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'External Link',
                      hintText: 'https://example.com',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter link';
                      }
                      if (!value.startsWith('http')) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                  ),
                ] else if (_selectedType == 'note') ...[
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Note Content',
                      hintText: 'Enter your text note here...',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter note content';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveMaterial, child: const Text('Save')),
      ],
    );
  }
}
