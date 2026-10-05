import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../dashboard/data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/repositories/wallet_details_repository.dart';
import '../bloc/wallet_details_bloc.dart';
import '../bloc/wallet_details_event.dart';

class AddTransactionDialog extends StatefulWidget {
  final SangamAccount account;
  final SangamUserEntity user;

  const AddTransactionDialog({
    super.key,
    required this.account,
    required this.user,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'EXPENSE';
  DateTime _selectedDate = DateTime.now();

  int? _selectedCategoryId;
  int? _selectedSpentById;
  int? _selectedPaidById;

  List<SangamCategory> _allCategories = [];
  List<SangamMemberRef> _members = [];
  bool _isLoadingDropdowns = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = context.read<WalletDetailsRepository>();
      final results = await Future.wait([
        repo.getCategories(),
        repo.getMembers(),
      ]);

      if (!mounted) return;

      setState(() {
        _allCategories = results[0] as List<SangamCategory>;
        _members = results[1] as List<SangamMemberRef>;

        // Set default spentBy and paidBy to logged in user if match found
        final currentUserMember = _members.cast<SangamMemberRef?>().firstWhere(
              (m) =>
                  m != null &&
                  (m.id == widget.user.id ||
                      m.name.toLowerCase() == widget.user.name.toLowerCase()),
              orElse: () => _members.isNotEmpty ? _members.first : null,
            );

        if (currentUserMember != null) {
          _selectedSpentById = currentUserMember.id;
          _selectedPaidById = currentUserMember.id;
        }

        // Auto select first category matching initial type and wallet
        final matchingCategories = _getFilteredCategories(_selectedType);
        if (matchingCategories.isNotEmpty) {
          _selectedCategoryId = matchingCategories.first.id;
        }

        _isLoadingDropdowns = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingDropdowns = false);
      }
    }
  }

  List<SangamCategory> _getFilteredCategories(String type) {
    return _allCategories
        .where((c) =>
            c.type == type &&
            c.isActive &&
            (c.accountId == null || c.accountId == widget.account.id))
        .toList();
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _selectedType = newType;
      final matching = _getFilteredCategories(newType);
      _selectedCategoryId = matching.isNotEmpty ? matching.first.id : null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    context.read<WalletDetailsBloc>().add(
          CreateTransactionRequested(
            amount: amount,
            type: _selectedType,
            accountId: widget.account.id,
            categoryId: _selectedCategoryId,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            date: _selectedDate,
            spentById: _selectedSpentById,
            paidById: _selectedPaidById,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final familyTheme = context.familyTheme;

    final filteredCategories = _getFilteredCategories(_selectedType);

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
              Icons.add_card_rounded,
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
                  'Add Transaction',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.account.name,
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: _isLoadingDropdowns
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
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
                            if (set.isNotEmpty) _onTypeChanged(set.first);
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'EXPENSE'
                              ? colors.error
                              : familyTheme.success,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          prefixStyle: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'EXPENSE'
                                ? colors.error
                                : familyTheme.success,
                          ),
                          hintText: '0.00',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid amount greater than 0';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Category Dropdown
                      DropdownButtonFormField<int>(
                        key: ValueKey('cat-$_selectedType-$_selectedCategoryId'),
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('General / Other'),
                          ),
                          ...filteredCategories.map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedCategoryId = val),
                      ),

                      const SizedBox(height: 14),

                      // Date Picker Field
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Transaction Date',
                            prefixIcon:
                                Icon(Icons.calendar_today_rounded, size: 20),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: text.bodyMedium,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Spent By Member (Optional)
                      DropdownButtonFormField<int>(
                        key: ValueKey('spent-$_selectedSpentById'),
                        initialValue: _selectedSpentById,
                        decoration: const InputDecoration(
                          labelText: 'Spent By (Family Member)',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Select Member'),
                          ),
                          ..._members.map(
                            (m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedSpentById = val),
                      ),

                      const SizedBox(height: 14),

                      // Paid By Member (Optional)
                      DropdownButtonFormField<int>(
                        key: ValueKey('paid-$_selectedPaidById'),
                        initialValue: _selectedPaidById,
                        decoration: const InputDecoration(
                          labelText: 'Paid By (Disbursed From)',
                          prefixIcon: Icon(Icons.payments_outlined, size: 20),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('Select Member'),
                          ),
                          ..._members.map(
                            (m) => DropdownMenuItem<int>(
                              value: m.id,
                              child: Text(m.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedPaidById = val),
                      ),

                      const SizedBox(height: 14),

                      // Description / Note Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Note (Optional)',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                          hintText: 'e.g. Weekly grocery provisions',
                        ),
                        maxLines: 2,
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
          onPressed: _isSubmitting || _isLoadingDropdowns ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add Transaction'),
        ),
      ],
    );
  }
}
