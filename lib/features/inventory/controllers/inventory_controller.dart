import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:sangam/core/constants/firebase_constants.dart';
import 'package:sangam/features/inventory/models/inventory_models.dart';
import 'package:sangam/core/utils/app_snackbar.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _pageSize = 20;

  final RxList<InventoryItem> items = <InventoryItem>[].obs;
  final ScrollController scrollController = ScrollController();

  Future<void> markAsFinished(InventoryItem item) async {
    await updateQuantity(item.id, 0);
    addToShoppingList(item.name, 1, item.unit); // Default add 1 to list
    AppSnackBar.info(
      'Finished',
      '${item.name} marked as finished & added to list',
    );
  }

  // Pagination State
  DocumentSnapshot? _lastDocument;
  var isLoading = false.obs;
  var hasMore = true.obs;
  var isLoadingMore = false.obs;

  final RxList<ShoppingListItem> currentShoppingList = <ShoppingListItem>[].obs;
  final RxString searchText = ''.obs;

  // For Shopping List local search
  List<ShoppingListItem> get filteredShoppingList {
    if (searchText.isEmpty) return currentShoppingList;
    return currentShoppingList
        .where(
          (item) =>
              item.name.toLowerCase().contains(searchText.value.toLowerCase()),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _fetchInitialPage();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });

    // Debounce search to avoid too many refreshes
    debounce(searchText, (val) {
      _fetchInitialPage();
    }, time: const Duration(milliseconds: 500));
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> _fetchInitialPage() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    items.clear();

    try {
      await _fetchData();
    } catch (e) {
      print("Error fetching initial page: $e");
      // AppSnackBar.error("Error", "Failed to load inventory");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      await _fetchData();
    } catch (e) {
      print("Error loading more: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _fetchData() async {
    Query query = _firestore
        .collection(FirebaseConstants.inventoryCollection)
        .orderBy('name')
        .limit(_pageSize);

    // Apply Search (Prefix)
    if (searchText.value.isNotEmpty) {
      final search = searchText.value;
      query = query
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThanOrEqualTo: '$search\uf8ff');
    }

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.length < _pageSize) {
      hasMore.value = false;
    }

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;

      final newItems = snapshot.docs
          .map((doc) => InventoryItem.fromDocument(doc))
          .toList();

      items.addAll(newItems);
    }
  }

  Future<void> updateQuantity(String id, double newQuantity) async {
    await _firestore
        .collection(FirebaseConstants.inventoryCollection)
        .doc(id)
        .update({'quantity': newQuantity});

    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      // Create copy with new quantity
      final updatedItem = items[index].copyWith(quantity: newQuantity);
      // Replace item in list to trigger Obx if observing specific item (though here observing list)
      items[index] = updatedItem;
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .doc(id)
          .delete();

      items.removeWhere((item) => item.id == id);
      AppSnackBar.success('Success', 'Item deleted from inventory');

      if (items.isEmpty) {
        _fetchInitialPage();
      }
    } catch (e) {
      AppSnackBar.error('Error', 'Failed to delete item: $e');
    }
  }

  Future<void> addInventoryItem(
    String name,
    double quantity,
    String unit,
    String category,
  ) async {
    final docRef = await _firestore
        .collection(FirebaseConstants.inventoryCollection)
        .add({
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'category': category,
          'lastPurchased': Timestamp.now(),
        });

    // Refresh list or add locally
    _fetchInitialPage();
  }

  // Analysis Logic: Generate list based on low stock or previous habits
  // Manual Add to Shopping List
  void addToShoppingList(String name, double quantity, String unit) {
    // Check if exists
    final existing = currentShoppingList.firstWhereOrNull(
      (i) => i.name.toLowerCase() == name.toLowerCase(),
    );

    if (existing != null) {
      existing.quantity += quantity;
      currentShoppingList.refresh();
      AppSnackBar.success('Updated', '$name quantity updated.');
    } else {
      currentShoppingList.add(
        ShoppingListItem(name: name, quantity: quantity, unit: unit),
      );
      AppSnackBar.success('Added', '$name added to shopping list.');
    }
  }

  void updateShoppingListItem(
    int index,
    String name,
    double quantity,
    String unit,
  ) {
    if (index >= 0 && index < currentShoppingList.length) {
      final item = currentShoppingList[index];
      item.name = name;
      item.quantity = quantity;
      item.unit = unit;
      currentShoppingList.refresh(); // Trigger Obx
      AppSnackBar.success('Updated', 'Item updated successfully');
    }
  }

  Future<void> generateShoppingList() async {
    currentShoppingList.clear();

    // Since we don't have the full list locally anymore, we query for low stock items
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .where('quantity', isLessThan: 2)
          .get();

      final lowStockItems = querySnapshot.docs
          .map((doc) => InventoryItem.fromDocument(doc))
          .toList();

      for (var item in lowStockItems) {
        currentShoppingList.add(
          ShoppingListItem(
            name: item.name,
            quantity: 2 - item.quantity, // Top up to 2
            unit: item.unit,
          ),
        );
      }

      AppSnackBar.info(
        'Analysis Complete',
        'Generated ${currentShoppingList.length} items to buy.',
      );
    } catch (e) {
      AppSnackBar.error('Error', 'Failed to generate list: $e');
    }
  }

  // Move bought items to inventory
  Future<void> completeShopping() async {
    final boughtItems = currentShoppingList.where((i) => i.isBought).toList();

    for (var shopItem in boughtItems) {
      // Find matching inventory item (Query by name)
      // Note: This is an N+1 query loop, but safe for small shopping lists.
      final query = await _firestore
          .collection(FirebaseConstants.inventoryCollection)
          .where('name', isEqualTo: shopItem.name)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final currentQty = (doc.data()['quantity'] as num).toDouble();
        await updateQuantity(doc.id, currentQty + shopItem.quantity);
      } else {
        // Create new
        await _firestore.collection(FirebaseConstants.inventoryCollection).add({
          'name': shopItem.name,
          'quantity': shopItem.quantity, // Bought quantity
          'unit': shopItem.unit,
          'category': 'General', // Default
          'lastPurchased': Timestamp.now(),
        });
      }
    }
    _fetchInitialPage(); // Refresh inventory

    currentShoppingList.removeWhere((i) => i.isBought);
    AppSnackBar.success('Shopping Complete', 'Inventory updated successfully!');
  }
}
