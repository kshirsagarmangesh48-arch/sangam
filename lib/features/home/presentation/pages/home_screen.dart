// Home Screen for Sangam Family Expense Manager
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sangam_expense/core/utils/toast_utils.dart';
import 'package:sangam_expense/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sangam_expense/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:sangam_expense/features/expenses/presentation/pages/category_management_screen.dart';
import 'package:sangam_expense/features/expenses/presentation/pages/wallet_details_screen.dart';
import 'package:sangam_expense/features/expenses/presentation/pages/wallet_management_screen.dart';
import 'package:sangam_expense/features/home/presentation/pages/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(FetchDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseError) {
            ToastUtils.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ExpenseBloc>().add(FetchDashboardData());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Wallets",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWalletsGrid(context, state),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state is ExpenseError ? state.message : "No data available",
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<ExpenseBloc>().add(FetchDashboardData()),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello,",
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final name = state is AuthAuthenticated
                  ? state.user['name']
                  : "User";
              return Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF1E3C72)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWalletsGrid(BuildContext context, ExpenseDashboardLoaded state) {
    final accounts = state.accounts;
    final isAdmin =
        context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).user['role'] ==
            'ADMIN';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: accounts.length + (isAdmin ? 2 : 0),
      itemBuilder: (context, index) {
        if (index == accounts.length) {
          // Manage Wallets Button for Admin
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WalletManagementScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E3C72).withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E3C72).withOpacity(0.2),
                  style: BorderStyle.none,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings_suggest_outlined,
                    size: 40,
                    color: Color(0xFF1E3C72),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Manage\nWallets",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3C72),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (index == accounts.length + 1) {
          // Manage Categories Button for Admin
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 40,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Manage\nCategories",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final wallet = accounts[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WalletDetailsScreen(wallet: wallet),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3C72).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: Color(0xFF1E3C72),
                  ),
                ),
                const Spacer(),
                Text(
                  wallet['name'],
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${wallet['balance']}",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: (wallet['balance'] as num) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsSection(List<dynamic> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Recent Transactions",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        transactions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("No transactions yet"),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  final isExpense = t['type'] == 'EXPENSE';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isExpense ? Colors.red : Colors.green)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isExpense
                                ? Icons.arrow_outward
                                : Icons.arrow_downward,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['category']?['name'] ?? "Other",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Spent by: ${t['spentBy']['name']} • Paid by: ${t['paidBy']['name']}",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (t['description'] != null)
                                Text(
                                  t['description'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          "${isExpense ? '-' : '+'}₹${t['amount']}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    // I'll implement a full separate screen for adding transaction for better UX
    // But for now, I'll just show a placeholder to prove the layout
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
  }

  void _showManageWalletsSheet(BuildContext context, List<dynamic> accounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Wallets",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final wallet = accounts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      wallet['name'],
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Current Balance: ₹${wallet['balance']}"),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF1E3C72),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditWalletSheet(context, wallet);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWalletSheet(BuildContext context, dynamic wallet) {
    final nameController = TextEditingController(text: wallet['name']);
    final descController = TextEditingController(
      text: wallet['description'] ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit Wallet",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Wallet Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<ExpenseBloc>().add(
                      UpdateWalletRequested(
                        wallet['id'],
                        nameController.text,
                        descController.text,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Save Changes",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create New Wallet",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Wallet Name (e.g. Home, Shop)",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<ExpenseBloc>().add(
                      CreateWalletRequested(
                        nameController.text,
                        descController.text,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Create Wallet",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final int? initialAccountId;
  final String? initialType;
  const AddTransactionScreen({
    super.key,
    this.initialAccountId,
    this.initialType,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'EXPENSE';
  int? _accountId;
  int? _categoryId;
  int? _spentById;
  int? _paidById;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Record Transaction")),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is! ExpenseDashboardLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          // No default member selection — leave both null

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.initialType == null) ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'EXPENSE',
                        label: Text('Expense'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: 'INCOME',
                        label: Text('Income'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (val) =>
                        setState(() => _type = val.first),
                  ),
                  const SizedBox(height: 24),
                ],
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    prefixText: "₹",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.initialAccountId == null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: "Wallet / Account",
                      border: OutlineInputBorder(),
                    ),
                    items: state.accounts
                        .map(
                          (a) => DropdownMenuItem<int>(
                            value: a['id'],
                            child: Text(a['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _accountId = val),
                    initialValue: _accountId,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  items: state.categories
                      .where(
                        (c) =>
                            c['type'] == _type &&
                            (c['accountId'] == null ||
                                c['accountId'] == _accountId),
                      )
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _categoryId = val),
                  // Safety: If current category is not in the filtered list, reset it
                  initialValue:
                      state.categories
                          .where(
                            (c) =>
                                c['type'] == _type &&
                                (c['accountId'] == null ||
                                    c['accountId'] == _accountId),
                          )
                          .any((c) => c['id'] == _categoryId)
                      ? _categoryId
                      : null,
                ),
                const SizedBox(height: 16),
                if (_type == 'INCOME') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: "Received By (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("None"),
                      ),
                      ...state.familyMembers
                          .map<DropdownMenuItem<int?>>(
                            (m) => DropdownMenuItem<int?>(
                              value: m['id'],
                              child: Text(m['name']),
                            ),
                          ),
                    ],
                    onChanged: (val) => setState(() => _spentById = val),
                    value: _spentById,
                  ),
                ],
                if (_type == 'EXPENSE') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: "Paid By (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("None"),
                      ),
                      ...state.familyMembers
                          .map<DropdownMenuItem<int?>>(
                            (m) => DropdownMenuItem<int?>(
                              value: m['id'],
                              child: Text(m['name']),
                            ),
                          ),
                    ],
                    onChanged: (val) => setState(() => _paidById = val),
                    value: _paidById,
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_amountController.text.isEmpty ||
                          _accountId == null) {
                        ToastUtils.showError(
                          context,
                          "Amount and Wallet are required",
                        );
                        return;
                      }
                      context.read<ExpenseBloc>().add(
                        AddTransactionRequested({
                          'amount': _amountController.text,
                          'type': _type,
                          'accountId': _accountId,
                          'categoryId': _categoryId,
                          'spentById': _spentById,
                          'paidById': _paidById,
                          'description': _descController.text,
                        }),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Save Transaction",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
