import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/auth/domain/entities/user_entity.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_event.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_state.dart';
import 'package:expenses/features/auth/presentation/screens/login_screen.dart';
import 'package:expenses/features/auth/presentation/widgets/change_password_dialog.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:expenses/features/dashboard/presentation/widgets/add_wallet_dialog.dart';
import 'package:expenses/features/documents/presentation/widgets/manage_categories_bottom_sheet.dart';
import '../widgets/add_category_dialog.dart';

class SettingsScreen extends StatelessWidget {
  final SangamUserEntity user;

  const SettingsScreen({super.key, required this.user});

  void _confirmLogout(BuildContext context) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from Sangam Home?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LoginScreen(initialMessage: state.message),
                ),
                (route) => false,
              );
            }
          },
        ),
        BlocListener<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardWalletCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Wallet "${state.account.name}" created successfully',
                    style: text.bodyMedium?.copyWith(color: colors.onPrimary),
                  ),
                  backgroundColor: familyTheme.success,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: user.isAdmin
                          ? colors.primaryContainer
                          : colors.secondaryContainer,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: text.headlineSmall?.copyWith(
                          color: user.isAdmin
                              ? colors.onPrimaryContainer
                              : colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  style: text.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: user.isAdmin
                                      ? colors.primaryContainer
                                      : colors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: text.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: user.isAdmin
                                        ? colors.onPrimaryContainer
                                        : colors.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: text.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (user.isAdmin) ...[
              const SizedBox(height: 24),

              // Management Section (Admin Only)
              Text(
                'Management',
                style: text.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Add New Wallet',
                        style: text.titleMedium,
                      ),
                      subtitle: Text(
                        'Create cash bucket or family bank account',
                        style: text.bodySmall,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const AddWalletDialog(),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Add Category',
                        style: text.titleMedium,
                      ),
                      subtitle: Text(
                        'Create global or wallet-mapped category',
                        style: text.bodySmall,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const AddCategoryDialog(),
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.folder_special_outlined,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Document Categories',
                        style: text.titleMedium,
                      ),
                      subtitle: Text(
                        'Configure categories for property deeds, member IDs & records',
                        style: text.bodySmall,
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                      onTap: () => ManageCategoriesBottomSheet.show(
                        context,
                        isAdmin: user.isAdmin,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Security Section
            Text(
              'Security',
              style: text.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Change Password',
                      style: text.titleMedium,
                    ),
                    subtitle: Text(
                      'Update your account password',
                      style: text.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const ChangePasswordDialog(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account & Session Section
            Text(
              'Session',
              style: text.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: colors.error,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      'Sign Out',
                      style: text.titleMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Log out of your account on this device',
                      style: text.bodySmall,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // App Information
            Center(
              child: Column(
                children: [
                  Text(
                    'Sangam Home Expenses v1.0.0',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: familyTheme.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cloud Sync Connected',
                        style: text.bodySmall?.copyWith(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
