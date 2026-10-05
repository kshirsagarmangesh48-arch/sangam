import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/data/models/account_model.dart';
import '../../../wallet_details/data/models/category_model.dart';
import '../../../wallet_details/domain/repositories/wallet_details_repository.dart';

class AddCategoryDialog extends StatefulWidget {
  final int? initialAccountId;
  final void Function(SangamCategory category)? onCategoryCreated;

  const AddCategoryDialog({
    super.key,
    this.initialAccountId,
    this.onCategoryCreated,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'EXPENSE';
  int? _selectedAccountId;
  List<SangamAccount> _accounts = [];
  bool _isLoadingAccounts = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
    _loadAccounts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final repo = context.read<WalletDetailsRepository>();
      final accounts = await repo.getAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoadingAccounts = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingAccounts = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final colors = context.colors;
    final familyTheme = context.familyTheme;
    final name = _nameController.text.trim();

    try {
      final repo = context.read<WalletDetailsRepository>();
      final created = await repo.createCategory(
        name: name,
        type: _selectedType,
        accountId: _selectedAccountId,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Category "$name" created successfully',
            style: TextStyle(color: colors.onPrimary),
          ),
          backgroundColor: familyTheme.success,
        ),
      );

      widget.onCategoryCreated?.call(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('ApiException: ', ''),
            style: TextStyle(color: colors.onError),
          ),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.category_rounded,
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Category',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Create expense or income category',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Segmented Button
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'EXPENSE',
                        label: const Text('Expense'),
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          color: colors.error,
                          size: 18,
                        ),
                      ),
                      ButtonSegment(
                        value: 'INCOME',
                        label: const Text('Income'),
                        icon: Icon(
                          Icons.arrow_downward_rounded,
                          color: familyTheme.success,
                          size: 18,
                        ),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        setState(() => _selectedType = set.first);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Category Name
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Groceries, Electricity, Fuel',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter category name';
                    }
                    if (value.trim().length < 2) {
                      return 'Category name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Wallet / Account Association Dropdown
                _isLoadingAccounts
                    ? const SizedBox(
                        height: 50,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : DropdownButtonFormField<int?>(
                        key: ValueKey('wallet-$_selectedAccountId'),
                        initialValue: _selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Applicable Wallet',
                          prefixIcon: Icon(Icons.wallet_outlined, size: 20),
                          helperText:
                              'Global applies to all wallets; or link to a specific wallet.',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.public_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Global (All Wallets)'),
                              ],
                            ),
                          ),
                          ..._accounts.map(
                            (acc) => DropdownMenuItem<int?>(
                              value: acc.id,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(acc.name),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedAccountId = val),
                      ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add Category'),
        ),
      ],
    );
  }
}
