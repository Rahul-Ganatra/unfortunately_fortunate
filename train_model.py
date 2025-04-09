import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib

def preprocess_data(df):
    # Convert timestamp to datetime if it's not already
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    
    # Extract time-based features
    df['hour'] = df['timestamp'].dt.hour
    df['day_of_week'] = df['timestamp'].dt.dayofweek
    
    # Create binary features for payment methods and transaction types
    df['is_card'] = (df['Type'] == 'card').astype(int)
    df['is_neft'] = (df['Type'] == 'neft').astype(int)
    df['is_contact'] = (df['Type'] == 'contact').astype(int)
    
    # Handle contact numbers
    df['is_international'] = df['Contact Number'].apply(
        lambda x: 1 if isinstance(x, str) and not x.startswith('+91') else 0
    )
    
    # Create features for transaction patterns
    df['transaction_hour'] = df['timestamp'].dt.hour
    df['is_odd_hours'] = ((df['transaction_hour'] >= 2) & 
                         (df['transaction_hour'] < 5)).astype(int)
    
    # Flag small amount card/NEFT transactions
    df['is_small_amount_card_neft'] = (
        (df['Amount'] < 1000) & 
        ((df['Type'] == 'card') | (df['Type'] == 'neft'))
    ).astype(int)
    
    # Track frequent small transactions to same receiver
    df['small_tx_count'] = 0
    if 'From' in df.columns and 'To' in df.columns:
        for sender in df['From'].unique():
            for receiver in df['To'].unique():
                mask = (df['From'] == sender) & (df['To'] == receiver) & (df['Amount'] < 1000)
                if mask.any():
                    df.loc[mask, 'small_tx_count'] = mask.cumsum()
        
        df['frequent_small_tx'] = (df['small_tx_count'] > 3).astype(int)
    
    # Select features for the model
    features = [
        'Amount', 'is_card', 'is_neft', 'is_contact',
        'is_international', 'hour', 'day_of_week', 'is_odd_hours',
        'is_small_amount_card_neft', 'frequent_small_tx'
    ]
    
    return df[features], df['is_suspicious']

def train_model():
    # Load the dataset
    try:
        df = pd.read_csv('transactions_dataset.csv')
        print("Dataset loaded successfully!")
        print("\nDataset shape:", df.shape)
        print("\nSample of the dataset:")
        print(df.head())
        
        # Check class distribution
        print("\nClass distribution:")
        print(df['is_suspicious'].value_counts(normalize=True))
        
        # Preprocess the data
        X, y = preprocess_data(df)
        print("\nFeatures used for training:", X.columns.tolist())
        
        # Split the data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Scale the features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Train the model
        print("\nTraining Random Forest model...")
        model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42,
            class_weight='balanced'
        )
        model.fit(X_train_scaled, y_train)
        
        # Make predictions
        y_pred = model.predict(X_test_scaled)
        
        # Calculate accuracy
        accuracy = accuracy_score(y_test, y_pred)
        print("\nModel Accuracy: {:.2f}%".format(accuracy * 100))
        
        # Print detailed classification report
        print("\nClassification Report:")
        print(classification_report(y_test, y_pred))
        
        # Print confusion matrix
        print("\nConfusion Matrix:")
        print(confusion_matrix(y_test, y_pred))
        
        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': X.columns,
            'importance': model.feature_importances_
        })
        print("\nFeature Importance:")
        print(feature_importance.sort_values('importance', ascending=False))
        
        # Save the model and scaler
        joblib.dump(model, 'suspicious_transaction_model.joblib')
        joblib.dump(scaler, 'scaler.joblib')
        print("\nModel and scaler saved successfully!")
        
        return model, scaler
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return None, None

if __name__ == "__main__":
    model, scaler = train_model()

def predict_transaction(transaction_data, model, scaler):
    """
    Make predictions on new transactions.
    
    Args:
        transaction_data (dict): Dictionary containing transaction information
        model: Trained model
        scaler: Fitted scaler
    
    Returns:
        bool: True if transaction is suspicious, False otherwise
    """
    # Create a DataFrame with the same features used in training
    df = pd.DataFrame([transaction_data])
    
    # Preprocess the data
    X, _ = preprocess_data(df)
    
    # Scale the features
    X_scaled = scaler.transform(X)
    
    # Make prediction
    prediction = model.predict(X_scaled)[0]
    probability = model.predict_proba(X_scaled)[0][1]
    
    return prediction, probability