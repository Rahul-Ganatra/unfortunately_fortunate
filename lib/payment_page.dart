import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PaymentType { NEFT, CREDIT_CARD, PHONE_NUMBER }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  PaymentType _selectedPaymentType = PaymentType.CREDIT_CARD;
  String _selectedCountryCode = '+91'; // Default to India

  // List of common country codes
  final List<String> _countryCodes = [
    '+91', // India
    '+1', // USA/Canada
    '+44', // UK
    '+61', // Australia
    '+81', // Japan
    '+86', // China
    '+33', // France
    '+49', // Germany
    '+39', // Italy
    '+34', // Spain
  ];

  // Controllers for all required fields
  final _amountController = TextEditingController();
  final _recipientUsernameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _contactNumberController = TextEditingController();

  Future<void> _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Get sender's username from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final senderUsername = prefs.getString('username');
        if (senderUsername == null) {
          throw Exception('Sender profile not found');
        }

        // Verify recipient username
        final recipientUsername = _recipientUsernameController.text.trim();
        final recipientQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: recipientUsername)
            .get();

        if (recipientQuery.docs.isEmpty) {
          throw Exception('Recipient username does not exist');
        }

        if (senderUsername == recipientUsername) {
          throw Exception('Cannot send payment to yourself');
        }

        final amount = double.parse(_amountController.text);

        // Create transaction data
        final transactionData = {
          'From': senderUsername,
          'To': recipientUsername,
          'Type': _selectedPaymentType.toString().split('.').last,
          'Amount': amount,
          'Payment Method': _selectedPaymentType.toString().split('.').last,
          'Card Number': _selectedPaymentType == PaymentType.CREDIT_CARD
              ? _cardNumberController.text
                  .replaceAll(RegExp(r'\d(?=\d{4})'), '*')
              : null,
          'Expiry Date': _selectedPaymentType == PaymentType.CREDIT_CARD
              ? _expiryDateController.text
              : null,
          'CVV': _selectedPaymentType == PaymentType.CREDIT_CARD
              ? _cvvController.text
              : null,
          'Account Number': _selectedPaymentType == PaymentType.NEFT
              ? _accountNumberController.text
              : null,
          'IFSC Code': _selectedPaymentType == PaymentType.NEFT
              ? _ifscCodeController.text
              : null,
          'Contact Number': _selectedPaymentType == PaymentType.PHONE_NUMBER
              ? '$_selectedCountryCode${_contactNumberController.text}'
              : null,
          'Date': FieldValue.serverTimestamp(),
          'Status': 'Completed',
          'TransactionID': DateTime.now().millisecondsSinceEpoch.toString(),
        };

        // Add transaction to Firestore
        await _firestore.collection('transactions').add(transactionData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        String errorMessage = 'Error: ';
        if (e.toString().contains('Recipient username does not exist')) {
          errorMessage = 'Recipient username does not exist';
        } else if (e.toString().contains('Cannot send payment to yourself')) {
          errorMessage = 'Cannot send payment to yourself';
        } else if (e.toString().contains('Sender profile not found')) {
          errorMessage = 'Please complete your profile setup';
        } else if (e.toString().contains('User not authenticated')) {
          errorMessage = 'Please login again';
        } else {
          errorMessage += e.toString();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('New Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentTypeDropdown(),
                const SizedBox(height: 20),
                _buildAmountField(),
                const SizedBox(height: 20),
                _buildRecipientUsernameField(),
                const SizedBox(height: 20),
                _buildPaymentFields(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF8A94A6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentType>(
          value: _selectedPaymentType,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A2235),
          style: const TextStyle(color: Colors.white),
          items: PaymentType.values.map((PaymentType type) {
            return DropdownMenuItem<PaymentType>(
              value: type,
              child: Text(type.toString().split('.').last),
            );
          }).toList(),
          onChanged: (PaymentType? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPaymentType = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaymentFields() {
    switch (_selectedPaymentType) {
      case PaymentType.CREDIT_CARD:
        return _buildCardFields();
      case PaymentType.NEFT:
        return _buildBankFields();
      case PaymentType.PHONE_NUMBER:
        return _buildContactField();
    }
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: _buildInputDecoration('Amount', 'Enter amount'),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Amount is required';
        final amount = double.tryParse(value!);
        if (amount == null) return 'Enter valid amount';
        if (amount <= 0) return 'Amount must be greater than 0';
        return null;
      },
    );
  }

  Widget _buildRecipientUsernameField() {
    return TextFormField(
      controller: _recipientUsernameController,
      decoration: _buildInputDecoration(
          'Recipient Username', 'Enter recipient username'),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Recipient username is required';
        if (value!.trim().length < 3)
          return 'Username must be at least 3 characters';
        return null;
      },
    );
  }

  Widget _buildCardFields() {
    return Column(
      children: [
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: _buildInputDecoration('Card Number', 'Enter card number'),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            CardNumberFormatter(),
          ],
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Card number is required';
            if (value!.replaceAll(' ', '').length != 16)
              return 'Card number must be 16 digits';
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryDateController,
                decoration: _buildInputDecoration('Expiry Date', 'MM/YY'),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  CardExpiryFormatter(),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Expiry date is required';
                  if (value!.length != 5) return 'Invalid expiry date format';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: _cvvController,
                decoration: _buildInputDecoration('CVV', '123'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'CVV is required';
                  if (value!.length != 3) return 'CVV must be 3 digits';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      children: [
        TextFormField(
          controller: _accountNumberController,
          decoration:
              _buildInputDecoration('Account Number', 'Enter account number'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Account number is required';
            if (value!.length < 9 || value.length > 18)
              return 'Invalid account number';
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _ifscCodeController,
          decoration: _buildInputDecoration('IFSC Code', 'Enter IFSC code'),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'IFSC code is required';
            if (value!.length != 11) return 'IFSC code must be 11 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF8A94A6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A2235),
              style: const TextStyle(color: Colors.white),
              items: _countryCodes.map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(code),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCountryCode = newValue;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _contactNumberController,
          decoration:
              _buildInputDecoration('Contact Number', 'Enter contact number'),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Contact number is required';
            if (value!.length != 10) return 'Contact number must be 10 digits';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_formKey.currentState?.validate() ?? false) {
                  _submitPayment();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: const Color(0xFFD4AF37).withOpacity(0.5),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              )
            : const Text(
                'Submit Payment',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
      hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
      filled: true,
      fillColor: const Color(0xFF1A2235),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8A94A6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8A94A6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _recipientUsernameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }
}

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class CardExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
