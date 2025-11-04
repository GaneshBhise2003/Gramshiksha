import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/app_start_wrapper.dart';
import 'utils/responsive_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'Gramshiksha',
        debugShowCheckedModeBanner: false,
        theme: ResponsiveTheme.getLightTheme(),
        darkTheme: ResponsiveTheme.getDarkTheme(),
        themeMode: ThemeMode.system, // Automatically switch between light/dark
        home: const AppStartWrapper(),
      ),
    );
  }
}
