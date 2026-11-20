-- RDS PostgreSQL initialization script for Athena Federated Query demonstration
CREATE TABLE IF NOT EXISTS payment_transactions (
    transaction_id VARCHAR(64) PRIMARY KEY,
    order_id VARCHAR(64) NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(32) NOT NULL,
    payment_status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO payment_transactions (transaction_id, order_id, amount, payment_method, payment_status) VALUES
('TXN-8801', 'ORD-1001', 249.99, 'CREDIT_CARD', 'SUCCESS'),
('TXN-8802', 'ORD-1002', 89.50, 'DEBIT_CARD', 'SUCCESS'),
('TXN-8803', 'ORD-1003', 1250.00, 'WIRE_TRANSFER', 'SUCCESS'),
('TXN-8804', 'ORD-1004', 45.20, 'CREDIT_CARD', 'SUCCESS'),
('TXN-8805', 'ORD-1005', 320.75, 'PAYPAL', 'SUCCESS'),
('TXN-8806', 'ORD-1006', 610.00, 'CREDIT_CARD', 'PENDING'),
('TXN-8807', 'ORD-1007', 15.99, 'APPLE_PAY', 'SUCCESS'),
('TXN-8808', 'ORD-1008', 780.40, 'CREDIT_CARD', 'SUCCESS'),
('TXN-8809', 'ORD-1009', 99.00, 'CREDIT_CARD', 'FAILED'),
('TXN-8810', 'ORD-1010', 430.10, 'PAYPAL', 'SUCCESS')
ON CONFLICT (transaction_id) DO NOTHING;
