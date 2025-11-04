import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_model.dart';

enum QuizStatus { available, completed }

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final bool isTablet;
  final QuizStatus status;
  final VoidCallback onTap;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.isTablet,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildQuizInfo(),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _buildSubtitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(context),
      ],
    );
  }

  String _buildSubtitle() {
    switch (status) {
      case QuizStatus.available:
        return '${quiz.questions.length} questions • ${quiz.timeLimit} min';
      case QuizStatus.completed:
        return 'Completed • ${quiz.timeLimit} min';
    }
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (color, text, icon) = switch (status) {
      QuizStatus.available => (Colors.blue, 'Available', Icons.quiz),
      QuizStatus.completed => (Colors.green, 'Completed', Icons.check_circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.help_outline,
          text: '${quiz.questions.length} questions',
        ),
        _InfoChip(
          icon: Icons.timer,
          text: '${quiz.timeLimit} min',
        ),
        _InfoChip(
          icon: Icons.stars,
          text: '${quiz.totalMarks} marks',
        ),
      ],
    );
  }
}

class CompletedQuizCard extends StatelessWidget {
  final QuizModel quiz;
  final QuizAttemptModel attempt;
  final bool isTablet;
  final VoidCallback onTap;

  const CompletedQuizCard({
    super.key,
    required this.quiz,
    required this.attempt,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildQuizInfo(context),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed on ${DateFormat('MMM dd, yyyy').format(attempt.completedAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        _buildScoreBadge(),
      ],
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: attempt.scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: attempt.scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${attempt.percentage.round()}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: attempt.scoreColor,
            ),
          ),
          Text(
            '${attempt.score}/${attempt.totalMarks}',
            style: TextStyle(
              fontSize: 10,
              color: attempt.scoreColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.help_outline,
          text: '${quiz.questions.length} questions',
        ),
        const SizedBox(width: 16),
        _InfoChip(
          icon: Icons.timer,
          text: '${_formatDuration(attempt.timeTaken)}',
        ),
        const Spacer(),
        Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}


