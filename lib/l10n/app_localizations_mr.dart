// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get recentTransactions => 'अलीकडील व्यवहार';

  @override
  String get income => 'उत्पन्न';

  @override
  String get expense => 'खर्च';

  @override
  String get deleteTransaction => 'व्यवहार हटवा';

  @override
  String get deleteTransactionConfirm =>
      'तुम्हाला नक्की हे व्यवहार हटवायचे आहे का?\nही क्रिया पूर्ववत करता येत नाही.';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get delete => 'हटवा';

  @override
  String get errorLoadingTransactions => 'व्यवहार लोड करताना त्रुटी';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get noTransactionsYet => 'अद्याप कोणतेही व्यवहार नाहीत';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get addTransaction => 'व्यवहार जोडा';

  @override
  String get newTransaction => 'नवीन व्यवहार';

  @override
  String get account => 'खाते';

  @override
  String get amount => 'रक्कम';

  @override
  String get enterAmount => 'रक्कम प्रविष्ट करा';

  @override
  String get invalidNumber => 'अवैध क्रमांक';

  @override
  String get description => 'वर्णन';

  @override
  String get enterDescription => 'वर्णन प्रविष्ट करा';

  @override
  String get saveTransaction => 'व्यवहार जतन करा';

  @override
  String get saving => 'जतन करत आहे...';

  @override
  String get pleaseSelectAccount => 'कृपया खाते निवडा';

  @override
  String get error => 'त्रुटी';

  @override
  String get home => 'घर';

  @override
  String get khorochi => 'खोरोची';

  @override
  String get hingane => 'हिंगणे';

  @override
  String get inventoryAndShopping => 'साठा आणि खरेदी';

  @override
  String get searchItems => 'वस्तू शोधा...';

  @override
  String get stock => 'साठा';

  @override
  String get shoppingList => 'खरेदी यादी';

  @override
  String get noItemsFound => 'कोणत्याही वस्तू आढळल्या नाहीत.';

  @override
  String get deleteItem => 'वस्तू हटवा';

  @override
  String deleteItemConfirm(String item) {
    return 'तुम्हाला नक्की \"$item\" साठ्यातून हटवायचे आहे का?';
  }

  @override
  String get lastBought => 'शेवटची खरेदी';

  @override
  String get never => 'कधीही नाही';

  @override
  String get finish => 'संपवा';

  @override
  String get complete => 'पूर्ण';

  @override
  String get addItem => 'वस्तू जोडा';

  @override
  String get smartGenerate => 'स्मार्ट जनरेट';

  @override
  String get shoppingListEmpty => 'खरेदी यादी रिकामी आहे.';

  @override
  String get buy => 'खरेदी';

  @override
  String get editShoppingItem => 'खरेदी वस्तू संपादित करा';

  @override
  String get itemName => 'वस्तूचे नाव';

  @override
  String get quantity => 'प्रमाण';

  @override
  String get unit => 'एकक';

  @override
  String get update => 'अद्यतनित करा';

  @override
  String get addToShoppingList => 'खरेदी यादीत जोडा';

  @override
  String get add => 'जोडा';

  @override
  String get addNewItem => 'नवीन वस्तू जोडा';

  @override
  String get category => 'श्रेणी';

  @override
  String get inventory => 'साठा';
}
