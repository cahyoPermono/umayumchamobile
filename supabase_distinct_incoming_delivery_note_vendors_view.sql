CREATE OR REPLACE VIEW distinct_incoming_delivery_note_vendors AS
SELECT DISTINCT from_vendor_name
FROM incoming_delivery_notes
WHERE from_vendor_name IS NOT NULL AND from_vendor_name != '';