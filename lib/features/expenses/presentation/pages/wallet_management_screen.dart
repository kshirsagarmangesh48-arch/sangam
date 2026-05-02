import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sangam_expense/features/expenses/presentation/bloc/expense_bloc.dart';

class WalletManagementScreen extends StatelessWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Manage Wallets", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseDashboardLoaded) {
            final accounts = state.accounts;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final wallet = accounts[index];
                return _buildWalletCard(context, wallet);
              },
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state is ExpenseError ? state.message : "Unable to load wallets",
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
        onPressed: () => _showAddWalletSheet(context),
        backgroundColor: const Color(0xFF1E3C72),
        label: const Text("New Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, dynamic wallet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3C72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Color(0xFF1E3C72)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet['name'], style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                if (wallet['description'] != null && wallet['description'].isNotEmpty)
                  Text(wallet['description'], style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${wallet['balance']}",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E3C72)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showEditWalletSheet(context, wallet),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddWalletSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create New Wallet", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Wallet Name", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<ExpenseBloc>().add(CreateWalletRequested(nameController.text, descController.text));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Create Wallet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showEditWalletSheet(BuildContext context, dynamic wallet) {
    final nameController = TextEditingController(text: wallet['name']);
    final descController = TextEditingController(text: wallet['description'] ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit Wallet", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Wallet Name", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    context.read<ExpenseBloc>().add(UpdateWalletRequested(
                      wallet['id'],
                      nameController.text,
                      descController.text,
                    ));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
