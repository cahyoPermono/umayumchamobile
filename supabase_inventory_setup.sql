-- Helper function to get the role of the currently logged-in user.
-- This is needed for our security policies.
create or replace function get_my_role()
returns text as $$
begin
  return (
    select role from public.profiles where id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- 1. PRODUCTS TABLE (Master Inventory)
-- This table stores the master list of all your dimsum products.
create table public.products (
  id uuid not null primary key default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  name text not null,
  description text,
  sku text unique,
  quantity integer not null default 0,
  user_id uuid references auth.users(id)
);

-- Security policies for products table
alter table public.products enable row level security;
create policy "Authenticated users can view products." on public.products for select using ( auth.role() = 'authenticated' );
create policy "Admins can insert products." on public.products for insert with check ( get_my_role() = 'admin' );
create policy "Admins can update products." on public.products for update using ( get_my_role() = 'admin' );
create policy "Admins can delete products." on public.products for delete using ( get_my_role() = 'admin' );


-- 2. DELIVERY NOTES TABLE (Surat Jalan)
-- This table stores information for each delivery note.
create table public.delivery_notes (
  id uuid not null primary key default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  customer_name text not null,
  destination_address text,
  delivery_date date not null default now(),
  user_id uuid references auth.users(id) default auth.uid()
);

-- Security policies for delivery_notes table
alter table public.delivery_notes enable row level security;
create policy "Users can view their own delivery notes." on public.delivery_notes for select using ( auth.uid() = user_id );
create policy "Admins can view all delivery notes." on public.delivery_notes for select using ( get_my_role() = 'admin' );
create policy "Users can create delivery notes." on public.delivery_notes for insert with check ( auth.uid() = user_id );
create policy "Admins can update delivery notes." on public.delivery_notes for update using ( get_my_role() = 'admin' );
create policy "Admins can delete delivery notes." on public.delivery_notes for delete using ( get_my_role() = 'admin' );


-- 3. INVENTORY TRANSACTIONS TABLE
-- This table logs every stock movement (in or out).
create table public.inventory_transactions (
  id uuid not null primary key default gen_random_uuid(),
  created_at timestamp with time zone not null default now(),
  product_id uuid references public.products(id) on delete set null,
  type text not null check (type in ('in', 'out')),
  quantity_change integer not null,
  reason text,
  delivery_note_id uuid references public.delivery_notes(id) on delete set null,
  product_name text,
  from_branch_name text,
  to_branch_name text,
  user_id uuid references auth.users(id) default auth.uid()
);

-- Security policies for inventory_transactions table
alter table public.inventory_transactions enable row level security;
create policy "Authenticated users can view transactions." on public.inventory_transactions for select using ( auth.role() = 'authenticated' );
create policy "Authenticated users can create transactions." on public.inventory_transactions for insert with check ( auth.role() = 'authenticated' );
create policy "Admins can update transactions." on public.inventory_transactions for update using ( get_my_role() = 'admin' );
create policy "Admins can delete transactions." on public.inventory_transactions for delete using ( get_my_role() = 'admin' );


-- 4. FUNCTION AND TRIGGER
-- This automatically updates the master stock in the 'products' table
-- every time a new transaction is added.
create or replace function public.update_product_quantity()
returns trigger as $$
declare
  quantity_to_update int;
begin
  -- Ensure 'out' transactions have a negative quantity_change, and 'in' are positive.
  if new.type = 'out' then
    quantity_to_update := -abs(new.quantity_change);
  else
    quantity_to_update := abs(new.quantity_change);
  end if;

  -- Update the quantity in the products table
  update public.products
  set quantity = quantity + quantity_to_update
  where id = new.product_id;

  return new;
end;
$$ language plpgsql security definer;

-- Attach the trigger to the transactions table
create trigger on_inventory_transaction_created
  after insert on public.inventory_transactions
  for each row execute procedure public.update_product_quantity();
