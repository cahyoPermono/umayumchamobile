CREATE OR REPLACE VIEW distinct_to_branch_names AS
SELECT DISTINCT to_branch_name
FROM delivery_notes
WHERE to_branch_name IS NOT NULL AND to_branch_name != ''
ORDER BY to_branch_name ASC;