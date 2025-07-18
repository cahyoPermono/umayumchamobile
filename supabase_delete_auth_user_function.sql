CREATE OR REPLACE FUNCTION public.delete_auth_user(user_id uuid)
RETURNS void AS $$
BEGIN
  -- First, delete the profile from public.profiles
  DELETE FROM public.profiles WHERE id = user_id;

  -- Then, delete the user from auth.users
  DELETE FROM auth.users WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_auth_user(uuid) TO authenticated;