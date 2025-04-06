import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyData {
  final int month;
  final double income;
  final double expenses;

  MonthlyData(this.month, this.income, this.expenses);
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _currentUsername = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('username') ?? '';
    });
  }

  Future<Map<String, dynamic>> _fetchAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('username') ?? '';

    if (currentUsername.isEmpty) {
      return {
        'income': 0.0,
        'expenses': 0.0,
        'savings': 0.0,
        'categories': [],
      };
    }

    // Fetch all transactions for the user
    final sentTransactions = await _firestore
        .collection('transactions')
        .where('From', isEqualTo: currentUsername)
        .get();

    final receivedTransactions = await _firestore
        .collection('transactions')
        .where('To', isEqualTo: currentUsername)
        .get();

    // Calculate totals
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categorySpending = {};

    // Process received transactions (income)
    for (var doc in receivedTransactions.docs) {
      final transaction = doc.data();
      final amount = double.parse(transaction['Amount'].toString());
      totalIncome += amount;
    }

    // Process sent transactions (expenses)
    for (var doc in sentTransactions.docs) {
      final transaction = doc.data();
      final amount = double.parse(transaction['Amount'].toString());
      totalExpenses += amount;

      // Track spending by category
      final category = transaction['Category'] ?? 'Uncategorized';
      categorySpending[category] = (categorySpending[category] ?? 0) + amount;
    }

    // Calculate savings
    final savings = totalIncome - totalExpenses;

    // Convert category spending to list format
    final categories = categorySpending.entries.map((entry) {
      final percentage = (entry.value / totalExpenses) * 100;
      return {
        'name': entry.key,
        'amount': entry.value,
        'percentage': percentage,
      };
    }).toList();

    // Sort categories by amount
    categories.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    return {
      'income': totalIncome,
      'expenses': totalExpenses,
      'savings': savings,
      'categories': categories,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchAnalyticsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final data = snapshot.data ??
                      {
                        'income': 0.0,
                        'expenses': 0.0,
                        'savings': 0.0,
                        'categories': [],
                      };

                  return Column(
                    children: [
                      _buildOverviewCard(data),
                      const SizedBox(height: 20),
                      _buildCategoriesSection(
                          data['categories'] as List<dynamic>),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1624), Color(0xFF162440)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildStatCard(
                  'Income',
                  '₹${data['income'].toStringAsFixed(2)}',
                  const Color(0xFF4CD964),
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Expenses',
                  '₹${data['expenses'].toStringAsFixed(2)}',
                  const Color(0xFFFF3B30),
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Savings',
                  '₹${data['savings'].toStringAsFixed(2)}',
                  const Color(0xFFD4AF37),
                  Icons.savings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A94A6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(List<dynamic> categories) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No spending data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...categories.map((category) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${(category['amount'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (category['percentage'] as double) / 100,
                  backgroundColor: const Color(0xFF0A0E17),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(const Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(category['percentage'] as double).toStringAsFixed(1)}% of total expenses',
                  style: const TextStyle(
                    color: Color(0xFF8A94A6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isSent = transaction['From'] == _currentUsername;
    final amount = transaction['Amount'] as double;
    final date = (transaction['Date'] as Timestamp).toDate();
    final formattedDate = DateFormat('MMM dd, yyyy').format(date);
    final formattedTime = DateFormat('hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isSent
                      ? 'To: ${transaction['To']}'
                      : 'From: ${transaction['From']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isSent ? Colors.red : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 14,
                ),
              ),
              Text(
                formattedTime,
                style: const TextStyle(
                  color: Color(0xFF8A94A6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
