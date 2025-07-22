
-- Add the new column to the delivery_notes table
ALTER TABLE public.delivery_notes
ADD COLUMN dn_number TEXT;

-- Create a sequence for the delivery note number
CREATE SEQUENCE IF NOT EXISTS delivery_note_seq;

-- Create a function to generate the delivery note number
CREATE OR REPLACE FUNCTION generate_dn_number()
RETURNS TRIGGER AS $$
DECLARE
    new_id INTEGER;
    year_val TEXT;
    month_val TEXT;
BEGIN
    -- Get the next value from the sequence
    new_id := nextval('delivery_note_seq');

    -- Get the current year and month
    year_val := to_char(NEW.delivery_date, 'YYYY');
    month_val := to_char(NEW.delivery_date, 'MM');

    -- Format the new dn_number
    NEW.dn_number := 'GA/' || month_val || '/' || year_val || '/' || lpad(new_id::text, 4, '0');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function before insert
CREATE TRIGGER set_dn_number
BEFORE INSERT ON public.delivery_notes
FOR EACH ROW
EXECUTE FUNCTION generate_dn_number();
