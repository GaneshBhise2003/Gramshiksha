import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gramshiksha/screens/student/quiz_taking_screen.dart';
import 'package:intl/intl.dart';

import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_model.dart';
import '../../models/student_model.dart';

class QuizDetailsDialog extends StatelessWidget {
  final QuizModel quiz;
  final StudentModel student;

  const QuizDetailsDialog({
    super.key,
    required this.quiz,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
              const SizedBox(height: 24),
              _buildStartButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            quiz.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            label: 'Description',
            value: quiz.description.isNotEmpty
                ? quiz.description
                : 'Interactive quiz with ${quiz.questions.length} questions',
          ),
          _DetailRow(
            label: 'Number of Questions',
            value: quiz.questions.length.toString(),
          ),
          _DetailRow(
            label: 'Duration',
            value: '${quiz.timeLimit} minutes',
          ),
          _DetailRow(
            label: 'Total Marks',
            value: quiz.totalMarks.toString(),
          ),
          _DetailRow(
            label: 'Created',
            value: DateFormat('MMM dd, yyyy').format(quiz.createdAt),
          ),
          const SizedBox(height: 24),
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Answer all questions to the best of your ability\n'
                '• You can only take this quiz once\n'
                '• Make sure you have a stable internet connection\n'
                '• Submit before the time runs out',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _startQuiz(context),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Quiz'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizTakingScreen(quiz: quiz, student: student),
      ),
    );
  }
}

class QuizResultsDialog extends StatelessWidget {
  final QuizModel quiz;
  final QuizAttemptModel attempt;

  const QuizResultsDialog({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildScoreDisplay(),
              const SizedBox(height: 24),
              Expanded(child: _buildDetails()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            quiz.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: attempt.scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: attempt.scoreColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '${attempt.percentage.round()}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: attempt.scoreColor,
              ),
            ),
            Text(
              'Grade: ${attempt.grade}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: attempt.scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${attempt.score} out of ${attempt.totalMarks} marks',
              style: TextStyle(fontSize: 14, color: attempt.scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _DetailRow(
            label: 'Submitted On',
            value: DateFormat('EEEE, MMMM dd, yyyy at HH:mm')
                .format(attempt.completedAt),
          ),
          _DetailRow(
            label: 'Time Taken',
            value: _formatDuration(attempt.timeTaken),
          ),
          _DetailRow(
            label: 'Questions',
            value: '${quiz.questions.length} questions',
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}