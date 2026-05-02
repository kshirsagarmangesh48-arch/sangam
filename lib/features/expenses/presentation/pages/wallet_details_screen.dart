// Wallet Details Screen with transaction filtering and reassignment
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sangam_expense/features/expenses/presentation/bloc/expense_bloc.dart';
import 'package:sangam_expense/features/home/presentation/pages/home_screen.dart'; // To reuse AddTransactionScreen

class WalletDetailsScreen extends StatefulWidget {
  final dynamic wallet;
  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedMemberId;
  DateTime? _selectedMonth;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.wallet['name'].toString().toLowerCase() == 'home') {
      final now = DateTime.now();
      _selectedMonth = DateTime(now.year, now.month, 1);
    }
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabOrFilterChanged);
    _scrollController.addListener(_onScroll);
    
    // Initial fetch for the selected wallet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onTabOrFilterChanged();
    });
  }

  List<DateTime> _getPastMonths() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabOrFilterChanged);
    _scrollController.removeListener(_onScroll);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<ExpenseBloc>().state;
      if (state is ExpenseDashboardLoaded && state.pagination != null) {
        final pagination = state.pagination!;
        if (pagination['page'] < pagination['totalPages']) {
          final type = _tabController.index == 0 ? null : (_tabController.index == 1 ? 'INCOME' : 'EXPENSE');
          final filters = {
            'accountId': widget.wallet['id'],
            'memberId': _selectedMemberId,
            'type': type,
            'page': pagination['page'] + 1,
            'limit': pagination['limit'],
          };
          if (_selectedMonth != null) {
            filters['startDate'] = _selectedMonth!.toIso8601String();
            filters['endDate'] = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0, 23, 59, 59, 999).toIso8601String();
          }
          context.read<ExpenseBloc>().add(LoadMoreTransactions(filters));
        }
      }
    }
  }

  void _onTabOrFilterChanged() {
    final type = _tabController.index == 0
        ? null
        : (_tabController.index == 1 ? 'INCOME' : 'EXPENSE');
    final filters = {
      'accountId': widget.wallet['id'],
      'memberId': _selectedMemberId,
      'type': type,
    };
    if (_selectedMonth != null) {
      filters['startDate'] = _selectedMonth!.toIso8601String();
      filters['endDate'] =
          DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0, 23, 59, 59, 999)
              .toIso8601String();
    }
    // Fetch both transactions and stats for this specific wallet/filter
    context.read<ExpenseBloc>().add(FetchTransactionsRequested(filters));
    context.read<ExpenseBloc>().add(FetchDashboardData(filters: filters));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          // Refresh data with current filters when an action (add/delete/update) succeeds
          _onTabOrFilterChanged();
        }
      },
      builder: (context, state) {
        if (state is ExpenseError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.wallet['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<ExpenseBloc>().add(FetchDashboardData()),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (state is! ExpenseDashboardLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // We use the transactions directly from the state as they are now filtered by backend
        final walletTransactions = state.transactions;
        final walletInfo = state.accounts.firstWhere(
          (a) => a['id'] == widget.wallet['id'],
          orElse: () => widget.wallet,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: Text(
              widget.wallet['name'],
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
            actions: [
              if (_selectedMonth != null)
                DropdownButtonHideUnderline(
                  child: DropdownButton<DateTime>(
                    value: _selectedMonth,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E3C72)),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E3C72),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    onChanged: (DateTime? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMonth = newValue;
                        });
                        _onTabOrFilterChanged();
                      }
                    },
                    items: _getPastMonths().map<DropdownMenuItem<DateTime>>((DateTime date) {
                      return DropdownMenuItem<DateTime>(
                        value: date,
                        child: Text(DateFormat('MMM yyyy').format(date)),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              _buildWalletStats(walletInfo, state),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1E3C72),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF1E3C72),
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Income"),
                  Tab(text: "Expense"),
                ],
              ),
              const SizedBox(height: 8),
              _buildMemberChips(state.familyMembers),
              const SizedBox(height: 12),
              Expanded(
                child: state.isRefreshingTransactions
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: _buildTransactionList(walletTransactions),
                          ),
                          if (state.isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTransaction(context, 'INCOME'),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Income",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTransaction(context, 'EXPENSE'),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Expense",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberChips(List<dynamic> members) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Everyone"),
            selected: _selectedMemberId == null,
            onSelected: (val) {
              setState(() => _selectedMemberId = null);
              _onTabOrFilterChanged();
            },
            selectedColor: const Color(0xFF1E3C72).withOpacity(0.2),
            labelStyle: GoogleFonts.outfit(
              color: _selectedMemberId == null
                  ? const Color(0xFF1E3C72)
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(m['name']),
                selected: _selectedMemberId == m['id'],
                onSelected: (val) {
                  setState(() => _selectedMemberId = val ? m['id'] : null);
                  _onTabOrFilterChanged();
                },
                selectedColor: const Color(0xFF1E3C72).withOpacity(0.2),
                labelStyle: GoogleFonts.outfit(
                  color: _selectedMemberId == m['id']
                      ? const Color(0xFF1E3C72)
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStats(dynamic wallet, ExpenseDashboardLoaded state) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Balance",
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                "₹${wallet['balance']}",
                key: ValueKey("balance_${wallet['balance']}"),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (wallet['description'] != null && wallet['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                wallet['description'],
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildPaidByDistributionBar(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidByDistributionBar(ExpenseDashboardLoaded state) {
    final distribution = state.filterStats?['paidByDistribution'] as List<dynamic>?;
    if (distribution == null || distribution.isEmpty) return const SizedBox.shrink();

    final members = state.familyMembers;

    // Aggregate net amounts from distribution
    Map<int, double> memberNetAmounts = {};
    double totalAbsolute = 0;

    for (var item in distribution) {
      final memberId = item['memberId'];
      if (memberId == null) continue;
      double amount = double.tryParse(item['total'].toString()) ?? 0;
      memberNetAmounts[memberId] = amount;
      totalAbsolute += amount.abs();
    }

    if (totalAbsolute == 0) return const SizedBox.shrink();

    final activeMembers = members.where((m) => memberNetAmounts.containsKey(m['id'])).toList();
    if (activeMembers.isEmpty) return const SizedBox.shrink();

    final List<Color> barColors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.tealAccent,
      Colors.amberAccent,
      Colors.cyanAccent,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ...activeMembers.asMap().entries.map((entry) {
          int idx = entry.key;
          var m = entry.value;
          double amount = memberNetAmounts[m['id']]!;
          double percentage = totalAbsolute > 0 ? (amount.abs() / totalAbsolute) : 0;
          Color barColor = barColors[idx % barColors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m['name'],
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "₹${amount.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        color: amount > 0 ? Colors.greenAccent : (amount < 0 ? Colors.redAccent : Colors.white),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionList(List<dynamic> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text("No transactions recorded for this wallet"),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isExpense = t['type'] == 'EXPENSE';
        final color = isExpense ? Colors.red : Colors.green;
        final bgColor = isExpense ? Colors.red.shade50 : Colors.green.shade50;
        final icon = isExpense ? Icons.north_east : Icons.south_west;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            t['category']?['name'] ?? "General",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF1E3C72),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "${isExpense ? '-' : '+'}₹${t['amount']}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                      Text(
                        t['description'],
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(DateTime.parse(t['date'])),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (!isExpense && t['spentBy'] != null) ...[
                                const Text(" • ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                InkWell(
                                  onTap: () => _showReassignMemberSheet(context, t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E3C72).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "By: ${t['spentBy']['name']}",
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF1E3C72),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.sync_alt, size: 10, color: Color(0xFF1E3C72)),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else if (isExpense && t['paidBy'] != null) ...[
                                const Text(" • ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                InkWell(
                                  onTap: () => _showReassignMemberSheet(context, t),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Paid by: ${t['paidBy']['name']}",
                                          style: GoogleFonts.outfit(
                                            color: Colors.deepOrange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.sync_alt, size: 10, color: Colors.deepOrange),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmDelete(context, t['id']),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction?"),
        content: const Text(
          "Are you sure you want to delete this record? This will also adjust the wallet balance.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteTransactionRequested(id));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddTransaction(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialAccountId: widget.wallet['id'],
          initialType: type,
        ),
      ),
    );
  }

  void _showReassignMemberSheet(BuildContext context, dynamic transaction) {
    final state = context.read<ExpenseBloc>().state as ExpenseDashboardLoaded;
    final isExpense = transaction['type'] == 'EXPENSE';
    final sheetTitle = isExpense ? "Reassign Paid By" : "Reassign Income To";
    final currentMemberId = isExpense ? transaction['paidById'] : transaction['spentById'];
    final fieldToUpdate = isExpense ? 'paidById' : 'spentById';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sheetTitle,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...state.familyMembers.map(
              (member) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1E3C72).withOpacity(0.1),
                  child: Text(
                    member['name'][0],
                    style: const TextStyle(color: Color(0xFF1E3C72)),
                  ),
                ),
                title: Text(member['name'], style: GoogleFonts.outfit()),
                trailing: currentMemberId == member['id']
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  context.read<ExpenseBloc>().add(
                    UpdateTransactionRequested(transaction['id'], {
                      fieldToUpdate: member['id'],
                    }),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
