import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/core/utils/toast_utils.dart';
import 'package:sangam_expense/features/auth/presentation/bloc/auth_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Change Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordSuccess) {
            ToastUtils.showSuccess(context, state.message);
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ToastUtils.showError(context, state.error);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _buildPasswordField(
                        controller: _oldPasswordController,
                        label: "Current Password",
                        obscure: _obscureOld,
                        toggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                        validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: "New Password",
                        obscure: _obscureNew,
                        toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Required";
                          if (value.length < 6) return "Min 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: "Confirm New Password",
                        obscure: _obscureConfirm,
                        toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (value) {
                          if (value != _newPasswordController.text) return "Passwords do not match";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3C72),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Update Password",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E3C72))),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: toggleObscure,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            ChangePasswordRequested(
              _oldPasswordController.text,
              _newPasswordController.text,
            ),
          );
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
