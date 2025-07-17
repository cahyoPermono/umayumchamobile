
CREATE TABLE consumable_transactions (
  id SERIAL PRIMARY KEY,
  consumable_id INTEGER NOT NULL REFERENCES consumables(id) ON DELETE CASCADE,
  quantity_change INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('in', 'out')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) DEFAULT auth.uid()
);

-- Enable Row Level Security
ALTER TABLE consumable_transactions ENABLE ROW LEVEL SECURITY;

-- Policies for consumable_transactions
CREATE POLICY "Allow authenticated users to view transactions" ON consumable_transactions
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert transactions" ON consumable_transactions
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Function to update consumable quantity from transaction
CREATE OR REPLACE FUNCTION update_consumable_quantity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE consumables
  SET quantity = quantity + NEW.quantity_change
  WHERE id = NEW.consumable_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update quantity on new transaction
CREATE TRIGGER on_consumable_transaction_created
  AFTER INSERT ON consumable_transactions
  FOR EACH ROW
  EXECUTE PROCEDURE update_consumable_quantity();
