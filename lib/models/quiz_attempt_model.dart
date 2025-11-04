import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final String divisionId;
  final Map<String, String> answers;
  final int score;
  final int totalMarks;
  final int timeTaken; // in seconds
  final DateTime startedAt;
  final DateTime completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.divisionId,
    required this.answers,
    required this.score,
    required this.totalMarks,
    required this.timeTaken,
    required this.startedAt,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'divisionId': divisionId,
      'answers': answers,
      'score': score,
      'totalMarks': totalMarks,
      'timeTaken': timeTaken,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt.millisecondsSinceEpoch,
    };
  }

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map) {
    return QuizAttemptModel(
      id: (map['id'] ?? '').toString(),
      quizId: (map['quizId'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
      studentName: (map['studentName'] ?? 'Unknown Student').toString(),
      divisionId: (map['divisionId'] ?? '').toString(),
      answers: Map<String, String>.from(map['answers'] ?? {}),
      score: _parseInt(map['score']),
      totalMarks: _parseInt(map['totalMarks']),
      timeTaken: _parseInt(map['timeTaken']),
      startedAt: _parseTimestamp(map['startedAt']),
      completedAt: _parseTimestamp(map['completedAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is double) return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateTime.now();
  }

  double get percentage => totalMarks > 0 ? (score / totalMarks * 100) : 0;

  String get grade {
    final percent = percentage;
    if (percent >= 90) return 'A+';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B';
    if (percent >= 60) return 'C';
    return 'D';
  }

  Color get scoreColor {
    final percent = percentage;
    if (percent >= 80) return Colors.green;
    if (percent >= 60) return Colors.orange;
    return Colors.red;
  }
}