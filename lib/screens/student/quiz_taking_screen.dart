import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_model.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final QuizModel quiz;
  final StudentModel student;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.student,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late final PageController _pageController;
  late final Map<String, String> _answers;
  late final DateTime _quizStartTime;
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _answers = {};
    _quizStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: 24),
              Expanded(child: _buildQuestion(question)),
              const SizedBox(height: 24),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.quiz.title),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _onWillPop(),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
      backgroundColor: Colors.grey.withOpacity(0.3),
      valueColor: AlwaysStoppedAnimation<Color>(
        Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildQuestion(QuizQuestion question) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ..._buildOptions(question),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(QuizQuestion question) {
    return question.options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      final optionKey = String.fromCharCode(65 + index); // A, B, C, D
      final isSelected = _answers[question.id] == optionKey;

      return _OptionCard(
        optionKey: optionKey,
        optionText: option,
        isSelected: isSelected,
        onTap: () => _selectAnswer(question.id, optionKey),
      );
    }).toList();
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentQuestionIndex > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _getNextButtonAction(),
            icon: _isSubmitting
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(_getNextButtonIcon()),
            label: Text(_getNextButtonText()),
          ),
        ),
      ],
    );
  }

  void _selectAnswer(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  VoidCallback? _getNextButtonAction() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      return _nextQuestion;
    } else {
      return _submitQuiz;
    }
  }

  IconData _getNextButtonIcon() {
    return _currentQuestionIndex < widget.quiz.questions.length - 1
        ? Icons.arrow_forward
        : Icons.check;
  }

  String _getNextButtonText() {
    return _currentQuestionIndex < widget.quiz.questions.length - 1
        ? 'Next'
        : 'Submit Quiz';
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      // Calculate score
      final score = _calculateScore();
      final timeTaken = DateTime.now().difference(_quizStartTime).inSeconds;

      // Create quiz attempt
      final attempt = QuizAttemptModel(
        id: '${widget.student.uid}_${widget.quiz.id}_${DateTime.now().millisecondsSinceEpoch}',
        quizId: widget.quiz.id,
        studentId: widget.student.uid,
        studentName: widget.student.name,
        divisionId: widget.student.divisionId,
        answers: _answers,
        score: score,
        totalMarks: widget.quiz.totalMarks,
        timeTaken: timeTaken,
        startedAt: _quizStartTime,
        completedAt: DateTime.now(),
      );

      await databaseService.submitQuizAttempt(attempt);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackbar(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // int _calculateScore() {
  //   int score = 0;
  //   for (final question in widget.quiz.questions) {
  //     if (_answers[question.id] == question.correctAnswer) {
  //       score += question.marks;
  //     }
  //   }
  //   return score;
  // }

//by ganesh
int _calculateScore() {
  int score = 0;
  for (final question in widget.quiz.questions) {
    final selectedOptionKey = _answers[question.id]; // This gives "A", "B", "C", "D"
    
    if (selectedOptionKey != null) {
      // Convert option key to actual answer text
      final selectedOptionIndex = selectedOptionKey.codeUnitAt(0) - 65; // A=0, B=1, C=2, D=3
      final selectedAnswerText = question.options[selectedOptionIndex];
      
      // Compare with correct answer text
      if (selectedAnswerText == question.correctAnswer) {
        score += question.marks;
      }
    }
  }
  return score;
}
  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to submit quiz: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (shouldExit && mounted) {
      Navigator.of(context).pop();
    }

    return false;
  }
}

class _OptionCard extends StatelessWidget {
  final String optionKey;
  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.optionKey,
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  optionKey,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}