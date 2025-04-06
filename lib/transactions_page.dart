import 'package:flutter/material.dart';

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '1',
      'type': 'sent',
      'amount': 1250.00,
      'recipient': 'Luxury Boutique',
      'date': 'Today, 2:45 PM',
      'status': 'completed',
      'method': 'card',
      'card': 'Elysium Elite •••• 5432',
    },
    {
      'id': '2',
      'type': 'received',
      'amount': 8750.00,
      'sender': 'Parker Industries',
      'date': 'Apr 4, 9:30 AM',
      'status': 'completed',
      'method': 'neft',
      'account': '•••• 8765',
    },
    {
      'id': '3',
      'type': 'sent',
      'amount': 385.50,
      'recipient': 'Azure Restaurant',
      'date': 'Apr 3, 8:15 PM',
      'status': 'completed',
      'method': 'phone',
      'phone': '+1 234 567 8900',
    },
    {
      'id': '4',
      'type': 'sent',
      'amount': 2150.00,
      'recipient': 'Tech Store',
      'date': 'Apr 2, 3:20 PM',
      'status': 'completed',
      'method': 'card',
      'card': 'Elysium Elite •••• 5432',
    },
    {
      'id': '5',
      'type': 'received',
      'amount': 15000.00,
      'sender': 'Salary Deposit',
      'date': 'Apr 1, 12:00 PM',
      'status': 'completed',
      'method': 'neft',
      'account': '•••• 8765',
    },
    {
      'id': '6',
      'type': 'sent',
      'amount': 250.75,
      'recipient': 'Supermarket',
      'date': 'Mar 31, 5:30 PM',
      'status': 'completed',
      'method': 'card',
      'card': 'Elysium Elite •••• 5432',
    },
    {
      'id': '7',
      'type': 'sent',
      'amount': 45.00,
      'recipient': 'Movie Theater',
      'date': 'Mar 30, 8:15 PM',
      'status': 'completed',
      'method': 'card',
      'card': 'Elysium Elite •••• 5432',
    },
    {
      'id': '8',
      'type': 'sent',
      'amount': 50.00,
      'recipient': 'Mobile Recharge',
      'date': 'Mar 29, 10:00 AM',
      'status': 'completed',
      'method': 'phone',
      'phone': '+1 234 567 8900',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((transaction) {
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'sent' && transaction['type'] == 'sent') ||
          (_selectedFilter == 'received' && transaction['type'] == 'received');

      final matchesSearch = _searchController.text.isEmpty ||
          transaction['recipient']
                  ?.toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ==
              true ||
          transaction['sender']
                  ?.toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ==
              true;

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1A2235),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: TextStyle(color: Color(0xFF8A94A6)),
                prefixIcon: Icon(Icons.search, color: Color(0xFF8A94A6)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Sent', 'sent'),
                _buildFilterChip('Received', 'received'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Color(0xFF8A94A6),
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Color(0xFF1A2235),
        selectedColor: Color(0xFFD4AF37),
        checkmarkColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions found',
          style: TextStyle(
            color: Color(0xFF8A94A6),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return Container(
          margin: EdgeInsets.only(bottom: 15),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF0A0E17),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          transaction['type'] == 'sent'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: transaction['type'] == 'sent'
                              ? Color(0xFFFF3B30)
                              : Color(0xFF4CD964),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['type'] == 'sent'
                                ? transaction['recipient']
                                : transaction['sender'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            transaction['date'],
                            style: TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${transaction['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          color: transaction['type'] == 'sent'
                              ? Color(0xFFFF3B30)
                              : Color(0xFF4CD964),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: transaction['status'] == 'completed'
                              ? Color(0xFF4CD964).withOpacity(0.1)
                              : Color(0xFFFF9500).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction['status'].toUpperCase(),
                          style: TextStyle(
                            color: transaction['status'] == 'completed'
                                ? Color(0xFF4CD964)
                                : Color(0xFFFF9500),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 15),
              Divider(color: Color(0xFF8A94A6).withOpacity(0.2)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getMethodIcon(transaction['method']),
                        color: Color(0xFF8A94A6),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _getMethodLabel(transaction),
                        style: TextStyle(
                          color: Color(0xFF8A94A6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'card':
        return Icons.credit_card;
      case 'neft':
        return Icons.account_balance;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.payment;
    }
  }

  String _getMethodLabel(Map<String, dynamic> transaction) {
    switch (transaction['method']) {
      case 'card':
        return transaction['card'];
      case 'neft':
        return 'Account ${transaction['account']}';
      case 'phone':
        return transaction['phone'];
      default:
        return 'Unknown';
    }
  }
}
