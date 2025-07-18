CREATE OR REPLACE VIEW public.consumable_transactions_with_user_email_view AS
SELECT
  ct.*,
  upv.email AS user_email
FROM
  public.consumable_transactions AS ct
JOIN
  public.user_profiles_view AS upv ON ct.user_id = upv.id;

-- Grant permissions to authenticated users to select from this view
GRANT SELECT ON public.consumable_transactions_with_user_email_view TO authenticated;