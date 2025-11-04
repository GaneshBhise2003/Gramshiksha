import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ResponsiveAnimations {
  // Animation durations
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration staggeredDuration = Duration(milliseconds: 600);

  // Page transitions
  static Widget slideTransition({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }

  static Widget fadeSlideTransition({
    required Widget child,
    required AnimationController controller,
    Offset begin = const Offset(0.0, 0.3),
  }) {
    final slideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }

  static Widget scaleTransition({
    required Widget child,
    required AnimationController controller,
    double begin = 0.8,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      )),
      child: child,
    );
  }

  // List animations
  static Widget staggeredListAnimation({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      delay: delay,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  static Widget staggeredGridAnimation({
    required Widget child,
    required int index,
    required int columnCount,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      duration: staggeredDuration,
      columnCount: columnCount,
      child: ScaleAnimation(
        child: FadeInAnimation(child: child),
      ),
    );
  }

  // Card animations
  static Widget cardPopInAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: child,
      ),
    );
  }

  // Button animations
  static Widget buttonPressAnimation({
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: normalDuration,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          onTapDown: (details) {},
          onTapUp: (details) {},
          onTapCancel: () {},
          child: child,
        ),
      ),
    );
  }

  // Loading animations
  static Widget shimmerLoading({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                baseColor ?? Colors.grey.shade300,
                highlightColor ?? Colors.grey.shade100,
                baseColor ?? Colors.grey.shade300,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Progress animations
  static Widget progressBarAnimation({
    required double progress,
    Duration duration = normalDuration,
    Color? backgroundColor,
    Color? valueColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: backgroundColor ?? Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            valueColor ?? Theme.of(context).primaryColor,
          ),
        );
      },
    );
  }

  // Navigation animations
  static Route<T> slideRoute<T>({
    required Widget page,
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = normalDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
  }

  static Route<T> fadeRoute<T>({
    required Widget page,
    Duration duration = normalDuration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Success/Error animations
  static Widget successCheckAnimation({
    required bool show,
    Duration duration = const Duration(milliseconds: 800),
    Color color = Colors.green,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      child: show
          ? TweenAnimationBuilder<double>(
              key: const ValueKey('success'),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: duration,
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.check_circle,
                    color: color,
                    size: 48,
                  ),
                );
              },
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  static Widget errorShakeAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10.0 * animation.value * (1.0 - animation.value),
            0.0,
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Floating action button animations
  static Widget fabScaleAnimation({
    required Widget child,
    required bool visible,
    Duration duration = normalDuration,
  }) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: duration,
      curve: Curves.easeInOut,
      child: child,
    );
  }

  // Modal/Dialog animations
  static Widget modalSlideUpAnimation({
    required Widget child,
    required AnimationController controller,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }

  // Refresh animations
  static Widget pullToRefreshAnimation({
    required Widget child,
    required RefreshCallback onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 60.0,
      strokeWidth: 3.0,
      child: child,
    );
  }
}

// Animation wrapper widgets
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveAnimations.fadeSlideTransition(
      controller: _controller,
      child: widget.child,
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}