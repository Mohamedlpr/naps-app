import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api_client.dart';
import 'app_models.dart';
import 'app_shell.dart';
import 'app_theme.dart';
import 'auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = await ApiClient.create();
  runApp(NapsApp(apiClient: apiClient));
}

class NapsApp extends StatefulWidget {
  const NapsApp({super.key, required this.apiClient});
  final ApiClient apiClient;

  @override
  State<NapsApp> createState() => _NapsAppState();
}

class _NapsAppState extends State<NapsApp> {
  AppUser? user;
  bool restoringSession = true;
  String? sessionError;

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      user = await widget.apiClient.restoreSession();
    } on ApiException catch (error) {
      sessionError = error.message;
    } finally {
      if (mounted) setState(() => restoringSession = false);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'إدارة العمل | NAPS',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('ar', 'EG'),
    supportedLocales: const [Locale('ar', 'EG')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: restoringSession
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : user == null
        ? AuthenticationScreen(
            apiClient: widget.apiClient,
            initialError: sessionError,
            onAuthenticated: (newUser) => setState(() {
              user = newUser;
              sessionError = null;
            }),
          )
        : AppShell(
            apiClient: widget.apiClient,
            user: user!,
            onLogout: () => setState(() {
              user = null;
            }),
          ),
  );
}
