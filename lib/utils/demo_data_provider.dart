class DemoDataProvider {
  static List<Map<String, dynamic>> getSampleAnnouncements() {
    return [
      {
        'id': 'demo1',
        'title': 'Mathematics Quiz Tomorrow',
        'content':
            'Don\'t forget about the mathematics quiz scheduled for tomorrow at 10 AM. Please review chapters 5-7.',
        'teacherId': 'demo_teacher',
        'classId': 'demo_class',
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        'imageUrl':
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=200&fit=crop&crop=center',
      },
      {
        'id': 'demo2',
        'title': 'Science Project Submission',
        'content':
            'Science project submissions are due next Friday. Please submit your projects along with the report.',
        'teacherId': 'demo_teacher',
        'classId': 'demo_class',
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'imageUrl':
            'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=200&fit=crop&crop=center',
      },
      {
        'id': 'demo3',
        'title': 'Parent-Teacher Meeting',
        'content':
            'Parent-teacher meeting is scheduled for this Saturday at 2 PM. Please ensure your parents attend.',
        'teacherId': 'demo_teacher',
        'classId': 'demo_class',
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'imageUrl':
            'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=200&fit=crop&crop=center',
      },
    ];
  }

  static List<Map<String, dynamic>> getSampleOfflineContent() {
    return [
      {
        'id': 'content1',
        'title': 'Mathematics - Algebra Fundamentals',
        'content':
            'Complete guide to algebraic expressions, equations, and problem-solving techniques.',
        'type': 'Study Material',
        'imageUrl':
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=200&fit=crop&crop=center',
        'downloadedAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'id': 'content2',
        'title': 'Science - Cell Biology',
        'content':
            'Detailed notes on cell structure, organelles, and cellular processes.',
        'type': 'Lecture Notes',
        'imageUrl':
            'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=200&fit=crop&crop=center',
        'downloadedAt': DateTime.now().subtract(const Duration(hours: 5)),
      },
      {
        'id': 'content3',
        'title': 'English - Grammar Essentials',
        'content':
            'Comprehensive guide to English grammar rules and usage examples.',
        'type': 'Reference Material',
        'imageUrl':
            'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400&h=200&fit=crop&crop=center',
        'downloadedAt': DateTime.now().subtract(const Duration(hours: 12)),
      },
    ];
  }

  static List<Map<String, dynamic>> getSampleAssignments() {
    return [
      {
        'id': 'assignment1',
        'title': 'Mathematics Problem Set #5',
        'description':
            'Solve all problems from chapter 5. Show your work clearly and submit neat solutions.',
        'dueDate': DateTime.now().add(const Duration(days: 3)),
        'subject': 'Mathematics',
        'status': 'pending',
        'imageUrl':
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=400&h=200&fit=crop&crop=center',
      },
      {
        'id': 'assignment2',
        'title': 'Science Lab Report',
        'description':
            'Write a detailed lab report on the recent chemistry experiment about acids and bases.',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
        'subject': 'Science',
        'status': 'pending',
        'imageUrl':
            'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=400&h=200&fit=crop&crop=center',
      },
      {
        'id': 'assignment3',
        'title': 'English Essay - "My Future Goals"',
        'description':
            'Write a 500-word essay about your future goals and how you plan to achieve them.',
        'dueDate': DateTime.now().add(const Duration(days: 5)),
        'subject': 'English',
        'status': 'completed',
        'imageUrl':
            'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400&h=200&fit=crop&crop=center',
      },
    ];
  }

  static Map<String, dynamic> getSampleStudentProfile() {
    return {
      'name': 'Alex Johnson',
      'rollNumber': 'ST2024001',
      'class': '10th Grade',
      'email': 'alex.johnson@school.edu',
      'profileImage':
          'https://api.dicebear.com/7.x/avataaars/png?seed=student&backgroundColor=transparent',
      'performance': {
        'attendance': 92,
        'averageScore': 85,
        'completedAssignments': 12,
        'pendingAssignments': 3,
        'rank': 3,
        'totalStudents': 45,
      },
    };
  }

  static Map<String, dynamic> getSampleTeacherProfile() {
    return {
      'name': 'Dr. Sarah Smith',
      'employeeId': 'TCH2024001',
      'email': 'sarah.smith@school.edu',
      'department': 'Mathematics',
      'profileImage':
          'https://api.dicebear.com/7.x/avataaars/png?seed=teacher&backgroundColor=transparent&accessories=eyepatch,wayfarers,prescription01&clothingGraphic=skullOutline,skull',
      'stats': {
        'totalClasses': 5,
        'totalStudents': 150,
        'totalAssignments': 24,
        'totalQuizzes': 12,
      },
    };
  }

  static List<Map<String, dynamic>> getCelebrationImages() {
    return [
      {
        'score': 90,
        'title': 'Outstanding Achievement!',
        'imageUrl':
            'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&h=400&fit=crop&crop=center',
        'message': 'You\'re absolutely amazing! Keep up the excellent work!',
      },
      {
        'score': 80,
        'title': 'Excellent Performance!',
        'imageUrl':
            'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=400&fit=crop&crop=center',
        'message': 'Great job! You\'re doing wonderfully!',
      },
      {
        'score': 70,
        'title': 'Good Work!',
        'imageUrl':
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400&h=400&fit=crop&crop=center',
        'message': 'Well done! Keep pushing forward!',
      },
      {
        'score': 60,
        'title': 'Keep Going!',
        'imageUrl':
            'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=400&h=400&fit=crop&crop=center',
        'message': 'Every step forward is progress. You\'ve got this!',
      },
    ];
  }
}
