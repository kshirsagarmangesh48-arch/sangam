import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expenses/core/theme/app_theme.dart';
import 'package:expenses/features/auth/domain/entities/user_entity.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expenses/features/auth/presentation/bloc/auth_state.dart';
import 'package:expenses/features/auth/presentation/screens/login_screen.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:expenses/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:expenses/features/dashboard/presentation/widgets/wallet_card.dart';
import 'package:expenses/features/settings/presentation/screens/settings_screen.dart';
import 'package:expenses/features/wallet_details/presentation/screens/wallet_details_screen.dart';

import 'package:expenses/features/documents/presentation/screens/documents_screen.dart';

class HomeScreen extends StatefulWidget {
  final SangamUserEntity user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<DashboardBloc>().add(const FetchDashboardRequested());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
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
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildWalletsView(context),
            DocumentsScreen(user: widget.user),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Wallets',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_shared_outlined),
              selectedIcon: Icon(Icons.folder_shared_rounded),
              label: 'Documents',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsView(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sangam Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(user: widget.user),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(const RefreshDashboardRequested());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top User Greeting Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: widget.user.isAdmin
                        ? familyTheme.adminGradient
                        : familyTheme.memberGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
                            child: Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : '?',
                              style: text.headlineSmall?.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: text.bodySmall?.copyWith(
                                  color: colors.onPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                widget.user.name,
                                style: text.headlineSmall?.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.onPrimary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          widget.user.role.toUpperCase(),
                          style: text.bodySmall?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Wallets Section
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DashboardLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is DashboardError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 40,
                                color: colors.error,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: text.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<DashboardBloc>()
                                    .add(const FetchDashboardRequested()),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is DashboardLoaded) {
                      final accounts = state.accounts;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Wallets (${accounts.length})',
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: 12),

                          // Wallets Grid
                          if (accounts.isEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                  horizontal: 20,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 40,
                                        color: colors.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No wallets found',
                                        style: text.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Wallets will appear here once configured.',
                                        style: text.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                              itemCount: accounts.length,
                              itemBuilder: (context, index) {
                                final account = accounts[index];
                                return WalletCard(
                                  account: account,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WalletDetailsScreen(
                                        account: account,
                                        user: widget.user,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}
