import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fixops_frontend/core/constants.dart';
import 'package:fixops_frontend/providers/auth_provider.dart';
import 'package:fixops_frontend/providers/ticket_provider.dart';
import 'package:fixops_frontend/providers/admin_provider.dart';
import 'package:fixops_frontend/views/login_view.dart';
import 'package:fixops_frontend/views/main_shell.dart';
import 'package:fixops_frontend/widgets/glass_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FixOpsApp());
}

class FixOpsApp extends StatelessWidget {
  const FixOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.inter().fontFamily,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.secondary,
            onSecondary: AppColors.textMain,
            tertiary: AppColors.accentLime,
            onTertiary: AppColors.textMain,
            surface: AppColors.surface,
            onSurface: AppColors.textMain,
            error: AppColors.primary,
            onError: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.glassCardBg,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withAlpha(200), width: 1.2),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withAlpha(200),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.secondary.withAlpha(100), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withAlpha(200), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading && auth.currentUser == null) {
      return Scaffold(
        body: GlassBackground(
          child: Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(32),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Connecting to FIXOPS Services...',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (auth.isAuthenticated) {
      return const MainShell();
    } else {
      return const LoginView();
    }
  }
}
