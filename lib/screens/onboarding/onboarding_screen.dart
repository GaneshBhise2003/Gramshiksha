import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: "Welcome to Gramshiksha",
      subtitle: "Transforming Education with Technology",
      description:
          "Experience the future of learning with our innovative educational platform designed for both teachers and students.",
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      icon: Icons.school,
    ),
    OnboardingData(
      title: "Interactive Learning",
      subtitle: "Engage, Learn, Excel",
      description:
          "Access assignments, quizzes, and study materials anytime, anywhere. Learn at your own pace with offline capabilities.",
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6a11cb), Color(0xFF2575fc)],
      ),
      icon: Icons.laptop_chromebook,
    ),
    OnboardingData(
      title: "Track Your Progress",
      subtitle: "Monitor Growth & Achievement",
      description:
          "Real-time attendance tracking, performance analytics, and personalized reports to help you succeed.",
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF36d1dc), Color(0xFF5b86e5)],
      ),
      icon: Icons.trending_up,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                // Background with gradient and optional image
                Container(
                  decoration: BoxDecoration(
                    gradient: _onboardingData[_currentPage].backgroundGradient,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      image:
                          _currentPage == 0
                              ? const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400&h=800&fit=crop&crop=center',
                                ),
                                fit: BoxFit.cover,
                                opacity: 0.1,
                              )
                              : _currentPage == 1
                              ? const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400&h=800&fit=crop&crop=center',
                                ),
                                fit: BoxFit.cover,
                                opacity: 0.1,
                              )
                              : const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=400&h=800&fit=crop&crop=center',
                                ),
                                fit: BoxFit.cover,
                                opacity: 0.1,
                              ),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // Skip button
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: TextButton(
                            onPressed: _completeOnboarding,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PageView
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _onboardingData.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return AnimationLimiter(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:
                                    AnimationConfiguration.toStaggeredList(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      childAnimationBuilder:
                                          (widget) => SlideAnimation(
                                            horizontalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: widget,
                                            ),
                                          ),
                                      children: [
                                        // Icon
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isSmallScreen =
                                                constraints.maxWidth < 400;
                                            final iconSize =
                                                isSmallScreen ? 60.0 : 70.0;
                                            final padding =
                                                isSmallScreen ? 20.0 : 25.0;

                                            return Container(
                                              padding: EdgeInsets.all(padding),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _onboardingData[index].icon,
                                                size: iconSize,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 32),

                                        // Title
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isSmallScreen =
                                                constraints.maxWidth < 400;

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 20 : 32,
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  _onboardingData[index].title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:
                                                        isSmallScreen ? 24 : 28,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Subtitle
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isSmallScreen =
                                                constraints.maxWidth < 400;

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 20 : 32,
                                              ),
                                              child: Text(
                                                _onboardingData[index].subtitle,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 14 : 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        // Description
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final isSmallScreen =
                                                constraints.maxWidth < 400;

                                            return Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                    isSmallScreen ? 20 : 32,
                                              ),
                                              child: Text(
                                                _onboardingData[index]
                                                    .description,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 13 : 15,
                                                  height: 1.5,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                ),
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom section with indicators and button
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            // Page indicator
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: _onboardingData.length,
                              effect: WormEffect(
                                dotColor: Colors.white.withOpacity(0.3),
                                activeDotColor: Colors.white,
                                dotWidth: 12,
                                dotHeight: 12,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Action button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_currentPage ==
                                      _onboardingData.length - 1) {
                                    _completeOnboarding();
                                  } else {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor:
                                      _onboardingData[_currentPage]
                                          .backgroundGradient
                                          .colors
                                          .first,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.black.withOpacity(0.3),
                                ),
                                child: Text(
                                  _currentPage == _onboardingData.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final LinearGradient backgroundGradient;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.backgroundGradient,
    required this.icon,
  });
}
