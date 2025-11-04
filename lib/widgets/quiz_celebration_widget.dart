import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class QuizCelebrationWidget extends StatefulWidget {
  final int score;
  final VoidCallback onComplete;

  const QuizCelebrationWidget({
    super.key,
    required this.score,
    required this.onComplete,
  });

  @override
  State<QuizCelebrationWidget> createState() => _QuizCelebrationWidgetState();
}

class _QuizCelebrationWidgetState extends State<QuizCelebrationWidget>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    _startCelebration();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _startCelebration() {
    _confettiController.play();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      _bounceController.forward();
    });

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  String _getCelebrationMessage() {
    if (widget.score >= 90) {
      return "🎉 Outstanding! 🎉";
    } else if (widget.score >= 80) {
      return "🌟 Excellent Work! 🌟";
    } else if (widget.score >= 70) {
      return "👏 Great Job! 👏";
    } else {
      return "💪 Keep Going! 💪";
    }
  }

  Color _getCelebrationColor() {
    if (widget.score >= 90) {
      return Colors.amber;
    } else if (widget.score >= 80) {
      return Colors.green;
    } else if (widget.score >= 70) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  List<String> _getCelebrationEmojis() {
    if (widget.score >= 90) {
      return ["🎉", "🎊", "⭐", "🏆", "👑"];
    } else if (widget.score >= 80) {
      return ["🌟", "✨", "👍", "🎯", "💫"];
    } else if (widget.score >= 70) {
      return ["👏", "😊", "🙌", "💪", "🎈"];
    } else {
      return ["💪", "📚", "🎯", "⚡", "🚀"];
    }
  }

  String _getCelebrationImageUrl() {
    if (widget.score >= 90) {
      return 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400&h=400&fit=crop&crop=center'; // Trophy/victory
    } else if (widget.score >= 80) {
      return 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400&h=400&fit=crop&crop=center'; // Success/celebration
    } else if (widget.score >= 70) {
      return 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400&h=400&fit=crop&crop=center'; // Achievement
    } else {
      return 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=400&h=400&fit=crop&crop=center'; // Encouragement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.57,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
              shouldLoop: false,
              colors: [
                _getCelebrationColor(),
                _getCelebrationColor().withOpacity(0.8),
                Colors.white,
                Colors.yellow,
              ],
            ),
          ),

          // Main celebration content
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Celebration image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getCelebrationColor().withOpacity(0.3),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _getCelebrationImageUrl(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: _getCelebrationColor().withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 60,
                                  color: _getCelebrationColor(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Floating emojis
                      AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          final emojis = _getCelebrationEmojis();
                          return SizedBox(
                            height: 100,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ...emojis.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final emoji = entry.value;
                                  return AnimationLimiter(
                                    child: AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      child: SlideAnimation(
                                        verticalOffset:
                                            -50.0 * _bounceAnimation.value,
                                        child: FadeInAnimation(
                                          child: Transform.translate(
                                            offset: Offset(
                                              (index - 2) * 60.0,
                                              20.0 * _bounceAnimation.value,
                                            ),
                                            child: Transform.rotate(
                                              angle: (index - 2) * 0.2,
                                              child: Text(
                                                emoji,
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Score display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _getCelebrationColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${widget.score}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Celebration message
                      Text(
                        _getCelebrationMessage(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getCelebrationColor(),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Motivational message
                      Text(
                        widget.score >= 80
                            ? "You're doing amazing! Keep up the excellent work!"
                            : "Every step forward is progress. You've got this!",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Continue button
                      ElevatedButton(
                        onPressed: widget.onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCelebrationColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Continue Learning!",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper function to show the celebration
void showQuizCelebration(BuildContext context, int score) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => QuizCelebrationWidget(
          score: score,
          onComplete: () => Navigator.of(context).pop(),
        ),
  );
}
