CREATE OR REPLACE VIEW public.inventory_distinct_to_branch_names AS
SELECT DISTINCT to_branch_name
FROM public.inventory_transactions
WHERE to_branch_name IS NOT NULL;