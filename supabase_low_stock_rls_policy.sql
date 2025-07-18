
-- Drop the existing policy that restricts viewing for non-admins
DROP POLICY IF EXISTS "Users can view their assigned branch products or all if admin." ON public.branch_products;

-- Create a new policy to allow all authenticated users to view all branch products
CREATE POLICY "Allow authenticated users to view all branch products" ON public.branch_products
  FOR SELECT USING (auth.role() = 'authenticated');
