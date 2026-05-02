import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/core/utils/toast_utils.dart';
import 'package:sangam_expense/features/home/presentation/pages/home_screen.dart';
import 'package:sangam_expense/features/auth/presentation/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ToastUtils.showSuccess(context, "Welcome back, ${state.user['name']}!");
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is AuthFailure) {
            ToastUtils.showError(context, state.error.replaceAll('Exception: ', ''));
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onTogglePassword: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 32),
                      _buildLoginButton(state),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text('Sangam Expense', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text('Family Money Manager', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildLoginButton(AuthState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state is AuthLoading
            ? null
            : () {
                if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                  ToastUtils.showError(context, "Please fill all fields");
                  return;
                }
                context.read<AuthBloc>().add(
                      LoginRequested(_emailController.text.trim(), _passwordController.text),
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E3C72),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: state is AuthLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3))
            : Text('Login', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white24, width: 2)),
      ),
    );
  }
}
