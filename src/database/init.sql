-- Database initialization script for Docker PostgreSQL
-- This script runs automatically when the container starts for the first time

-- Ensure we're using the correct database
\c webhook_payments;

-- Create the payment_events table
CREATE TABLE IF NOT EXISTS payment_events (
    id SERIAL PRIMARY KEY,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    payment_id VARCHAR(255) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payment_events_event_id ON payment_events(event_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_payment_id ON payment_events(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_event_type ON payment_events(event_type);
CREATE INDEX IF NOT EXISTS idx_payment_events_received_at ON payment_events(received_at);

-- Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_payment_events_updated_at 
    BEFORE UPDATE ON payment_events 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create a view for payment summaries (optional, for easier querying)
CREATE OR REPLACE VIEW payment_summary AS
SELECT 
    payment_id,
    COUNT(*) as total_events,
    MIN(received_at) as first_event_at,
    MAX(received_at) as last_event_at,
    ARRAY_AGG(DISTINCT event_type ORDER BY event_type) as event_types,
    (ARRAY_AGG(event_type ORDER BY received_at DESC))[1] as latest_event_type
FROM payment_events 
GROUP BY payment_id;

-- Insert some sample data for testing (optional)
-- You can comment this out if you don't want sample data
INSERT INTO payment_events (event_id, payment_id, event_type, payload) VALUES 
    ('sample_evt_001', 'sample_pay_001', 'payment_authorized', '{"sample": true, "amount": 1000}'),
    ('sample_evt_002', 'sample_pay_001', 'payment_captured', '{"sample": true, "amount": 1000, "captured": true}')
ON CONFLICT (event_id) DO NOTHING;

-- Grant necessary permissions (if needed)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO webhook_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO webhook_user;

-- Show table info
\dt payment_events;
\d payment_events;

-- Show sample data count
SELECT COUNT(*) as total_events FROM payment_events;

-- Success message
SELECT 'Database initialization completed successfully!' as status;
