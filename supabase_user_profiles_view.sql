
CREATE OR REPLACE VIEW public.user_profiles_view AS
SELECT
  p.id,
  p.role,
  p.branch_id,
  au.email
FROM
  public.profiles AS p
JOIN
  auth.users AS au ON p.id = au.id;

-- Grant permissions to authenticated users to select from this view
GRANT SELECT ON public.user_profiles_view TO authenticated;
