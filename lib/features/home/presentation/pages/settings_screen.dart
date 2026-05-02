import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sangam_expense/features/auth/presentation/pages/change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF1E3C72).withOpacity(0.1),
                        child: Text(
                          user?['name']?[0]?.toUpperCase() ?? "U",
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3C72),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?['name'] ?? "User",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?['email'] ?? "email@example.com",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3C72).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?['role'] ?? "MEMBER",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3C72),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text("Account", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildSettingsItem(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text("Account Actions", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 16),
                _buildSettingsItem(
                  icon: Icons.logout_rounded,
                  title: "Logout",
                  color: const Color(0xFF1E3C72),
                  onTap: () => _showLogoutDialog(context),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "Sangam Expense v1.0.0",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: color)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text("Logout", style: TextStyle(color: Color(0xFF1E3C72))),
          ),
        ],
      ),
    );
  }
}
