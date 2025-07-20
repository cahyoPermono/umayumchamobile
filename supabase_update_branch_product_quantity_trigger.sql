create or replace function public.update_branch_product_quantity()
returns trigger as $$
begin
  -- For 'out' transactions, decrease stock from the 'from_branch_id'
  if new.type = 'out' and new.from_branch_id is not null then
    update public.branch_products
    set quantity = quantity + new.quantity_change -- new.quantity_change is now negative
    where branch_id = new.from_branch_id and product_id = new.product_id;
  end if;

  -- For 'in' transactions, increase stock in the 'to_branch_id'
  if new.type = 'in' and new.to_branch_id is not null then
    -- Check if the product already exists in the branch
    if exists (
      select 1 from public.branch_products
      where branch_id = new.to_branch_id and product_id = new.product_id
    ) then
      -- If it exists, update the quantity
      update public.branch_products
      set quantity = quantity + new.quantity_change -- new.quantity_change is now positive
      where branch_id = new.to_branch_id and product_id = new.product_id;
    else
      -- If it doesn't exist, insert a new record
      insert into public.branch_products (branch_id, product_id, quantity)
      values (new.to_branch_id, new.product_id, new.quantity_change);
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer;