class AppConfig {
  // App Information
  static const String appName = 'Gramshiksha';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Educational Management System - No Assets Required';

  // Network Image Sources
  static const String dicebeearBaseUrl = 'https://api.dicebear.com/7.x';
  static const String unsplashBaseUrl = 'https://images.unsplash.com';

  // Avatar Configurations
  static const Map<String, String> avatarStyles = {
    'student':
        '$dicebeearBaseUrl/avataaars/png?seed=student&backgroundColor=transparent',
    'teacher':
        '$dicebeearBaseUrl/avataaars/png?seed=teacher&backgroundColor=transparent&accessories=eyepatch,wayfarers,prescription01&clothingGraphic=skullOutline,skull',
    'admin':
        '$dicebeearBaseUrl/personas/png?seed=admin&backgroundColor=transparent',
  };

  // Subject Images
  static const Map<String, String> subjectImages = {
    'mathematics':
        '$unsplashBaseUrl/photo-1635070041078-e363dbe005cb?w=400&h=200&fit=crop&crop=center',
    'science':
        '$unsplashBaseUrl/photo-1532094349884-543bc11b234d?w=400&h=200&fit=crop&crop=center',
    'english':
        '$unsplashBaseUrl/photo-1455390582262-044cdead277a?w=400&h=200&fit=crop&crop=center',
    'history':
        '$unsplashBaseUrl/photo-1471731671703-74d8b7a461f5?w=400&h=200&fit=crop&crop=center',
    'geography':
        '$unsplashBaseUrl/photo-1519452575417-564c1401ecc0?w=400&h=200&fit=crop&crop=center',
  };

  // Onboarding Images
  static const List<String> onboardingBackgrounds = [
    '$unsplashBaseUrl/photo-1427504494785-3a9ca7044f45?w=800&h=600&fit=crop&crop=center', // Students learning
    '$unsplashBaseUrl/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop&crop=center', // Classroom
    '$unsplashBaseUrl/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop&crop=center', // Team collaboration
  ];

  // Celebration Images (Score-based)
  static const Map<String, String> celebrationImages = {
    'excellent':
        '$unsplashBaseUrl/photo-1513475382585-d06e58bcb0e0?w=400&h=400&fit=crop&crop=center', // Trophy/celebration
    'good':
        '$unsplashBaseUrl/photo-1559827260-dc66d52bef19?w=400&h=400&fit=crop&crop=center', // Success/thumbs up
    'average':
        '$unsplashBaseUrl/photo-1492684223066-81342ee5ff30?w=400&h=400&fit=crop&crop=center', // Encouragement
    'improvement':
        '$unsplashBaseUrl/photo-1606107557195-0e29a4b5b4aa?w=400&h=400&fit=crop&crop=center', // Growth/progress
  };

  // Empty State Images
  static const Map<String, String> emptyStateImages = {
    'no_announcements':
        '$unsplashBaseUrl/photo-1434030216411-0b793f4b4173?w=300&h=200&fit=crop&crop=center',
    'no_assignments':
        '$unsplashBaseUrl/photo-1606096559589-e638445355bb?w=300&h=200&fit=crop&crop=center',
    'no_materials':
        '$unsplashBaseUrl/photo-1481627834876-b7833e8f5570?w=300&h=200&fit=crop&crop=center',
    'no_quizzes':
        '$unsplashBaseUrl/photo-1434030216411-0b793f4b4173?w=300&h=200&fit=crop&crop=center',
  };

  // Utility Methods
  static String getStudentAvatar(String studentName) {
    return '$dicebeearBaseUrl/avataaars/png?seed=${studentName.toLowerCase()}&backgroundColor=transparent';
  }

  static String getTeacherAvatar(String teacherName) {
    return '$dicebeearBaseUrl/avataaars/png?seed=${teacherName.toLowerCase()}&backgroundColor=transparent&accessories=eyepatch,wayfarers,prescription01';
  }

  static String getSubjectImage(String subject) {
    final normalizedSubject = subject.toLowerCase().replaceAll(' ', '');
    return subjectImages[normalizedSubject] ?? subjectImages['science']!;
  }

  static String getCelebrationImage(int score) {
    if (score >= 90) return celebrationImages['excellent']!;
    if (score >= 80) return celebrationImages['good']!;
    if (score >= 70) return celebrationImages['average']!;
    return celebrationImages['improvement']!;
  }

  // Network Image Fallback
  static const String fallbackImageUrl =
      'https://via.placeholder.com/300x200/E3F2FD/1976D2?text=Gramshiksha';

  // App Theme Colors (for reference)
  static const Map<String, int> themeColors = {
    'primary': 0xFF1976D2,
    'secondary': 0xFF26A69A,
    'success': 0xFF4CAF50,
    'warning': 0xFFFF9800,
    'error': 0xFFF44336,
    'surface': 0xFFF5F5F5,
  };

  // Demo Data Configuration
  static const bool useDemoData = true;
  static const int maxDemoAnnouncements = 10;
  static const int maxDemoAssignments = 8;
  static const int maxDemoMaterials = 15;

  // Image Quality Settings
  static const String imageQuality = 'w=400&h=200&fit=crop&crop=center';
  static const String highQualityImage = 'w=800&h=600&fit=crop&crop=center';
  static const String thumbnailImage = 'w=150&h=150&fit=crop&crop=center';

  // Cache Settings
  static const Duration imageCacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100; // MB
}
