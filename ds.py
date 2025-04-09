import random
import pandas as pd
from datetime import datetime, timedelta

# Constants
NUM_TRANSACTIONS = 1000  # Total number of transactions
SUSPICIOUS_AMOUNT_THRESHOLD = 10000  # Amount threshold for suspicious transactions
SMALL_AMOUNT_THRESHOLD = 500  # Define what is considered a small amount
TIME_LIMIT_MINUTES = 10  # Time limit for continuous small transactions

# Sample data
usernames = [f'user{i}' for i in range(1, 101)]  # 100 users
transaction_types = ['neft', 'card', 'contact']
payment_methods = ['NEFT Transfer', 'Card Payment', 'Contact Payment']

# Function to generate a random transaction
def generate_transaction(is_suspicious=False, recent_transactions=None, odd_timing=False):
    sender = random.choice(usernames)
    receiver = random.choice(usernames)
    while receiver == sender:  # Ensure sender and receiver are not the same
        receiver = random.choice(usernames)
    
    transaction_type = random.choice(transaction_types)
    amount = random.randint(1000, 20000)  # Random amount between 1000 and 20000
    if is_suspicious:
        amount = random.randint(SUSPICIOUS_AMOUNT_THRESHOLD + 1, 50000)  # Ensure it's above the threshold
    
    payment_method = random.choice(payment_methods)
    
    # Set timestamp for odd timing transactions
    if odd_timing:
        # Generate a timestamp between 2 AM and 5 AM
        hour = random.randint(2, 4)  # 2 AM to 4 AM
        timestamp = datetime.now().replace(hour=hour, minute=random.randint(0, 59), second=0, microsecond=0)
    else:
        timestamp = datetime.now() - timedelta(days=random.randint(0, 30))  # Random date within the last 30 days
    
    date_str = timestamp.strftime("%m/%d/%Y, %I:%M:%S %p")  # Format date

    # Card details (randomly generated)
    card_number = random.choice(['-', '1234567890123456'])  # Example card number
    expiry_date = random.choice(['-', '02/29'])  # Example expiry date
    cvv = random.choice(['-', '111'])  # Example CVV
    account_number = random.choice(['9876543210', '-'])  # Example account number
    ifsc_code = random.choice(['SBIN1234567', '-'])  # Example IFSC code
    
    # Generate a contact number, some of which will be international
    contact_number = random.choice(['+14155552671', '+441632960961', '9152251477', '1234567890'])  # Example contact numbers

    # Flagging logic
    suspicion_reasons = []
    if amount > SUSPICIOUS_AMOUNT_THRESHOLD:
        suspicion_reasons.append("High transaction amount")
    
    # Check for small continuous transactions
    if recent_transactions:
        for trans in recent_transactions:
            if (trans['sender'] == sender and trans['receiver'] == receiver and
                (timestamp - trans['timestamp']).total_seconds() / 60 <= TIME_LIMIT_MINUTES and
                trans['amount'] < SMALL_AMOUNT_THRESHOLD):
                suspicion_reasons.append("Frequent small transactions to the same recipient")
                is_suspicious = True
                break

    # Check for odd timing (between 2 AM and 5 AM)
    transaction_hour = timestamp.hour
    if 2 <= transaction_hour < 5 and amount > SUSPICIOUS_AMOUNT_THRESHOLD:
        suspicion_reasons.append("Transaction at odd hours (2 AM - 5 AM)")
        is_suspicious = True

    # Check for international contact numbers (not starting with +91)
    if not contact_number.startswith('+91') and contact_number.startswith('+'):
        suspicion_reasons.append("Transaction to a non-Indian contact number")
        is_suspicious = True

    return {
        "From": sender,
        "To": receiver,
        "Type": transaction_type,
        "Amount": amount,
        "Payment Method": payment_method,
        "Card Number": card_number,
        "Expiry Date": expiry_date,
        "CVV": cvv,
        "Account Number": account_number,
        "IFSC Code": ifsc_code,
        "Contact Number": contact_number,
        "Date": date_str,
        "is_suspicious": is_suspicious,
        "suspicion_reasons": suspicion_reasons,  # List of reasons
        "timestamp": timestamp
    }

# Generate the dataset
transactions = []
recent_transactions = []  # To track recent transactions for flagging

# Add specific entries for user 1 to user 2 with small amounts
user_1 = 'user1'
user_2 = 'user2'

# Create frequent small transactions from user 1 to user 2
for _ in range(10):  # Add 10 frequent small transactions
    for _ in range(5):  # 5 small transactions
        transaction = generate_transaction(is_suspicious=True, recent_transactions=recent_transactions)
        transaction['Amount'] = random.randint(1, SMALL_AMOUNT_THRESHOLD - 1)  # Small amount
        transaction['From'] = user_1
        transaction['To'] = user_2
        transaction['suspicion_reasons'] = ["Frequent small transactions to the same recipient"]
        transactions.append(transaction)
        recent_transactions.append({
            'sender': transaction['From'],
            'receiver': transaction['To'],
            'amount': transaction['Amount'],
            'timestamp': transaction['timestamp']
        })

# Add transactions at odd hours
for _ in range(10):  # Add 10 odd hour transactions
    transaction = generate_transaction(is_suspicious=True, recent_transactions=recent_transactions, odd_timing=True)
    transactions.append(transaction)
    recent_transactions.append({
        'sender': transaction['From'],
        'receiver': transaction['To'],
        'amount': transaction['Amount'],
        'timestamp': transaction['timestamp']
    })

# Generate the rest of the dataset
for i in range(NUM_TRANSACTIONS - 60):  # Subtract the 60 transactions we just added
    is_suspicious = (i % 20 == 0)  # Flag every 20th transaction as suspicious
    transaction = generate_transaction(is_suspicious, recent_transactions)
    transactions.append(transaction)
    recent_transactions.append({
        'sender': transaction['From'],
        'receiver': transaction['To'],
        'amount': transaction['Amount'],
        'timestamp': transaction['timestamp']
    })

# Convert to DataFrame for easier handling
df = pd.DataFrame(transactions)

# Save to CSV or any other format
df.to_csv('transactions_dataset.csv', index=False)

print("Dataset created with suspicious transactions.")
