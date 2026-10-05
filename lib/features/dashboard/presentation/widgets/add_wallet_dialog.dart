import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';

class AddWalletDialog extends StatefulWidget {
  const AddWalletDialog({super.key});

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.0');

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
      context.read<DashboardBloc>().add(
            CreateWalletRequested(
              name: _nameController.text.trim(),
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
              initialBalance: balance,
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Wallet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet / Bank Name',
                  hintText: 'e.g. HDFC Bank, Main Cash',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a wallet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Primary family account',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Opening Balance (₹)',
                  hintText: '0.0',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    if (double.tryParse(val) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create Wallet'),
        ),
      ],
    );
  }
}
