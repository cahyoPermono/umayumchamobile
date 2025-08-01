DROP VIEW IF EXISTS public.consumable_transactions_with_user_email_view;

CREATE OR REPLACE VIEW public.consumable_transactions_with_user_email_view AS
SELECT
  ct.id,
  ct.consumable_id,
  ct.quantity_change,
  ct.type,
  ct.reason,
  ct.created_at,
  ct.user_id,
  ct.consumable_name,
  ct.branch_source_id,
  ct.branch_source_name,
  ct.branch_destination_id,
  ct.branch_destination_name,
  upv.email AS user_email
FROM
  public.consumable_transactions AS ct
LEFT JOIN
  public.user_profiles_view AS upv ON ct.user_id = upv.id;

-- Grant permissions to authenticated users to select from this view
GRANT SELECT ON public.consumable_transactions_with_user_email_view TO authenticated;