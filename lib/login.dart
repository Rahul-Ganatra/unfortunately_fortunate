import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'email_verification.dart';
import 'main_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _mpinController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _mpinController.text.isEmpty) {
      setState(() => _message = 'Please enter both email and MPIN');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final email = _emailController.text.trim();
      final mpin = _mpinController.text;

      // Query Firestore to find user by email in mpin collection
      final querySnapshot = await _firestore
          .collection('mpin')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _message = 'No account found with this email';
          _isLoading = false;
        });
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final storedMpin = userDoc.get('mpin');
      final userId = userDoc.id; // Get the document ID from mpin collection

      if (storedMpin == mpin) {
        // MPIN matches, check if user exists in users collection
        final userDocRef = _firestore.collection('users').doc(userId);
        final userDocSnapshot = await userDocRef.get();

        if (userDocSnapshot.exists) {
          // User exists, get username
          final userData = userDocSnapshot.data()!;
          final username =
              userData['username'] as String? ?? email.split('@')[0];

          // Store username in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);

          setState(() {
            _message = 'Login successful!';
            _isLoading = false;
          });

          // Navigate to MainPage and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
            (route) => false,
          );
        } else {
          // User doesn't exist in users collection, create it
          final username = email.split('@')[0];
          await userDocRef.set({
            'email': email,
            'username': username,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Store username in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);

          setState(() {
            _message = 'Login successful!';
            _isLoading = false;
          });

          // Navigate to MainPage and remove all previous routes
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
            (route) => false,
          );
        }
      } else {
        // MPIN doesn't match
        setState(() {
          _message = 'Incorrect MPIN';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo and Welcome Text
                Center(
                  child: Icon(
                    Icons.security,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Login to your secure account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
                const SizedBox(height: 48),
                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your registered email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                // MPIN Field
                TextField(
                  controller: _mpinController,
                  decoration: const InputDecoration(
                    labelText: 'MPIN',
                    hintText: '****',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                // Login Button
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[600]),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _message.startsWith('Error') ||
                                _message.startsWith('Incorrect') ||
                                _message.startsWith('No account')
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _message.startsWith('Error') ||
                                    _message.startsWith('Incorrect') ||
                                    _message.startsWith('No account')
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: _message.startsWith('Error') ||
                                    _message.startsWith('Incorrect') ||
                                    _message.startsWith('No account')
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _message,
                              style: TextStyle(
                                color: _message.startsWith('Error') ||
                                        _message.startsWith('Incorrect') ||
                                        _message.startsWith('No account')
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
