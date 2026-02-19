import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sangam/features/expense/controllers/finance_controller.dart';
import 'package:sangam/features/expense/models/transaction_model.dart';
import 'package:sangam/core/utils/app_snackbar.dart';
import 'package:sangam/l10n/app_localizations.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  String? _selectedCategory = 'general'; // Default to Home
  bool _isSaving = false;
  // String? _selectedWalletId; // Removed in favor of category selection

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() => _isSaving = true);

      try {
        // Use the controller specific to the selected category to update its state
        final targetController = Get.find<FinanceController>(
          tag: _selectedCategory,
        );

        await targetController.addTransaction(
          amount: double.parse(_amountController.text),
          description: _descController.text.trim(),
          type: _selectedType,
          participants: [],
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    } else if (_selectedCategory == null) {
      AppSnackBar.error(
        AppLocalizations.of(context)!.error,
        AppLocalizations.of(context)!.pleaseSelectAccount,
      );
    }
  }

  Widget _buildAccountChip(String label, String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.addTransaction)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.newTransaction,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Type Toggle
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text(AppLocalizations.of(context)!.expense),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text(AppLocalizations.of(context)!.income),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        setState(() {
                          _selectedType = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.standard,
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Account Selection
                    Text(AppLocalizations.of(context)!.account),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildAccountChip(
                          AppLocalizations.of(context)!.home,
                          'general',
                          Icons.home,
                        ),
                        _buildAccountChip(
                          AppLocalizations.of(context)!.khorochi,
                          'khorochi',
                          Icons.agriculture,
                        ),
                        _buildAccountChip(
                          AppLocalizations.of(context)!.hingane,
                          'hingane',
                          Icons.landscape,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.amount,
                        prefixText: '₹ ',
                        prefixIcon: const Icon(Icons.currency_rupee),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return AppLocalizations.of(context)!.enterAmount;
                        if (double.tryParse(value) == null)
                          return AppLocalizations.of(context)!.invalidNumber;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return AppLocalizations.of(context)!.enterDescription;
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              _selectedType == TransactionType.income
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          _isSaving
                              ? AppLocalizations.of(context)!.saving
                              : AppLocalizations.of(context)!.saveTransaction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
