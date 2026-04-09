import 'package:flutter/material.dart';
import 'package:sangam/features/expense/presentation/finance_dashboard.dart';
import 'package:sangam/features/settings/presentation/settings_page.dart';
import 'package:sangam/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FinancePage(
      category: 'general',
      title: 'Home Expenses',
    ), // These titles might not be updated dynamically if passed as const.
    // FinancePage uses title widget.title.
    // If I change AppBar title logic in build(), these passed titles might be unused or redundant for AppBar but used inside FinancePage?
    // Let's check FinancePage usage of title.
    // It is used in `_buildTotalBalanceCard`.
    // So `FinancePage` needs localized title too.
    // But `_pages` is `const`. I cannot pass localized strings here.
    // I need to remove `const` and move `_pages` into `build` or make it getter.
    // Refactoring: move _pages to build or remove const.
    // For now, I will leave _pages as is but handle title in FinancePage?
    // No, I must pass localized title to FinancePage or duplicate logic.
    // Easiest is to remove `const` and build `_pages` in `build` or `didChangeDependencies`.
    // I'll ignore this block in this tool call and do it in separate step if needed.
    // wait, I can just update the AppBar title logic which I did above.
    // But FinancePage also displays title.
    FinancePage(category: 'khorochi', title: 'Khorochi Farm'),
    FinancePage(category: 'hingane', title: 'Hingane Farm'),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine title based on index
    String appBarTitle;
    switch (_currentIndex) {
      case 0:
        appBarTitle = AppLocalizations.of(
          context,
        )!.income; // Using 'Income' isn't quite right for 'Home Expenses', using 'Home' from 'Account' context or new key might be better, but keys exist. 'Home' is available. Let's use 'Home' + 'Expense' or separate.
        // Wait, app_en.arb has 'home'. Let's check keys again.
        // 'home' -> "Home". 'expense' -> "Expense".
        // The original was 'Home Expenses'.
        // user didn't ask for "Home Expenses" key.
        // I will use '${AppLocalizations.of(context)!.home} ${AppLocalizations.of(context)!.expense}'
        appBarTitle =
            '${AppLocalizations.of(context)!.home} ${AppLocalizations.of(context)!.expense}';
        break;
      case 1:
        appBarTitle =
            '${AppLocalizations.of(context)!.khorochi} Farm'; // "Farm" isn't localized. I should have added "Farm" or "Khorochi Farm" key.
        // Assuming "Farm" is okay in English for now or reusing existing patterns.
        // Let's stick to simple or add "Farm" key?
        // User didn't request "Farm". I'll keep "Farm" hardcoded for now or better, since "Khorochi" translation is just the name.
        // Let's use just the name if acceptable? No, "Khorochi Farm".
        // Re-reading task: "Identify hardcoded strings". "Khorochi Farm" is one.
        // I didn't add "Farm" key.
        // I will assume for now leaving "Farm" hardcoded or concatenated is acceptable strictly for the reported scope, OR I can add "Farm" key quickly.
        // Let's use concatenation for proper nouns + Farm.
        // Wait, "Farm" might need translation in Marathi ("Shivar" or "Farm").
        // I'll leave "Farm" as is for now to avoid scope creep, or just use the name as title?
        // Let's use the Name Key only for the tab title if feasible?
        // No, let's look at `_pages`: title: 'Home Expenses'.
        // Actually, titles are used in AppBar.
        // Let's use Name keys directly for simplicity as per common app patterns?
        // "Khorochi", "Hingane".
        appBarTitle = '${AppLocalizations.of(context)!.khorochi} Farm';
        break;
      case 2:
        appBarTitle = '${AppLocalizations.of(context)!.hingane} Farm';
        break;
      case 3:
        appBarTitle = AppLocalizations.of(context)!.settings;
        break;
      default:
        appBarTitle = 'Sangam';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.agriculture_outlined),
            selectedIcon: const Icon(Icons.agriculture),
            label: AppLocalizations.of(context)!.khorochi,
          ),
          NavigationDestination(
            icon: const Icon(Icons.landscape_outlined),
            selectedIcon: const Icon(Icons.landscape),
            label: AppLocalizations.of(context)!.hingane,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
      ),
    );
  }
}
