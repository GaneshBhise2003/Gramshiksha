import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/wrapper.dart';
import '../services/offline_manager.dart';

class AppStartWrapper extends StatefulWidget {
  const AppStartWrapper({super.key});

  @override
  State<AppStartWrapper> createState() => _AppStartWrapperState();
}

class _AppStartWrapperState extends State<AppStartWrapper> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      // Initialize offline manager
      await OfflineManager().initialize();

      // Check if onboarding has been completed
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('onboarding_completed') ?? false;

      setState(() {
        _onboardingCompleted = completed;
        _isLoading = false;
      });
    } catch (e) {
      // If there's an error, skip onboarding
      setState(() {
        _onboardingCompleted = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _onboardingCompleted
        ? const AuthWrapper()
        : const OnboardingScreen();
  }
}
