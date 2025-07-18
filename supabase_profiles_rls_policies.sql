
-- Enable Row Level Security for profiles table if not already enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to view their own profile
CREATE POLICY "Users can view their own profile." ON public.profiles
  FOR SELECT USING ( auth.uid() = id );

-- Policy to allow admins to view all profiles
CREATE POLICY "Admins can view all profiles." ON public.profiles
  FOR SELECT USING ( get_my_role() = 'admin' );

-- Policy to allow admins to insert new profiles
CREATE POLICY "Admins can insert profiles." ON public.profiles
  FOR INSERT WITH CHECK ( get_my_role() = 'admin' );

-- Policy to allow admins to update profiles
CREATE POLICY "Admins can update profiles." ON public.profiles
  FOR UPDATE USING ( get_my_role() = 'admin' );

-- Policy to allow admins to delete profiles
CREATE POLICY "Admins can delete profiles." ON public.profiles
  FOR DELETE USING ( get_my_role() = 'admin' );
