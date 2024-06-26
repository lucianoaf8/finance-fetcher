-- Create the database
CREATE DATABASE IF NOT EXISTS plaid;
USE plaid;

/*
plaid_access_tokens
    Table Description: Table to store Plaid access tokens, which are used to authenticate and interact with the Plaid API for accessing financial data.
Examples:
    token_id=1
    access_token='access-sandbox-123456'
    bank_name='Bank of America'
    bank_id='ins_1'
    products='transactions'
    accounts='12345678'
*/
CREATE TABLE plaid_access_tokens (
    token_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the token
    access_token VARCHAR(255) NOT NULL, -- Plaid access token
    bank_name VARCHAR(255) NOT NULL, -- Name of the bank
    bank_id VARCHAR(255), -- Plaid bank identifier
    products VARCHAR(255), -- Products associated with the token
    accounts VARCHAR(255) -- Accounts associated with the token
);

/*
plaid_accounts
    Table Description: Table to store detailed information about financial accounts retrieved from Plaid, including balance information and account metadata.
Examples:
    account_id='12345678'
    bank_name='Bank of America'
    available_balance=1000.00
    current_balance=1200.00
    balance_limit=1500.00
    iso_currency_code='USD'
    unofficial_currency_code=NULL
    mask='1234'
    name='Primary Checking'
    official_name='Bank of America Checking Account'
    type='depository'
    subtype='checking'
    created_at='2024-01-01 00:00:00'
    updated_at='2024-01-01 00:00:00'
*/
CREATE TABLE plaid_accounts (
    account_id VARCHAR(255) NOT NULL PRIMARY KEY, -- Unique identifier for the account
    bank_name VARCHAR(255), -- Name of the bank
    available_balance DECIMAL(15, 2), -- Available balance
    current_balance DECIMAL(15, 2), -- Current balance
    balance_limit DECIMAL(15, 2), -- Credit limit, if applicable
    iso_currency_code VARCHAR(3), -- ISO currency code (e.g., 'USD')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    mask VARCHAR(10), -- Masked account number
    name VARCHAR(255), -- Name of the account
    official_name VARCHAR(255), -- Official name of the account
    type VARCHAR(50), -- Type of account (e.g., 'depository')
    subtype VARCHAR(50), -- Subtype of account (e.g., 'checking')
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the record was created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- Timestamp when the record was last updated
);

/*
file_import_tracker
    Table Description: Table to track file imports, including metadata about the imported files such as their name, description, and the timestamp when they were imported.
Examples:
    id=1
    file_name='transactions_20240626.csv'
    description='Imported transactions for June 2024'
    created_at='2024-06-26 12:00:00'
*/
CREATE TABLE file_import_tracker (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the import record
    file_name VARCHAR(255) NOT NULL, -- Name of the imported file
    description TEXT, -- Description of the import
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the record was created
    INDEX (file_name) -- Index on the file_name column
);

/*
plaid_liabilities_credit
    Table Description: Table to store credit liability information from Plaid, including details about payments, statements, and overdue status for credit accounts.
Examples:
    id=1
    account_id='12345678'
    is_overdue=FALSE
    last_payment_amount=100.00
    last_payment_date='2024-06-01'
    last_statement_issue_date='2024-05-31'
    last_statement_balance=500.00
    minimum_payment_amount=50.00
    next_payment_due_date='2024-07-01'
    file_import_id=1
*/
CREATE TABLE plaid_liabilities_credit (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the liability record
    account_id VARCHAR(255) NOT NULL UNIQUE, -- Identifier for the associated account
    is_overdue BOOLEAN NOT NULL, -- Whether the account is overdue
    last_payment_amount DECIMAL(10, 2), -- Amount of the last payment
    last_payment_date DATE, -- Date of the last payment
    last_statement_issue_date DATE, -- Date of the last statement issue
    last_statement_balance DECIMAL(10, 2), -- Balance on the last statement
    minimum_payment_amount DECIMAL(10, 2), -- Minimum payment amount
    next_payment_due_date DATE, -- Due date for the next payment
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_liabilities_credit_apr
    Table Description: Table to store APR details for credit liabilities from Plaid, including APR percentages, types, and associated balances and charges.
Examples:
    id=1
    account_id='12345678'
    apr_percentage=20.99
    apr_type='variable'
    balance_subject_to_apr=500.00
    interest_charge_amount=10.00
    file_import_id=1
*/
CREATE TABLE plaid_liabilities_credit_apr (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the APR record
    account_id VARCHAR(255) NOT NULL, -- Identifier for the associated account
    apr_percentage DECIMAL(5, 2), -- APR percentage
    apr_type VARCHAR(255), -- Type of APR (e.g., 'variable')
    balance_subject_to_apr DECIMAL(10, 2), -- Balance subject to APR
    interest_charge_amount DECIMAL(10, 2), -- Interest charge amount
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE, -- Foreign key constraint
    FOREIGN KEY (account_id) REFERENCES plaid_liabilities_credit(account_id) -- Foreign key constraint
);

/*
plaid_transactions
    Table Description: Table to store detailed information about financial transactions retrieved from Plaid, including transaction metadata, amounts, dates, and location details.
Examples:
    id=1
    account_id='12345678'
    transaction_id='tx_123456'
    account_owner='John Doe'
    amount=50.00
    authorized_date='2024-06-01'
    authorized_datetime='2024-06-01 12:00:00'
    date='2024-06-01'
    datetime='2024-06-01 12:00:00'
    iso_currency_code='USD'
    logo_url='http://example.com/logo.png'
    merchant_entity_id='me_123456'
    merchant_name='Amazon'
    name='Amazon Purchase'
    payment_channel='online'
    pending=FALSE
    pending_transaction_id=NULL
    transaction_code='tx_123456'
    transaction_type='debit'
    unofficial_currency_code=NULL
    category='Shopping'
    category_id='cat_123456'
    personal_finance_category_confidence_level='high'
    personal_finance_category_detailed='e-commerce'
    personal_finance_category_primary='shopping'
    personal_finance_category_icon_url='http://example.com/icon.png'
    location_address='123 Main St'
    location_city='San Francisco'
    location_region='CA'
    location_postal_code='94105'
    location_country='US'
    location_lat=37.774929
    location_lon=-122.419418
    location_store_number='123'
    payment_meta_reference_number='ref_123456'
    payment_meta_ppd_id='ppd_123456'
    payment_meta_payee='Amazon'
    payment_meta_by_order_of=NULL
    payment_meta_payer='John Doe'
    payment_meta_payment_method='credit_card'
    payment_meta_payment_processor='Stripe'
    payment_meta_reason='Purchase'
    website='http://amazon.com'
    check_number='123456'
    file_import_id=1
    created_at='2024-06-01 12:00:00'
    updated_at='2024-06-01 12:00:00'
*/
CREATE TABLE plaid_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the transaction
    account_id VARCHAR(255) NOT NULL, -- Identifier for the associated account
    transaction_id VARCHAR(255) NOT NULL UNIQUE, -- Unique identifier for the transaction
    account_owner VARCHAR(255), -- Owner of the account
    amount DECIMAL(10, 2), -- Transaction amount
    authorized_date DATE, -- Date the transaction was authorized
    authorized_datetime DATETIME, -- DateTime the transaction was authorized
    date DATE, -- Date of the transaction
    datetime DATETIME, -- DateTime of the transaction
    iso_currency_code VARCHAR(10), -- ISO currency code (e.g., 'USD')
    logo_url VARCHAR(255), -- URL of the merchant's logo
    merchant_entity_id VARCHAR(255), -- Identifier for the merchant entity
    merchant_name VARCHAR(255), -- Name of the merchant
    name VARCHAR(255), -- Name of the transaction
    payment_channel VARCHAR(50), -- Payment channel (e.g., 'online')
    pending BOOLEAN, -- Whether the transaction is pending
    pending_transaction_id VARCHAR(255), -- Identifier for the pending transaction
    transaction_code VARCHAR(255), -- Transaction code
    transaction_type VARCHAR(50), -- Type of transaction (e.g., 'debit')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    category VARCHAR(255), -- Transaction category
    category_id VARCHAR(255), -- Identifier for the transaction category
    personal_finance_category_confidence_level VARCHAR(50), -- Confidence level of the personal finance category
    personal_finance_category_detailed VARCHAR(255), -- Detailed personal finance category
    personal_finance_category_primary VARCHAR(255), -- Primary personal finance category
    personal_finance_category_icon_url VARCHAR(255), -- URL of the personal finance category icon
    location_address VARCHAR(255), -- Address of the transaction location
    location_city VARCHAR(255), -- City of the transaction location
    location_region VARCHAR(50), -- Region/State of the transaction location
    location_postal_code VARCHAR(20), -- Postal code of the transaction location
    location_country VARCHAR(50), -- Country of the transaction location
    location_lat DECIMAL(10, 7), -- Latitude of the transaction location
    location_lon DECIMAL(10, 7), -- Longitude of the transaction location
    location_store_number VARCHAR(50), -- Store number of the transaction location
    payment_meta_reference_number VARCHAR(255), -- Reference number of the payment
    payment_meta_ppd_id VARCHAR(255), -- PPD ID of the payment
    payment_meta_payee VARCHAR(255), -- Payee of the payment
    payment_meta_by_order_of VARCHAR(255), -- By order of the payment
    payment_meta_payer VARCHAR(255), -- Payer of the payment
    payment_meta_payment_method VARCHAR(255), -- Payment method
    payment_meta_payment_processor VARCHAR(255), -- Payment processor
    payment_meta_reason VARCHAR(255), -- Reason for the payment
    website VARCHAR(255), -- Website of the merchant
    check_number VARCHAR(255), -- Check number, if applicable
    file_import_id INT, -- Identifier for the associated file import
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the record was created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Timestamp when the record was last updated
    INDEX (transaction_id), -- Index on the transaction_id column
    INDEX (account_id), -- Index on the account_id column
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_transaction_counterparties
    Table Description: Table to store information about transaction counterparties, including details such as name, type, website, and contact information.
Examples:
    id=1
    transaction_id='tx_123456'
    name='Amazon'
    type='merchant'
    website='http://amazon.com'
    logo_url='http://example.com/logo.png'
    confidence_level='high'
    entity_id='me_123456'
    phone_number='1-800-123-4567'
    file_import_id=1
*/
CREATE TABLE plaid_transaction_counterparties (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the counterparty
    transaction_id VARCHAR(255), -- Identifier for the associated transaction
    name VARCHAR(255), -- Name of the counterparty
    type VARCHAR(50), -- Type of counterparty (e.g., 'merchant')
    website VARCHAR(255), -- Website of the counterparty
    logo_url VARCHAR(255), -- URL of the counterparty's logo
    confidence_level VARCHAR(50), -- Confidence level of the counterparty data
    entity_id VARCHAR(255), -- Identifier for the counterparty entity
    phone_number VARCHAR(50), -- Phone number of the counterparty
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE, -- Foreign key constraint
    FOREIGN KEY (transaction_id) REFERENCES plaid_transactions(transaction_id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_liabilities_credit_history
    Table Description: Table to store historical credit liability information from Plaid, capturing details about past payments, statements, and overdue status.
Examples:
    id=1
    account_id='12345678'
    is_overdue=FALSE
    last_payment_amount=100.00
    last_payment_date='2024-06-01'
    last_statement_issue_date='2024-05-31'
    last_statement_balance=500.00
    minimum_payment_amount=50.00
    next_payment_due_date='2024-07-01'
    file_import_id=1
*/
CREATE TABLE plaid_liabilities_credit_history (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the liability record
    account_id VARCHAR(255) NOT NULL, -- Identifier for the associated account
    is_overdue BOOLEAN NOT NULL, -- Whether the account is overdue
    last_payment_amount DECIMAL(10, 2), -- Amount of the last payment
    last_payment_date DATE, -- Date of the last payment
    last_statement_issue_date DATE, -- Date of the last statement issue
    last_statement_balance DECIMAL(10, 2), -- Balance on the last statement
    minimum_payment_amount DECIMAL(10, 2), -- Minimum payment amount
    next_payment_due_date DATE, -- Due date for the next payment
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_liabilities_credit_apr_history
    Table Description: Table to store historical APR details for credit liabilities from Plaid, capturing past APR percentages, types, and associated balances and charges.
Examples:
    id=1
    account_id='12345678'
    apr_percentage=20.99
    apr_type='variable'
    balance_subject_to_apr=500.00
    interest_charge_amount=10.00
    file_import_id=1
*/
CREATE TABLE plaid_liabilities_credit_apr_history (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the APR record
    account_id VARCHAR(255) NOT NULL, -- Identifier for the associated account
    apr_percentage DECIMAL(5, 2), -- APR percentage
    apr_type VARCHAR(255), -- Type of APR (e.g., 'variable')
    balance_subject_to_apr DECIMAL(10, 2), -- Balance subject to APR
    interest_charge_amount DECIMAL(10, 2), -- Interest charge amount
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_transactions_history
    Table Description: Table to store historical transaction data from Plaid, capturing detailed information about past transactions, including metadata, amounts, dates, and locations.
Examples:
    id=1
    account_id='12345678'
    transaction_id='tx_123456'
    account_owner='John Doe'
    amount=50.00
    authorized_date='2024-06-01'
    authorized_datetime='2024-06-01 12:00:00'
    date='2024-06-01'
    datetime='2024-06-01 12:00:00'
    iso_currency_code='USD'
    logo_url='http://example.com/logo.png'
    merchant_entity_id='me_123456'
    merchant_name='Amazon'
    name='Amazon Purchase'
    payment_channel='online'
    pending=FALSE
    pending_transaction_id=NULL
    transaction_code='tx_123456'
    transaction_type='debit'
    unofficial_currency_code=NULL
    category='Shopping'
    category_id='cat_123456'
    personal_finance_category_confidence_level='high'
    personal_finance_category_detailed='e-commerce'
    personal_finance_category_primary='shopping'
    personal_finance_category_icon_url='http://example.com/icon.png'
    location_address='123 Main St'
    location_city='San Francisco'
    location_region='CA'
    location_postal_code='94105'
    location_country='US'
    location_lat=37.774929
    location_lon=-122.419418
    location_store_number='123'
    payment_meta_reference_number='ref_123456'
    payment_meta_ppd_id='ppd_123456'
    payment_meta_payee='Amazon'
    payment_meta_by_order_of=NULL
    payment_meta_payer='John Doe'
    payment_meta_payment_method='credit_card'
    payment_meta_payment_processor='Stripe'
    payment_meta_reason='Purchase'
    website='http://amazon.com'
    check_number='123456'
    file_import_id=1
    created_at='2024-06-01 12:00:00'
    updated_at='2024-06-01 12:00:00'
*/
CREATE TABLE plaid_transactions_history (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the transaction
    account_id VARCHAR(255) NOT NULL, -- Identifier for the associated account
    transaction_id VARCHAR(255) NOT NULL, -- Unique identifier for the transaction
    account_owner VARCHAR(255), -- Owner of the account
    amount DECIMAL(10, 2), -- Transaction amount
    authorized_date DATE, -- Date the transaction was authorized
    authorized_datetime DATETIME, -- DateTime the transaction was authorized
    date DATE, -- Date of the transaction
    datetime DATETIME, -- DateTime of the transaction
    iso_currency_code VARCHAR(10), -- ISO currency code (e.g., 'USD')
    logo_url VARCHAR(255), -- URL of the merchant's logo
    merchant_entity_id VARCHAR(255), -- Identifier for the merchant entity
    merchant_name VARCHAR(255), -- Name of the merchant
    name VARCHAR(255), -- Name of the transaction
    payment_channel VARCHAR(50), -- Payment channel (e.g., 'online')
    pending BOOLEAN, -- Whether the transaction is pending
    pending_transaction_id VARCHAR(255), -- Identifier for the pending transaction
    transaction_code VARCHAR(255), -- Transaction code
    transaction_type VARCHAR(50), -- Type of transaction (e.g., 'debit')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    category VARCHAR(255), -- Transaction category
    category_id VARCHAR(255), -- Identifier for the transaction category
    personal_finance_category_confidence_level VARCHAR(50), -- Confidence level of the personal finance category
    personal_finance_category_detailed VARCHAR(255), -- Detailed personal finance category
    personal_finance_category_primary VARCHAR(255), -- Primary personal finance category
    personal_finance_category_icon_url VARCHAR(255), -- URL of the personal finance category icon
    location_address VARCHAR(255), -- Address of the transaction location
    location_city VARCHAR(255), -- City of the transaction location
    location_region VARCHAR(50), -- Region/State of the transaction location
    location_postal_code VARCHAR(20), -- Postal code of the transaction location
    location_country VARCHAR(50), -- Country of the transaction location
    location_lat DECIMAL(10, 7), -- Latitude of the transaction location
    location_lon DECIMAL(10, 7), -- Longitude of the transaction location
    location_store_number VARCHAR(50), -- Store number of the transaction location
    payment_meta_reference_number VARCHAR(255), -- Reference number of the payment
    payment_meta_ppd_id VARCHAR(255), -- PPD ID of the payment
    payment_meta_payee VARCHAR(255), -- Payee of the payment
    payment_meta_by_order_of VARCHAR(255), -- By order of the payment
    payment_meta_payer VARCHAR(255), -- Payer of the payment
    payment_meta_payment_method VARCHAR(255), -- Payment method
    payment_meta_payment_processor VARCHAR(255), -- Payment processor
    payment_meta_reason VARCHAR(255), -- Reason for the payment
    website VARCHAR(255), -- Website of the merchant
    check_number VARCHAR(255), -- Check number, if applicable
    file_import_id INT, -- Identifier for the associated file import
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when the record was created
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Timestamp when the record was last updated
    INDEX (transaction_id), -- Index on the transaction_id column
    INDEX (account_id), -- Index on the account_id column
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
plaid_transaction_counterparties_history
    Table Description: Table to store historical transaction counterparty information from Plaid, capturing details such as names, types, websites, and contact information for past transactions.
Examples:
    id=1
    transaction_id='tx_123456'
    name='Amazon'
    type='merchant'
    website='http://amazon.com'
    logo_url='http://example.com/logo.png'
    confidence_level='high'
    entity_id='me_123456'
    phone_number='1-800-123-4567'
    file_import_id=1
*/
CREATE TABLE plaid_transaction_counterparties_history (
    id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the counterparty
    transaction_id VARCHAR(255), -- Identifier for the associated transaction
    name VARCHAR(255), -- Name of the counterparty
    type VARCHAR(50), -- Type of counterparty (e.g., 'merchant')
    website VARCHAR(255), -- Website of the counterparty
    logo_url VARCHAR(255), -- URL of the counterparty's logo
    confidence_level VARCHAR(50), -- Confidence level of the counterparty data
    entity_id VARCHAR(255), -- Identifier for the counterparty entity
    phone_number VARCHAR(50), -- Phone number of the counterparty
    file_import_id INT, -- Identifier for the associated file import
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key constraint
);

/*
categories
    Table Description: Table to store category information with hierarchical relationships.
Examples:
    category_id='10001000'
    category_group='special'
    hierarchy_level1='Bank Fees'
    hierarchy_level2='Overdraft'
*/
CREATE TABLE categories (
    category_id VARCHAR(8) NOT NULL PRIMARY KEY, -- Unique identifier for the category
    category_group VARCHAR(50) NOT NULL, -- Group name the category belongs to
    hierarchy_level1 VARCHAR(255), -- Level 1 hierarchy name
    hierarchy_level2 VARCHAR(255), -- Level 2 hierarchy name
    hierarchy_level3 VARCHAR(255) -- Level 3 hierarchy name
);

/*
asset_report
    Table Description: Table to store the asset report metadata.
Examples:
    asset_report_id='a04fa14e-03dc-4311-b3b3-0205d10dcf7d'
    client_report_id=NULL
    date_generated='2024-06-27 02:03:08'
    days_requested=60
    file_path='path/to/imported/file.json'
    json_file='{ "report": { ... } }'
    created_at='2024-06-27 02:03:08'
*/
CREATE TABLE asset_report (
    asset_report_id VARCHAR(50) PRIMARY KEY, -- Unique identifier for the asset report
    client_report_id VARCHAR(50), -- Client-provided identifier for the report
    date_generated DATETIME, -- Date and time when the report was generated
    days_requested INT, -- Number of days the report covers
    file_path VARCHAR(255), -- Name of the imported file
    json_file JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Timestamp when the record was created
);

/*
asset_item
    Table Description: Table to store items associated with the report.
Examples:
    item_id='AL6LmqjboJCLwoMqxyajT93O31b1eLc6mMLQr'
    institution_name='Tangerine - Personal'
    institution_id='ins_40'
    date_last_updated='2024-06-27 02:03:08'
    asset_report_id='a04fa14e-03dc-4311-b3b3-0205d10dcf7d'
*/
CREATE TABLE asset_item (
    item_id VARCHAR(50) PRIMARY KEY, -- Unique identifier for the item
    institution_name VARCHAR(100), -- Name of the financial institution
    institution_id VARCHAR(50), -- Identifier for the financial institution
    date_last_updated DATETIME, -- Date and time when the item was last updated
    asset_report_id VARCHAR(50), -- Identifier for the associated asset report
    FOREIGN KEY (asset_report_id) REFERENCES asset_report(asset_report_id) ON DELETE CASCADE
);

/*
asset_account
    Table Description: Table to store account details.
Examples:
    account_id='4OYOERLAkwIQdknYq7rMCXrRx5B0PpUJ9pj4m'
    name='Brazil'
    official_name='Tangerine Savings Account'
    mask='5661'
    available=100.53
    current=100.53
    limit=NULL
    margin_loan_amount=NULL
    iso_currency_code='CAD'
    unofficial_currency_code=NULL
    type='depository'
    subtype='savings'
    days_available=60
    item_id='AL6LmqjboJCLwoMqxyajT93O31b1eLc6mMLQr'
    asset_report_id='a04fa14e-03dc-4311-b3b3-0205d10dcf7d'
*/
CREATE TABLE asset_account (
    account_id VARCHAR(50) PRIMARY KEY, -- Unique identifier for the account
    name VARCHAR(50), -- Name of the account
    official_name VARCHAR(100), -- Official name of the account
    mask VARCHAR(10), -- Masked account number
    available DECIMAL(10,2), -- Available balance
    current DECIMAL(10,2), -- Current balance
    `limit` DECIMAL(10,2), -- Credit limit, if applicable
    margin_loan_amount DECIMAL(10,2), -- Margin loan amount, if applicable
    iso_currency_code VARCHAR(10), -- ISO currency code (e.g., 'CAD')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    type VARCHAR(50), -- Type of account (e.g., 'depository')
    subtype VARCHAR(50), -- Subtype of account (e.g., 'savings')
    days_available INT, -- Number of days the account data is available
    item_id VARCHAR(50), -- Identifier for the associated item
    asset_report_id VARCHAR(50), -- Identifier for the associated asset report
    FOREIGN KEY (asset_report_id) REFERENCES asset_report(asset_report_id) ON DELETE CASCADE
);

/*
asset_transaction
    Table Description: Table to store transaction details for each account.
Examples:
    transaction_id='bkykKdNx7bCLXmZBO81qTAxxY3NEDLuDwaaqX'
    account_id='4OYOERLAkwIQdknYq7rMCXrRx5B0PpUJ9pj4m'
    amount=-0.11
    iso_currency_code='CAD'
    unofficial_currency_code=NULL
    original_description='Interest Paid'
    date='2024-04-30'
    pending=FALSE
    asset_report_id='a04fa14e-03dc-4311-b3b3-0205d10dcf7d'
*/
CREATE TABLE asset_transaction (
    transaction_id VARCHAR(50) PRIMARY KEY, -- Unique identifier for the transaction
    account_id VARCHAR(50), -- Identifier for the associated account
    amount DECIMAL(10,2), -- Transaction amount
    iso_currency_code VARCHAR(10), -- ISO currency code (e.g., 'CAD')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    original_description VARCHAR(255), -- Original description of the transaction
    date DATE, -- Date of the transaction
    pending BOOLEAN, -- Whether the transaction is pending
    asset_report_id VARCHAR(50),  -- Identifier for the associated asset report
    FOREIGN KEY (asset_report_id) REFERENCES asset_report(asset_report_id) ON DELETE CASCADE
);

/*
asset_historical_balance
    Table Description: Table to store historical balance details for each account.
Examples:
    balance_id=1
    account_id='4OYOERLAkwIQdknYq7rMCXrRx5B0PpUJ9pj4m'
    date='2024-06-26'
    current=100.53
    iso_currency_code='CAD'
    unofficial_currency_code=NULL
    asset_report_id='a04fa14e-03dc-4311-b3b3-0205d10dcf7d'
*/
CREATE TABLE asset_historical_balance (
    balance_id INT AUTO_INCREMENT PRIMARY KEY, -- Unique identifier for the balance record
    account_id VARCHAR(50), -- Identifier for the associated account
    date DATE, -- Date of the balance record
    current DECIMAL(10,2), -- Current balance
    iso_currency_code VARCHAR(10), -- ISO currency code (e.g., 'CAD')
    unofficial_currency_code VARCHAR(10), -- Unofficial currency code, if any
    asset_report_id VARCHAR(50),  -- Identifier for the associated asset report
    FOREIGN KEY (asset_report_id) REFERENCES asset_report(asset_report_id) ON DELETE CASCADE
);

-- Table for inflow_streams
/*
inflow_streams
    Table Description: Stores information about incoming financial transactions including categories, amounts, and frequencies.
Examples:
    stream_id='KAkA9rbn1xTqbkBrp1wxS4EYx3KMBmCQn41ze'
    account_id='rDND7jznYEH6eXvNMo35t81a63z4e7faRMODd'
    description='EFT Deposit from COMPLYWORKS LTD'
    first_date='2022-07-07'
    last_date='2024-06-20'
*/
CREATE TABLE inflow_streams (
    stream_id VARCHAR(255) PRIMARY KEY, -- Unique identifier for the inflow stream
    account_id VARCHAR(255), -- Account associated with the stream
    category_id VARCHAR(255), -- Category identifier
    description TEXT, -- Description of the transaction
    merchant_name VARCHAR(255), -- Name of the merchant
    first_date DATE, -- First date of the transaction
    last_date DATE, -- Last date of the transaction
    frequency VARCHAR(50), -- Frequency of the transaction
    average_amount DECIMAL(10, 2), -- Average amount of the transaction
    last_amount DECIMAL(10, 2), -- Last amount of the transaction
    is_active BOOLEAN, -- Whether the stream is active
    status VARCHAR(50), -- Status of the stream
    is_user_modified BOOLEAN, -- Whether the stream was modified by the user
    last_user_modified_datetime DATETIME, -- Last user modification datetime
    pers_fin_primary_category VARCHAR(255), -- Personal finance primary category
    pers_fin_detailed_category VARCHAR(255), -- Personal finance detailed category
    pers_fin_confidence_level VARCHAR(50), -- Personal finance confidence level
    file_import_id INT, -- ID of the file import record
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key to file_import_tracker
);

-- Table for outflow_streams
/*
outflow_streams
    Table Description: Stores information about outgoing financial transactions including categories, amounts, and frequencies.
Examples:
    stream_id='M0v0Aa7XqxFjZmXayVL0f13Dk8OKeOSMD65y1'
    account_id='rDND7jznYEH6eXvNMo35t81a63z4e7faRMODd'
    description='Bill Payment - TRIANGLE MASTERCARD - ************4169'
    first_date='2022-07-22'
    last_date='2024-06-13'
*/
CREATE TABLE outflow_streams (
    stream_id VARCHAR(255) PRIMARY KEY, -- Unique identifier for the outflow stream
    account_id VARCHAR(255), -- Account associated with the stream
    category_id VARCHAR(255), -- Category identifier
    description TEXT, -- Description of the transaction
    merchant_name VARCHAR(255), -- Name of the merchant
    first_date DATE, -- First date of the transaction
    last_date DATE, -- Last date of the transaction
    frequency VARCHAR(50), -- Frequency of the transaction
    average_amount DECIMAL(10, 2), -- Average amount of the transaction
    last_amount DECIMAL(10, 2), -- Last amount of the transaction
    is_active BOOLEAN, -- Whether the stream is active
    status VARCHAR(50), -- Status of the stream
    is_user_modified BOOLEAN, -- Whether the stream was modified by the user
    last_user_modified_datetime DATETIME, -- Last user modification datetime
    pers_fin_primary_category VARCHAR(255), -- Personal finance primary category
    pers_fin_detailed_category VARCHAR(255), -- Personal finance detailed category
    pers_fin_confidence_level VARCHAR(50), -- Personal finance confidence level
    file_import_id INT, -- ID of the file import record
    FOREIGN KEY (file_import_id) REFERENCES file_import_tracker(id) ON DELETE CASCADE -- Foreign key to file_import_tracker
);

-- Table for transaction_ids related to inflow_streams
/*
inflow_transactions
    Table Description: Stores transaction IDs related to inflow streams.
Examples:
    transaction_id='M0v0Aa7XqxFjZmXayVL0fwXav1zm5YIpYokj9'
    stream_id='KAkA9rbn1xTqbkBrp1wxS4EYx3KMBmCQn41ze'
*/
CREATE TABLE inflow_transactions (
    transaction_id VARCHAR(255) PRIMARY KEY, -- Unique identifier for the transaction
    stream_id VARCHAR(255), -- Associated inflow stream
    FOREIGN KEY (stream_id) REFERENCES inflow_streams(stream_id) ON DELETE CASCADE -- Foreign key to inflow_streams
);

-- Table for transaction_ids related to outflow_streams
/*
outflow_transactions
    Table Description: Stores transaction IDs related to outflow streams.
Examples:
    transaction_id='8oYo1XqrjQfkJjPqXNRnh1wApbXEo3UvnDKXm'
    stream_id='M0v0Aa7XqxFjZmXayVL0f13Dk8OKeOSMD65y1'
*/
CREATE TABLE outflow_transactions (
    transaction_id VARCHAR(255) PRIMARY KEY, -- Unique identifier for the transaction
    stream_id VARCHAR(255), -- Associated outflow stream
    FOREIGN KEY (stream_id) REFERENCES outflow_streams(stream_id) ON DELETE CASCADE -- Foreign key to outflow_streams
);
