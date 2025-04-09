from flask import Flask, render_template, request, jsonify
from flask_cors import CORS  # Import CORS
import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "http://127.0.0.1:5000"}})

# Initialize Firebase
load_dotenv()
service_key = os.getenv('SERVICE_KEY')

cred = credentials.Certificate(service_key)
firebase_admin.initialize_app(cred)
db = firestore.client()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/admin')
def admin_dashboard():
    return render_template('admin-dashboard.html')

@app.route('/admin/transactions')
def admin_transactions():
    return render_template('admin-transactions.html')

@app.route('/user')
def user_dashboard():
    return render_template('user-dashboard.html')

@app.route('/user/transactions')
def user_transactions():
    return render_template('user-transaction.html')

@app.route('/api/login', methods=['POST'])
def login():
    # Your login logic here
    return jsonify({"status": "success"})  # Example response

if __name__ == '__main__':
    app.run(debug=True)
