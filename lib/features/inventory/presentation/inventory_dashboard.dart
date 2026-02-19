import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:sangam/features/inventory/controllers/inventory_controller.dart';
import 'package:sangam/features/inventory/models/inventory_models.dart';
import 'package:sangam/l10n/app_localizations.dart';

class InventoryDashboard extends StatelessWidget {
  const InventoryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InventoryController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.inventoryAndShopping),
          toolbarHeight: 0, // Collapsed
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              140,
            ), // Increased to prevent overflow
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (val) => controller.searchText.value = val,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchItems,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(
                      text: AppLocalizations.of(context)!.stock,
                      icon: const Icon(Icons.shelves),
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.shoppingList,
                      icon: const Icon(Icons.shopping_cart),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // STOCK TAB
            Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddInventoryDialog(context, controller),
                child: const Icon(Icons.add),
              ),
              body: Obx(() {
                if (controller.isLoading.value && controller.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.items.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noItemsFound),
                  );
                }

                return ListView.builder(
                  controller: controller.scrollController,
                  itemCount:
                      controller.items.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = controller.items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: 0,
                      color: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onLongPress: () {
                          // ... dialog
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).bottomSheetTheme.backgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.deleteItem,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteItemConfirm(item.name),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          controller.deleteInventoryItem(
                                            item.id,
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.errorContainer,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.delete,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.category} • ${AppLocalizations.of(context)!.lastBought}: ${item.lastPurchased != null ? item.lastPurchased.toString().split(' ')[0] : AppLocalizations.of(context)!.never}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              if (item.quantity > 0) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 32,
                                  child: FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                    onPressed: () =>
                                        controller.markAsFinished(item),
                                    child: const Text(
                                      'Finish',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // SHOPPING LIST TAB
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                onPressed: controller.completeShopping,
                label: Text(AppLocalizations.of(context)!.complete),
                icon: const Icon(Icons.check_circle),
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showAddShoppingItemDialog(context, controller),
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.addItem),
                        ),
                        ElevatedButton.icon(
                          onPressed: controller.generateShoppingList,
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(
                            AppLocalizations.of(context)!.smartGenerate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.currentShoppingList.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.shoppingListEmpty,
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: controller.filteredShoppingList.length,
                        itemBuilder: (context, index) {
                          final item = controller.filteredShoppingList[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            elevation: 0,
                            color: Theme.of(context).cardTheme.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Checkbox(
                                value: item.isBought,
                                onChanged: (val) {
                                  item.isBought = val ?? false;
                                  controller.currentShoppingList.refresh();
                                },
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                '${AppLocalizations.of(context)!.buy}: ${item.quantity.toStringAsFixed(1).replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "")} ${item.unit}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => controller.currentShoppingList
                                    .removeAt(index),
                              ),
                              onTap: () => _showEditShoppingItemDialog(
                                context,
                                controller,
                                index,
                                item,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditShoppingItemDialog(
    BuildContext context,
    InventoryController controller,
    int index,
    ShoppingListItem item,
  ) {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final unitCtrl = TextEditingController(text: item.unit);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.editShoppingItem,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.itemName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.quantity,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                      controller.updateShoppingListItem(
                        index,
                        nameCtrl.text.trim(),
                        qty,
                        unitCtrl.text.trim(),
                      );
                      context.pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.update),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddShoppingItemDialog(
    BuildContext context,
    InventoryController controller,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController(text: '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.addToShoppingList,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.itemName,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.quantity,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.unit,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                      controller.addToShoppingList(
                        nameCtrl.text.trim(),
                        qty,
                        unitCtrl.text.trim(),
                      );
                      context.pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInventoryDialog(
    BuildContext context,
    InventoryController controller,
  ) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final unitCtrl = TextEditingController(text: '');
    final catCtrl = TextEditingController(text: 'General');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.addNewItem,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.itemName,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.quantity,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: InputDecoration(
                      labelText:
                          '${AppLocalizations.of(context)!.unit} (pcs, kg)', // "pcs, kg" not localized, but maybe acceptable for now or create generic unit hint
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: catCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.category,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                      controller.addInventoryItem(
                        nameCtrl.text.trim(),
                        qty,
                        unitCtrl.text.trim(),
                        catCtrl.text.trim(),
                      );
                      context.pop();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
