import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/home/presentation/screens/home_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AuthBloc>().add(const AuthCheckRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(user: state.user)),
          );
        } else if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LoginScreen(initialMessage: state.message),
            ),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: familyTheme.splashGradient,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.onPrimary.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 44,
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sangam Home',
                style: text.displayMedium?.copyWith(
                  color: colors.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Family Expenses & Ledger',
                style: text.bodyMedium?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  colors.onPrimary.withValues(alpha: 0.8),
                ),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
