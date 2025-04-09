# Flag It Up 🚩

A modern web application for detecting and preventing suspicious financial transactions using machine learning and real-time monitoring.

## Overview

Flag It Up is an anti-money laundering (AML) system that helps financial institutions identify and flag potentially suspicious transactions. The system uses machine learning algorithms to analyze transaction patterns and provides a user-friendly interface for both users and administrators.

## Features

### User Features
- Secure user authentication and registration
- Multiple payment methods (Card, NEFT, Contact)
- Real-time transaction processing
- Transaction history viewing
- Secure payment information handling

### Admin Features
- Comprehensive transaction monitoring dashboard
- Advanced analytics and visualization
- Real-time suspicious activity detection
- Multiple detection criteria:
  - Odd hours transactions (2 AM - 5 AM)
  - High-value transactions (>₹50,000)
  - International number detection
  - Round amount transactions
  - Small amount card/NEFT transactions
  - Frequent small transactions pattern
- Transaction flagging with confidence scores
- Detailed transaction information

### Security Features
- Firebase Authentication
- Secure API endpoints
- Password encryption
- Admin access control
- Token-based authentication
- Secure session management

## Technology Stack

- **Frontend**:
  - HTML5
  - CSS3 (Modern animations and transitions)
  - JavaScript (ES6+)
  - Firebase SDK

- **Backend**:
  - Python Flask
  - Firebase Admin SDK
  - Machine Learning Models

- **Database**:
  - Firebase Firestore

- **Authentication**:
  - Firebase Authentication

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Rahul-Ganatra/Flagitup
   cd flagitup
   ```

2. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Authentication and Firestore
   - Add your Firebase configuration in `templates/index.html`
   - Download Firebase Admin SDK key and set it up


4. **Run the Application**
   ```bash
   python app.py
   ```

## Usage

### User Interface
1. Register/Login as a user
2. Make transactions using various payment methods
3. View transaction history
4. Monitor transaction status

### Admin Interface
1. Login with admin credentials
2. Monitor all transactions
3. View flagged suspicious activities
4. Check transaction analytics
5. Review user activities

## Suspicious Transaction Detection

The system flags transactions based on various criteria:

1. **Time-based Detection**
   - Transactions during odd hours (2 AM - 5 AM)

2. **Amount-based Detection**
   - High-value transactions (>₹50,000)
   - Round amount transactions
   - Small amount card/NEFT transactions (<₹1,000)

3. **Pattern-based Detection**
   - Frequent small transactions to same receiver
   - Multiple transactions in short time spans

4. **Location-based Detection**
   - International number detection
   - Cross-border transactions