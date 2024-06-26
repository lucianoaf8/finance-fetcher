import os
import json
import logging
from dotenv import load_dotenv
from decimal import Decimal
from plaid.api import plaid_api
from plaid import configuration, api_client
from plaid.model.transactions_enrich_request import TransactionsEnrichRequest
from plaid.model.client_provided_transaction import ClientProvidedTransaction
from plaid.model.enrich_transaction_direction import EnrichTransactionDirection
from datetime import datetime
from urllib.parse import urlparse
from mysql.connector import pooling
from plaid.api_client import ApiException

# Load environment variables from .env file
load_dotenv()

# Set up logging
log_dir = 'logs'
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

today = datetime.now().strftime('%Y-%m-%d')
logging.basicConfig(
    filename=os.path.join(log_dir, f'plaid_enrich_{today}.log'),
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s'
)

# Database connection pool
MYSQL_URL = os.getenv("MYSQL_URL")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")

url = urlparse(MYSQL_URL)
connection_pool = pooling.MySQLConnectionPool(
    pool_name="mypool",
    pool_size=5,
    host=url.hostname,
    port=url.port if url.port else 3306,
    user=MYSQL_USER,
    password=MYSQL_PASSWORD,
    database='finance'  # Hardcoded the database name
)

def get_db_connection():
    return connection_pool.get_connection()

# Plaid configuration
PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID")
PLAID_SECRET = os.getenv("PLAID_SECRET")
PLAID_ENV = os.getenv("PLAID_ENV", "development")

PLAID_ENV_URLS = {
    "sandbox": "https://sandbox.plaid.com",
    "development": "https://development.plaid.com",
    "production": "https://production.plaid.com"
}
PLAID_HOST = PLAID_ENV_URLS.get(PLAID_ENV, "https://production.plaid.com")

configuration = configuration.Configuration(
    host=PLAID_HOST,
    api_key={
        'clientId': PLAID_CLIENT_ID,
        'secret': PLAID_SECRET
    }
)
api_client = api_client.ApiClient(configuration)
client = plaid_api.PlaidApi(api_client)

def get_data_to_enrich():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM finance.mbna_transactions")
        transactions = cursor.fetchall()
        cursor.close()
        conn.close()
        return transactions
    except Exception as e:
        print(f"Error getting data from database: {e}")
        logging.error(f"Error getting data from database: {e}")
        return []

def enrich_transactions(transactions):
    enriched_data = []
    for transaction in transactions:
        transaction_data = ClientProvidedTransaction(
            id=str(transaction["transaction_id"]),
            description=transaction["payeee"],
            amount=abs(float(transaction["amount"])),  # Ensure amount is non-negative
            iso_currency_code="CAD",  # Using CAD
            direction=EnrichTransactionDirection("OUTFLOW" if transaction["amount"] < 0 else "INFLOW")  # Use enum
        )
        enriched_data.append(transaction_data)
    
    batch_size = 100
    results = []

    for i in range(0, len(enriched_data), batch_size):
        batch = enriched_data[i:i+batch_size]
        request = TransactionsEnrichRequest(
            account_type="credit",  # Modify this as needed
            transactions=batch
        )
        
        try:
            response = client.transactions_enrich(request)
            results.extend(response.to_dict()['transactions'])
        except ApiException as e:
            print(f"Exception when calling PlaidApi->transactions_enrich: {e}")
            logging.error(f"Exception when calling PlaidApi->transactions_enrich: {e}")
    
    return results

def save_enriched_data(data):
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    filename = f'data/fetched-files/plaid_enriched_{timestamp}.json'
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'w') as file:
        json.dump(data, file, indent=4)
    print(f"Enriched data saved to {filename}")
    logging.info(f"Enriched data saved to {filename}")

def main():
    transactions = get_data_to_enrich()
    if transactions:
        enriched_data = enrich_transactions(transactions)
        if enriched_data:
            save_enriched_data(enriched_data)

if __name__ == "__main__":
    main()
