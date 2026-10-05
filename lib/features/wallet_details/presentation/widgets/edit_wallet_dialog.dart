import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dashboard/data/models/account_model.dart';
import '../bloc/wallet_details_bloc.dart';
import '../bloc/wallet_details_event.dart';

class EditWalletDialog extends StatefulWidget {
  final SangamAccount account;

  const EditWalletDialog({super.key, required this.account});

  @override
  State<EditWalletDialog> createState() => _EditWalletDialogState();
}

class _EditWalletDialogState extends State<EditWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _descController =
        TextEditingController(text: widget.account.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<WalletDetailsBloc>().add(
            UpdateWalletInfoRequested(
              id: widget.account.id,
              name: _nameController.text.trim(),
              description: _descController.text.trim().isNotEmpty
                  ? _descController.text.trim()
                  : null,
            ),
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Wallet'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
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
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
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
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
