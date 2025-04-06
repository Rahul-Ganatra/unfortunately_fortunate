import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_page.dart';
import 'package:rxdart/rxdart.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('username') ?? '';

    if (currentUsername.isEmpty) {
      return [];
    }

    // Fetch all transactions for the user
    final sentTransactions = await _firestore
        .collection('transactions')
        .where('From', isEqualTo: currentUsername)
        .orderBy('Date', descending: true)
        .get();

    final receivedTransactions = await _firestore
        .collection('transactions')
        .where('To', isEqualTo: currentUsername)
        .orderBy('Date', descending: true)
        .get();

    // Combine and sort all transactions
    final allTransactions = [
      ...sentTransactions.docs.map((doc) => {
            ...doc.data(),
            'isSent': true,
          }),
      ...receivedTransactions.docs.map((doc) => {
            ...doc.data(),
            'isSent': false,
          }),
    ];

    // Sort by date
    allTransactions.sort((a, b) {
      final aDate = a['Date'] as Timestamp;
      final bDate = b['Date'] as Timestamp;
      return bDate.compareTo(aDate);
    });

    return allTransactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 30),
                _buildActiveCard(),
                SizedBox(height: 30),
                _buildPaymentsList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PaymentPage()),
          );
        },
        backgroundColor: Color(0xFFD4AF37),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payments',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF1A2235),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.search,
            color: Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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

        final transactions = snapshot.data ?? [];
        final recentTransactions = transactions.take(5).toList();
        final totalSent = transactions
            .where((t) => t['isSent'] == true)
            .fold<double>(
                0,
                (sum, t) =>
                    sum +
                    (double.tryParse(t['Amount']?.toString() ?? '0') ?? 0));
        final totalReceived = transactions
            .where((t) => t['isSent'] == false)
            .fold<double>(
                0,
                (sum, t) =>
                    sum +
                    (double.tryParse(t['Amount']?.toString() ?? '0') ?? 0));

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    Icons.analytics,
                    color: Color(0xFFD4AF37),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildStatItem(
                        'Sent', '₹${totalSent.toStringAsFixed(2)}', Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem('Received',
                        '₹${totalReceived.toStringAsFixed(2)}', Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatItem(
                        'Total',
                        '₹${(totalReceived - totalSent).toStringAsFixed(2)}',
                        Color(0xFFD4AF37)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ...recentTransactions.map((transaction) {
                final isSent = transaction['isSent'] as bool;
                final amount = transaction['Amount']?.toString() ?? '0';
                final otherParty =
                    isSent ? transaction['To'] : transaction['From'];
                final date = transaction['Date'] as Timestamp?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isSent ? 'To: $otherParty' : 'From: $otherParty',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8A94A6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isSent ? "-" : "+"}₹$amount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSent ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A94A6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 15),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final transactions = snapshot.data ?? [];

            if (transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Color(0xFF8A94A6),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(
                        color: Color(0xFF8A94A6),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isSent = transaction['isSent'] as bool;
                final amount = transaction['Amount']?.toString() ?? '0';
                final paymentMethod =
                    transaction['Payment Method'] ?? 'Unknown';
                final date = transaction['Date'] as Timestamp?;
                final otherParty =
                    isSent ? transaction['To'] : transaction['From'];
                final type = transaction['Type'] ?? '';

                return Container(
                  margin: EdgeInsets.only(bottom: 15),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A2235),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSent
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF0A0E17),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getTransactionIcon(type),
                          color: isSent ? Colors.red : Colors.green,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSent ? 'To: $otherParty' : 'From: $otherParty',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Color(0xFF8A94A6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _formatDate(date!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8A94A6),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF0A0E17),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      paymentMethod,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFD4AF37),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${isSent ? "-" : "+"}₹$amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSent ? Colors.red : Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSent
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSent ? 'SENT' : 'RECEIVED',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSent ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDate(Timestamp date) {
    final now = DateTime.now();
    final transactionDate = date.toDate();
    final difference = now.difference(transactionDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PHONE_NUMBER':
        return Icons.phone;
      case 'CREDIT_CARD':
      case 'CARD':
        return Icons.credit_card;
      case 'BANK_TRANSFER':
      case 'NEFT':
      case 'RTGS':
      case 'IMPS':
        return Icons.account_balance;
      case 'UPI':
        return Icons.phone_android;
      case 'WALLET':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
