import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];

  final Map<String, Budget> _budgets = {
    'Ăn uống': Budget(category: 'Ăn uống', limit: 2000000),
    'Di chuyển': Budget(category: 'Di chuyển', limit: 500000),
    'Mua sắm': Budget(category: 'Mua sắm', limit: 1000000),
  };

  TransactionProvider() {
    _loadData();
  }

  List<Transaction> get transactions {
    var sortedList = [..._transactions];
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }

  Map<String, Budget> get budgets => _budgets;

  // Logic tính toán cảnh báo ngân sách
  List<String> get budgetWarnings {
    List<String> warnings = [];
    _budgets.forEach((category, budget) {
      if (budget.limit > 0) {
        double percentage = budget.spent / budget.limit;
        if (percentage >= 1.0) {
          warnings.add("Danh mục '$category' đã vượt hạn mức!");
        } else if (percentage >= 0.8) {
          warnings.add("Danh mục '$category' sắp chạm hạn mức!");
        }
      }
    });
    return warnings;
  }

  double get totalBalance {
    double total = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  Map<String, double> get expenseByCategory {
    Map<String, double> data = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  Map<String, double> get incomeByCategory {
    Map<String, double> data = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.income) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount;
      }
    }
    return data;
  }

  void updateBudgetLimit(String category, double newLimit) {
    if (_budgets.containsKey(category)) {
      _budgets[category]!.limit = newLimit;
    } else {
      _budgets[category] = Budget(category: category, limit: newLimit);
    }
    notifyListeners();
    _saveBudgets();
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, double> limitsMap = {};
    _budgets.forEach((key, value) => limitsMap[key] = value.limit);
    prefs.setString('budgets_data', json.encode(limitsMap));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? budgetsString = prefs.getString('budgets_data');
    if (budgetsString != null) {
      final Map<String, dynamic> decoded = json.decode(budgetsString);
      decoded.forEach((key, value) {
        if (_budgets.containsKey(key)) {
          _budgets[key]!.limit = (value as num).toDouble();
        } else {
          _budgets[key] = Budget(category: key, limit: (value as num).toDouble());
        }
      });
    }

    final String? txString = prefs.getString('transactions_data');
    if (txString != null) {
      final List<dynamic> decodedData = json.decode(txString);
      _transactions = decodedData.map((item) => Transaction.fromJson(item)).toList();
    }
    _refreshSpentAmount();
    notifyListeners();
  }

  void _refreshSpentAmount() {
    for (var b in _budgets.values) b.spent = 0;
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense && _budgets.containsKey(tx.category)) {
        _budgets[tx.category]!.spent += tx.amount;
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_transactions.map((tx) => tx.toJson()).toList());
    prefs.setString('transactions_data', encoded);
  }

  void addTransaction(Transaction tx) {
    _transactions.add(tx);
    _refreshSpentAmount();
    notifyListeners();
    _saveData();
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    _refreshSpentAmount();
    notifyListeners();
    _saveData();
  }

  void updateTransaction(String id, Transaction newTx) {
    final index = _transactions.indexWhere((tx) => tx.id == id);
    if (index != -1) {
      _transactions[index] = newTx;
      _refreshSpentAmount();
      notifyListeners();
      _saveData();
    }
  }
}