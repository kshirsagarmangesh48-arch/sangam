import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/features/auth/data/auth_repository.dart';
import 'package:sangam_expense/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sangam_expense/features/auth/presentation/pages/login_screen.dart';
import 'package:sangam_expense/features/expenses/data/expense_repository.dart';
import 'package:sangam_expense/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:sangam_expense/features/home/presentation/pages/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => ExpenseRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>())..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => ExpenseBloc(context.read<ExpenseRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'Sangam',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3C72),
              primary: const Color(0xFF1E3C72),
            ),
            useMaterial3: true,
            textTheme: GoogleFonts.outfitTextTheme(),
          ),
          builder: (context, child) {
            return BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  // Clear navigation stack and go to login
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: child!,
            );
          },
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const HomeScreen();
              } else if (state is AuthUnauthenticated || state is AuthFailure) {
                return const LoginScreen();
              }
              // Show splash or loading while checking session
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
