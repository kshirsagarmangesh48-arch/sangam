import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/features/expenses/presentation/bloc/expense_bloc.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Manage Categories",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Expense"),
            Tab(text: "Income"),
          ],
          labelColor: const Color(0xFF1E3C72),
          indicatorColor: const Color(0xFF1E3C72),
        ),
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseDashboardLoaded) {
            final expenseCategories = state.categories
                .where((c) => c['type'] == 'EXPENSE')
                .toList();
            final incomeCategories = state.categories
                .where((c) => c['type'] == 'INCOME')
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(context, expenseCategories, 'EXPENSE'),
                _buildCategoryList(context, incomeCategories, 'INCOME'),
              ],
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state is ExpenseError ? state.message : "Unable to load categories",
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final type = _tabController.index == 0 ? 'EXPENSE' : 'INCOME';
          _showAddCategorySheet(context, type);
        },
        backgroundColor: const Color(0xFF1E3C72),
        label: const Text(
          "New Category",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<dynamic> categories,
    String type,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No $type categories found",
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap 'New Category' to add one",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            title: Text(
              category['name'],
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${category['isActive'] ? "Active" : "Disabled"}${category['account'] != null ? " • ${category['account']['name']}" : " • Global"}",
              style: TextStyle(
                color: category['isActive'] ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditCategorySheet(context, category),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _confirmDeleteCategory(context, category),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, dynamic category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text(
          "Are you sure you want to delete '${category['name']}'? This can only be done if the category has no transactions.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(
                DeleteCategoryRequested(category['id']),
              );
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context, String type) {
    final nameController = TextEditingController();
    int? selectedAccountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) => StatefulBuilder(
          builder: (context, setModalState) {
            final accounts = state is ExpenseDashboardLoaded
                ? state.accounts
                : [];
            return Padding(
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
                    "Add ${type == 'EXPENSE' ? 'Expense' : 'Income'} Category",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: "Link to Wallet (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Global Category"),
                    // Safety: Ensure the selected account exists in the list
                    initialValue:
                        accounts.any((a) => a['id'] == selectedAccountId)
                        ? selectedAccountId
                        : null,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Global Category"),
                      ),
                      ...accounts.map(
                        (a) => DropdownMenuItem<int?>(
                          value: a['id'],
                          child: Text(a['name']),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setModalState(() => selectedAccountId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      border: OutlineInputBorder(),
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
                            CreateCategoryRequested(
                              nameController.text,
                              type,
                              accountId: selectedAccountId,
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
                      child: const Text(
                        "Create Category",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditCategorySheet(BuildContext context, dynamic category) {
    final nameController = TextEditingController(text: category['name']);
    bool isActive = category['isActive'];
    int? selectedAccountId = category['accountId'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) => StatefulBuilder(
          builder: (context, setModalState) {
            final accounts = state is ExpenseDashboardLoaded
                ? state.accounts
                : [];
            return Padding(
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
                    "Edit Category",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: "Link to Wallet (Optional)",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Global Category"),
                    // Safety: Ensure the selected account exists in the list
                    initialValue:
                        accounts.any((a) => a['id'] == selectedAccountId)
                        ? selectedAccountId
                        : null,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("Global Category"),
                      ),
                      ...accounts.map(
                        (a) => DropdownMenuItem<int?>(
                          value: a['id'],
                          child: Text(a['name']),
                        ),
                      ),
                    ],
                    onChanged: (val) =>
                        setModalState(() => selectedAccountId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Active Status"),
                    value: isActive,
                    onChanged: (val) => setModalState(() => isActive = val),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          context.read<ExpenseBloc>().add(
                            UpdateCategoryRequested(
                              category['id'],
                              nameController.text,
                              category['type'],
                              isActive,
                              accountId: selectedAccountId,
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
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
