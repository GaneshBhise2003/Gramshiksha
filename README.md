# Gramshikshika Portal - Educational Management System

A comprehensive educational portal built with Flutter, Firebase Authentication, and Cloud Firestore for managing classes, students, assignments, quizzes, attendance, and more.

## 🚀 Features

### For Teachers:
- **Authentication**: Secure registration, login, password reset
- **Class Management**: Create/manage classes, assign students, track analytics
- **Student Management**: Create student accounts, bulk import, manage profiles
- **Assignment Management**: Create assignments, track submissions, grade with feedback
- **Quiz Management**: Create quizzes with auto-grading, view results
- **Attendance Management**: Mark attendance, generate reports
- **Announcements**: Create class-specific announcements
- **Reports & Analytics**: Visual reports, performance tracking

### For Students:
- **Dashboard**: Progress overview, attendance summary, announcements
- **My Courses**: Access study materials and resources
- **Take Quiz**: Attempt quizzes with timer, view results
- **Assignments**: Submit work, check grades and feedback
- **Profile**: View personal details, attendance, and marks
- **Leaderboard**: View class rankings

## 📋 Prerequisites

- Flutter SDK (3.7.0 or higher)
- Firebase account
- Android Studio / VS Code with Flutter extensions

## 🔧 Installation

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Firebase Setup

#### Create Firebase Project:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: `gramshikshika`
3. Enable **Email/Password** authentication
4. Create **Firestore Database** (test mode for development)

#### Update Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 3. Run the application
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── services/                 # Authentication & Database services
└── screens/                  # UI screens (auth, teacher, student)
```

## 🗄️ Firestore Collections

- `users` - User accounts (role-based)
- `teachers` - Teacher profiles
- `students` - Student profiles
- `classes` - Class information
- `assignments` - Assignment data
- `quizzes` - Quiz data
- `attendance` - Attendance records
- `announcements` - Class announcements
- `courses` - Course materials

## 🔐 Security

- Firebase Authentication (Email/Password only)
- Role-based access (Teacher/Student)
- Firestore security rules
- Password reset functionality

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows

## 🚦 Getting Started

### Teacher Registration:
1. Register as Teacher
2. Create classes with unique codes
3. Add students and share credentials
4. Create assignments, quizzes, and materials

### Student Login:
1. Use credentials from teacher
2. Reset password on first login
3. Access assignments, quizzes, and courses

## 📝 Key Dependencies

- `firebase_core` & `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `provider` - State management
- `fl_chart` - Charts and graphs
- `pdf` & `printing` - Report generation

## ⚠️ Important Notes

### Firebase Free Tier:
- Firestore: 1GB storage, 50K reads/day, 20K writes/day
- Monitor usage in Firebase Console

### No Storage Used:
This app uses **only** Firebase Authentication and Firestore (free services). File uploads are stored as URLs/links in Firestore documents.

## 🎯 Future Enhancements

- [ ] Video lecture integration
- [ ] Live class sessions
- [ ] Parent portal
- [ ] Mobile notifications
- [ ] Offline mode
- [ ] Multi-language support

---

**Built with Flutter + Firebase (Authentication & Firestore only)**


- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
