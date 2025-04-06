import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_page.dart';
import 'cards_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';
import 'transactions_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return HomePage();
      case 1:
        return const AnalyticsPage();
      case 2:
        return CardsPage();
      case 3:
        return ProfilePage();
      default:
        return HomePage();
    }
  }

  Widget _buildBottomNavigation() {
    final navItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.insert_chart, 'label': 'Analytics'},
      {'icon': Icons.credit_card, 'label': 'Cards'},
      {'icon': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == _currentIndex;

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: isActive
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF8A94A6),
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF8A94A6),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildBalanceCard(),
                const SizedBox(height: 30),
                _buildQuickActions(),
                const SizedBox(height: 30),
                _buildFeaturesSection(),
                const SizedBox(height: 30),
                _buildTransactionsList(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FutureBuilder<String>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getString('username') ?? 'User'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              );
            }

            final username = snapshot.data ?? 'User';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8A94A6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF1A2235),
            shape: BoxShape.circle,
          ),
          child: FutureBuilder<String>(
            future: SharedPreferences.getInstance()
                .then((prefs) => prefs.getString('username') ?? '?'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                );
              }

              final username = snapshot.data ?? '?';
              final firstLetter =
                  username.isNotEmpty ? username[0].toUpperCase() : '?';

              return Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return FutureBuilder<String>(
      future: SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('username') ?? ''),
      builder: (context, usernameSnapshot) {
        if (usernameSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            ),
          );
        }

        final currentUsername = usernameSnapshot.data ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('transactions')
              .where('From', isEqualTo: currentUsername)
              .snapshots(),
          builder: (context, sentSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('transactions')
                  .where('To', isEqualTo: currentUsername)
                  .snapshots(),
              builder: (context, receivedSnapshot) {
                if (sentSnapshot.connectionState == ConnectionState.waiting ||
                    receivedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  );
                }

                // Calculate total sent amount
                double totalSent = 0;
                for (var doc in sentSnapshot.data?.docs ?? []) {
                  final transaction = doc.data() as Map<String, dynamic>;
                  totalSent += double.parse(transaction['Amount'].toString());
                }

                // Calculate total received amount
                double totalReceived = 0;
                for (var doc in receivedSnapshot.data?.docs ?? []) {
                  final transaction = doc.data() as Map<String, dynamic>;
                  totalReceived +=
                      double.parse(transaction['Amount'].toString());
                }

                // Calculate total balance
                final totalBalance = totalReceived - totalSent;

                return Container(
                  height: 200,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0E1624), Color(0xFF162440)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFFD4AF37),
                            size: 24,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${totalBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBalanceInfo(
                                'Income',
                                totalReceived.toStringAsFixed(2),
                                true,
                              ),
                              _buildBalanceInfo(
                                'Outgoing',
                                totalSent.toStringAsFixed(2),
                                false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceInfo(String label, String amount, bool isIncome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8A94A6),
          ),
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Icon(
              isIncome ? Icons.arrow_upward : Icons.arrow_downward,
              color:
                  isIncome ? const Color(0xFF4CD964) : const Color(0xFFFF3B30),
              size: 16,
            ),
            SizedBox(width: 5),
            Text(
              '₹$amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('quickActions')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final actions = snapshot.data?.docs ?? [];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                switch (data['type']) {
                  case 'send':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PaymentPage()),
                    );
                    break;
                  // Add other action types as needed
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2235),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      _getIconData(data['icon']),
                      color: const Color(0xFFD4AF37),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['label'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'send':
        return Icons.arrow_upward;
      case 'invest':
        return Icons.bar_chart;
      case 'exchange':
        return Icons.swap_horiz;
      default:
        return Icons.error;
    }
  }

  Widget _buildFeaturesSection() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .collection('features')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final features = snapshot.data?.docs ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index].data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2235),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _getIconData(feature['icon']),
                        color:
                            Color(int.parse(feature['color'] ?? '0xFFD4AF37')),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            feature['description'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CardsPage()),
                );
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        FutureBuilder<String>(
          future: SharedPreferences.getInstance()
              .then((prefs) => prefs.getString('username') ?? ''),
          builder: (context, usernameSnapshot) {
            if (usernameSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (usernameSnapshot.hasError) {
              return Center(child: Text('Error fetching username'));
            }

            final currentUsername = usernameSnapshot.data ?? '';

            if (currentUsername.isEmpty) {
              return Center(child: Text('Username not available'));
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('transactions')
                  .where('From', isEqualTo: currentUsername)
                  .orderBy('Date', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (context, sentSnapshot) {
                if (sentSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                    ),
                  );
                }
                if (sentSnapshot.hasError) {
                  return Center(
                      child: Text('Error fetching sent transactions'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('transactions')
                      .where('To', isEqualTo: currentUsername)
                      .orderBy('Date', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, receivedSnapshot) {
                    if (receivedSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                        ),
                      );
                    }
                    if (receivedSnapshot.hasError) {
                      return Center(
                          child: Text('Error fetching received transactions'));
                    }

                    final allTransactions = [
                      ...?sentSnapshot.data?.docs,
                      ...?receivedSnapshot.data?.docs
                    ];

                    if (allTransactions.isEmpty) {
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
                              'No recent transactions',
                              style: TextStyle(
                                color: Color(0xFF8A94A6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    allTransactions.sort((a, b) {
                      final aDate = a['Date'] as Timestamp;
                      final bDate = b['Date'] as Timestamp;
                      return bDate.compareTo(aDate);
                    });
                    final recentTransactions = allTransactions.take(3).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final doc = recentTransactions[index];
                        final transaction = doc.data() as Map<String, dynamic>;

                        final isSender = transaction['From'] == currentUsername;
                        final amount = transaction['Amount']?.toString() ?? '0';
                        final paymentMethod =
                            transaction['Payment Method'] ?? 'Unknown';
                        final date = transaction['Date'] as Timestamp?;
                        final otherParty =
                            isSender ? transaction['To'] : transaction['From'];
                        final type = transaction['Type'] ?? '';

                        return Container(
                          margin: EdgeInsets.only(bottom: 15),
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Color(0xFF1A2235),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSender
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
                                  color: isSender ? Colors.red : Colors.green,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSender
                                          ? 'To: $otherParty'
                                          : 'From: $otherParty',
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                    '${isSender ? "-" : "+"}₹$amount',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSender ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSender
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isSender ? 'SENT' : 'RECEIVED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSender
                                            ? Colors.red
                                            : Colors.green,
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  IconData _getTransactionIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'CREDIT_CARD':
        return Icons.credit_card;
      case 'NEFT':
        return Icons.account_balance;
      case 'PHONE_NUMBER':
        return Icons.phone;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(Timestamp date) {
    final DateTime dateTime = date.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
