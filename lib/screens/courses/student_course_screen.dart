// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../services/auth_service.dart';
// import '../../services/database_service.dart';
// import '../../models/course_model.dart';
// import '../../models/class_model.dart';
// import '../courses/course_detail_screen.dart';

// class StudentCourseScreen extends StatelessWidget {
//   const StudentCourseScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<AuthService>(context);
//     final databaseService = Provider.of<DatabaseService>(context);
//     final currentUser = authService.currentUser;

//     if (currentUser == null) {
//       return const Scaffold(
//         body: Center(child: Text('Please log in to view courses')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Courses'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: StreamBuilder<List<ClassModel>>(
//         stream: databaseService.getStudentClasses(currentUser.uid),
//         builder: (context, classSnapshot) {
//           if (classSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (classSnapshot.hasError) {
//             return Center(child: Text('Error: ${classSnapshot.error}'));
//           }

//           final classes = classSnapshot.data ?? [];

//           if (classes.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.school, size: 64, color: Colors.grey[400]),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No classes enrolled',
//                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Contact your teacher to get enrolled in a class',
//                     style: TextStyle(color: Colors.grey[500]),
//                   ),
//                 ],
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: classes.length,
//             itemBuilder: (context, index) {
//               final classModel = classes[index];
//               return Card(
//                 margin: const EdgeInsets.all(8),
//                 child: ExpansionTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.blue[100],
//                     child: Icon(Icons.class_, color: Colors.blue[800]),
//                   ),
//                   title: Text(
//                     '${classModel.name} - ${classModel.subject}',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text(classModel.section),
//                   children: [
//                     StreamBuilder<List<CourseModel>>(
//                       stream: databaseService.getClassCourses(classModel.id),
//                       builder: (context, courseSnapshot) {
//                         if (courseSnapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Center(child: CircularProgressIndicator()),
//                           );
//                         }

//                         final courses = courseSnapshot.data ?? [];

//                         if (courses.isEmpty) {
//                           return const ListTile(
//                             leading: Icon(Icons.info_outline),
//                             title: Text('No courses available'),
//                             subtitle: Text('Check back later for new courses'),
//                           );
//                         }

//                         return Column(
//                           children:
//                               courses.map((course) {
//                                 return ListTile(
//                                   leading: CircleAvatar(
//                                     backgroundColor: Colors.green[100],
//                                     child: Icon(
//                                       Icons.book,
//                                       color: Colors.green[800],
//                                     ),
//                                   ),
//                                   title: Text(
//                                     course.title,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(course.description),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         '${course.materials.length} materials • Created ${_formatDate(course.createdAt)}',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   trailing: const Icon(Icons.arrow_forward_ios),
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder:
//                                             (context) => CourseDetailScreen(
//                                               course: course,
//                                             ),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               }).toList(),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }

//updated by kaustubh
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/course_model.dart';
import '../../models/class_model.dart';

import '../courses/course_detail_screen.dart';

class StudentCourseScreen extends StatelessWidget {
  const StudentCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view courses')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<List<ClassModel>>(
        stream: databaseService.getStudentClasses(currentUser.uid),
        builder: (context, classSnapshot) {
          if (classSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (classSnapshot.hasError) {
            return Center(child: Text('Error: ${classSnapshot.error}'));
          }

          final classes = classSnapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No classes enrolled',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact your teacher to get enrolled in a class',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classModel = classes[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.class_, color: Colors.blue[800]),
                  ),
                  title: Text(
                    '${classModel.name} - ${classModel.subject}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Section: ${classModel.section}'),
                  children: [
                    StreamBuilder<List<CourseModel>>(
                      stream: databaseService.getClassCourses(classModel.id),
                      builder: (context, courseSnapshot) {
                        if (courseSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final courses = courseSnapshot.data ?? [];

                        if (courses.isEmpty) {
                          return const ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('No courses available'),
                            subtitle: Text('Check back later for new courses'),
                          );
                        }

                        return Column(
                          children: courses.map((course) {
                            return StreamBuilder<List<CourseMaterial>>(
                              stream: databaseService.getCourseMaterials(
                                course.id,
                              ),
                              builder: (context, materialSnapshot) {
                                final materials = materialSnapshot.data ?? [];
                                final materialCount = materials.length;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getCourseColor(
                                        course.title,
                                      ),
                                      child: const Icon(
                                        Icons.book,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          course.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.folder,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$materialCount materials',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(course.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CourseDetailScreen(
                                            course: course,
                                            courseMaterials: materials,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getCourseColor(String courseTitle) {
    // Generate consistent color based on course title
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
    ];
    final index = courseTitle.hashCode % colors.length;
    return colors[index];
  }
}
