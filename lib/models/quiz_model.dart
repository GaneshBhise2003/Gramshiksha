import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { multipleChoice, trueFalse, shortAnswer }

class QuizModel {
  final String id;
  final String title;
  final String description; // Add this line
  final List<QuizQuestion> questions;
  final String teacherId;
  final String divisionId;
  final String institutionId;
  final String classId;
  final int totalMarks;
  final int timeLimit;
  final bool isActive;
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.title,
    required this.description, // Add this
    required this.questions,
    required this.teacherId,
    required this.divisionId,
    required this.institutionId,
    required this.classId,
    required this.totalMarks,
    required this.timeLimit,
    required this.isActive,
    required this.createdAt,
  });

  // Update toMap() method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description, // Add this
      'questions': questions.map((q) => q.toMap()).toList(),
      'teacherId': teacherId,
      'divisionId': divisionId,
      'institutionId': institutionId,
      'classId': classId,
      'totalMarks': totalMarks,
      'timeLimit': timeLimit,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      questions: (map['questions'] as List<dynamic>)
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      teacherId: map['teacherId'] as String,
      divisionId: map['divisionId'] as String,
      institutionId: map['institutionId'] as String,
      classId: map['classId'] as String,
      totalMarks: map['totalMarks'] as int,
      timeLimit: map['timeLimit'] as int,
      isActive: map['isActive'] as bool,
      // FIX: Handle both Timestamp and int formats
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

// Helper method to handle Timestamp conversion
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else {
      return DateTime.now();
    }
  }
  // Update fromMap() method
  // factory QuizModel.fromMap(Map<String, dynamic> map) {
  //   return QuizModel(
  //     id: map['id'] as String,
  //     title: map['title'] as String,
  //     description: map['description'] as String? ?? '', // Add this with default
  //     questions: (map['questions'] as List<dynamic>)
  //         .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
  //         .toList(),
  //     teacherId: map['teacherId'] as String,
  //     divisionId: map['divisionId'] as String,
  //     institutionId: map['institutionId'] as String,
  //     classId: map['classId'] as String,
  //     totalMarks: map['totalMarks'] as int,
  //     timeLimit: map['timeLimit'] as int,
  //     isActive: map['isActive'] as bool,
  //     createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
  //   );
  // }
  factory QuizModel.unknown({String id = 'unknown'}) {
    return QuizModel(
      id: id,
      title: 'Unknown Quiz',
      description: 'This quiz is no longer available',
      questions: [],
      teacherId: '',
      divisionId: '',
      institutionId: '',
      classId: '',
      totalMarks: 0,
      timeLimit: 0,
      isActive: false,
      createdAt: DateTime.now(),
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final int marks;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.marks,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswer': correctAnswer,
      'marks': marks,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      marks: map['marks'] ?? 0,
    );
  }
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final Map<String, String> answers;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int? totalScore;
  final bool isCompleted;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.startedAt,
    this.submittedAt,
    this.totalScore,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'answers': answers,
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'totalScore': totalScore,
      'isCompleted': isCompleted,
    };
  }

  factory QuizAttempt.fromMap(Map<String, dynamic> map) {
    return QuizAttempt(
      id: (map['id'] ?? '').toString(),
      quizId: (map['quizId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      answers: Map<String, String>.from(map['answers'] ?? {}),
      startedAt: _parseTimestamp(map['startedAt']),
      submittedAt: _parseTimestamp(map['submittedAt']),
      totalScore: (map['totalScore'] as int?) ?? 0,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }
}
