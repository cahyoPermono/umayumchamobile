
CREATE TABLE consumables (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  expired_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row update
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON consumables
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Enable Row Level Security
ALTER TABLE consumables ENABLE ROW LEVEL SECURITY;

-- Policies for consumables
CREATE POLICY "Allow authenticated users to view consumables" ON consumables
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to insert consumables" ON consumables
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to update consumables" ON consumables
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to delete consumables" ON consumables
  FOR DELETE USING (auth.role() = 'authenticated');

