import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sangam/core/constants/firebase_constants.dart';
import 'package:sangam/features/auth/controllers/auth_controller.dart';
import 'package:sangam/features/expense/models/transaction_model.dart';
import 'package:sangam/core/utils/app_snackbar.dart';
import 'package:sangam/core/constants/global_keys.dart';
import 'package:sangam/core/services/notification_service.dart';

class FinanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  static const _pageSize = 20;

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final ScrollController scrollController = ScrollController();

  // Pagination State
  DocumentSnapshot? _lastDocument;
  var isLoading = false.obs;
  var hasMore = true.obs;
  var isLoadingMore = false.obs;
  var errorMessage = ''.obs;

  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpense = 0.0.obs;

  // Subscription for totals
  StreamSubscription<DocumentSnapshot>? _totalsSubscription;

  // Selected Category (Provided via tag or defaulted)
  final RxString selectedCategory = 'general'.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen for category changes
    ever(selectedCategory, (category) {
      _bindTotals(category);
      fetchTransactions();
      _syncRemoteBalance(category); // Ensure this category is synced
    });

    // Initial manual bind
    _bindTotals('general'); // Will be updated if tag sets selectedCategory
    _syncRemoteBalance('general');

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  // Syncs the calculated balance using the transaction category
  Future<void> _syncRemoteBalance(String category) async {
    final currentUser = _authController.firebaseUser.value;
    if (currentUser == null) return;

    final baseQuery = _firestore
        .collection(FirebaseConstants.expensesCollection)
        .where('category', isEqualTo: category);

    try {
      // Calculate Income
      final incomeQuery = baseQuery.where(
        'type',
        isEqualTo: TransactionType.income.name,
      );
      final incomeAgg = await incomeQuery.aggregate(sum('amount')).get();
      final income = incomeAgg.getSum('amount') ?? 0.0;

      // Calculate Expense
      final expenseQuery = baseQuery.where(
        'type',
        isEqualTo: TransactionType.expense.name,
      );
      final expenseAgg = await expenseQuery.aggregate(sum('amount')).get();
      final expense = expenseAgg.getSum('amount') ?? 0.0;

      // Update Family Document for this category
      await _firestore
          .collection(FirebaseConstants.familyCollection)
          .doc(category) // e.g. 'general', 'khorochi', 'hingane'
          .set({
            'totalIncome': income,
            'totalExpense': expense,
            'lastSynced': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Sync Error: $e');
    }
  }

  void _bindTotals(String category) {
    _totalsSubscription?.cancel();
    // Listen to the family document for this category
    _totalsSubscription = _firestore
        .collection(FirebaseConstants.familyCollection)
        .doc(category)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null) {
              totalIncome.value =
                  (data['totalIncome'] as num?)?.toDouble() ?? 0.0;
              totalExpense.value =
                  (data['totalExpense'] as num?)?.toDouble() ?? 0.0;
            }
          } else {
            // If doc doesn't exist yet, reset to 0
            totalIncome.value = 0.0;
            totalExpense.value = 0.0;

            // Try explicit fetch if missing?
            _syncRemoteBalance(category);
          }
        });
  }

  Future<void> fetchTransactions() async {
    isLoading.value = true;
    hasMore.value = true;
    errorMessage.value = '';
    _lastDocument = null;
    transactions.clear();

    if (_authController.firebaseUser.value == null) {
      errorMessage.value = 'User not logged in';
      isLoading.value = false;
      return;
    }

    try {
      await _fetchData();
    } catch (e) {
      print("Error fetching initial page: $e");
      errorMessage.value = e.toString();
      AppSnackBar.error("Error", "Failed to load transactions: $e");
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
        .collection(FirebaseConstants.expensesCollection)
        .orderBy('date', descending: true); // Basic order

    // Simple category filtering
    // Since we use tagged controllers, selectedCategory.value IS the fixed account ID.
    query = query.where('category', isEqualTo: selectedCategory.value);

    query = query.limit(_pageSize);

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
          .map((doc) => TransactionModel.fromDocument(doc))
          .toList();

      transactions.addAll(newItems);
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String description,
    required TransactionType type,
    required List<String> participants,
    String? paidByName,
  }) async {
    isLoading.value = true;
    try {
      final currentUser = _authController.firebaseUser.value;
      if (currentUser == null) throw Exception('User not logged in');

      // Run as a Transaction to ensure Balance + Expense creation are atomic
      await _firestore.runTransaction((transaction) async {
        // 1. Get Family Ref (Category specific)
        final String category = selectedCategory.value;

        final familyRef = _firestore
            .collection(FirebaseConstants.familyCollection)
            .doc(category);

        final familyDoc = await transaction.get(familyRef);

        double currentIncome = 0;
        double currentExpense = 0;

        if (familyDoc.exists) {
          currentIncome =
              (familyDoc.data()?['totalIncome'] as num?)?.toDouble() ?? 0.0;
          currentExpense =
              (familyDoc.data()?['totalExpense'] as num?)?.toDouble() ?? 0.0;
        }

        // 3. Calculate new totals
        if (type == TransactionType.income) {
          currentIncome += amount;
        } else {
          currentExpense += amount;
        }

        // 4. Create new Expense Document Ref
        final newExpenseRef = _firestore
            .collection(FirebaseConstants.expensesCollection)
            .doc();

        // 5. Writes
        // Add Expense
        transaction.set(newExpenseRef, {
          'amount': amount,
          'description': description,
          'date': Timestamp.now(),
          'paidBy': currentUser.uid,
          'paidByName': (paidByName != null && paidByName.trim().isNotEmpty) ? paidByName.trim() : (currentUser.email ?? '-'),
          'participants': participants,
          'type': type.name,
          'category': category,
        });

        // Update Family Balance
        transaction.set(familyRef, {
          'totalIncome': currentIncome,
          'totalExpense': currentExpense,
          'lastSynced': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      AppSnackBar.success(
        'Success',
        '${type.name.capitalizeFirst} added successfully',
      );
      rootNavigatorKey.currentState?.pop();
      fetchTransactions(); // Refresh list to show new item

      // Fire off OneSignal push notification
      NotificationService.sendTransactionNotification(
        amount: amount,
        description: description,
        type: type.name,
        paidByName: (paidByName != null && paidByName.trim().isNotEmpty) ? paidByName.trim() : (currentUser.email ?? '-'),
      );
    } catch (e) {
      AppSnackBar.error('Error', 'Failed to add transaction: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    try {
      // Run as a Transaction to ensure Balance Reversal + Deletion are atomic
      await _firestore.runTransaction((firebaseTransaction) async {
        // 1. Get Family Ref
        String category = transaction.category.isNotEmpty
            ? transaction.category
            : 'general';

        final familyRef = _firestore
            .collection(FirebaseConstants.familyCollection)
            .doc(category);

        // 2. Read current totals
        double currentIncome = 0;
        double currentExpense = 0;

        final familyDoc = await firebaseTransaction.get(familyRef);
        if (familyDoc.exists) {
          currentIncome =
              (familyDoc.data()?['totalIncome'] as num?)?.toDouble() ?? 0.0;
          currentExpense =
              (familyDoc.data()?['totalExpense'] as num?)?.toDouble() ?? 0.0;
        }

        // 3. Calculate reversed totals
        if (transaction.type == TransactionType.income) {
          currentIncome -= transaction.amount;
        } else {
          currentExpense -= transaction.amount;
        }

        // 4. Get Expense Ref
        final expenseRef = _firestore
            .collection(FirebaseConstants.expensesCollection)
            .doc(transaction.id);

        // 5. Writes
        firebaseTransaction.delete(expenseRef);

        firebaseTransaction.set(familyRef, {
          'totalIncome': currentIncome,
          'totalExpense': currentExpense,
          'lastSynced': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      AppSnackBar.success('Success', 'Transaction deleted successfully');

      // Remove locally to avoid full refresh if possible, or just refresh
      transactions.removeWhere((t) => t.id == transaction.id);

      // No need to fetchTransactions() if we remove locally,
      // but to be safe and consistent with pagination:
      if (transactions.isEmpty) {
        fetchTransactions();
      }
    } catch (e) {
      AppSnackBar.error('Error', 'Failed to delete transaction: $e');
    }
  }

  double get netBalance => totalIncome.value - totalExpense.value;

  @override
  void onClose() {
    _totalsSubscription?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
