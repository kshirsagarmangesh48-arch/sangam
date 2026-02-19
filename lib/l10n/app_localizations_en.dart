// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get deleteTransaction => 'Delete Transaction';

  @override
  String get deleteTransactionConfirm =>
      'Are you sure you want to delete this transaction?\nThis action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get retry => 'Retry';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get account => 'Account';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get saving => 'Saving...';

  @override
  String get pleaseSelectAccount => 'Please select an account';

  @override
  String get error => 'Error';

  @override
  String get home => 'Home';

  @override
  String get khorochi => 'Khorochi';

  @override
  String get hingane => 'Hingane';

  @override
  String get inventoryAndShopping => 'Inventory & Shopping';

  @override
  String get searchItems => 'Search items...';

  @override
  String get stock => 'Stock';

  @override
  String get shoppingList => 'Shopping List';

  @override
  String get noItemsFound => 'No items found. Add some!';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String deleteItemConfirm(String item) {
    return 'Are you sure you want to delete \"$item\" from inventory?';
  }

  @override
  String get lastBought => 'Last bought';

  @override
  String get never => 'Never';

  @override
  String get finish => 'Finish';

  @override
  String get complete => 'Complete';

  @override
  String get addItem => 'Add Item';

  @override
  String get smartGenerate => 'Smart Generate';

  @override
  String get shoppingListEmpty => 'Shopping list is empty.';

  @override
  String get buy => 'Buy';

  @override
  String get editShoppingItem => 'Edit Shopping Item';

  @override
  String get itemName => 'Item Name';

  @override
  String get quantity => 'Quantity';

  @override
  String get unit => 'Unit';

  @override
  String get update => 'Update';

  @override
  String get addToShoppingList => 'Add to Shopping List';

  @override
  String get add => 'Add';

  @override
  String get addNewItem => 'Add New Item';

  @override
  String get category => 'Category';

  @override
  String get inventory => 'Inventory';
}
