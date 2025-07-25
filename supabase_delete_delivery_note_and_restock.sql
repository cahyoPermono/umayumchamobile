
create or replace function public.delete_delivery_note_and_restock(p_delivery_note_id uuid)
returns void as $$
declare
  item record;
  v_branch_id uuid;
begin
  -- Get the branch_id from the delivery note
  select from_branch_id into v_branch_id from public.delivery_notes where id = p_delivery_note_id;

  -- If the delivery note doesn't exist, exit
  if not found then
    raise exception 'Delivery note with id % not found', p_delivery_note_id;
  end if;

  -- Loop through items and restock inventory
  for item in
    select product_id, quantity_change
    from public.inventory_transactions
    where delivery_note_id = p_delivery_note_id
  loop
    -- Add the quantity back to the branch_products table
    update public.branch_products
    set quantity = quantity - item.quantity_change
    where branch_id = v_branch_id and product_id = item.product_id;
  end loop;

  -- Loop through consumables transactions and restock inventory
  for item in
    select consumable_id, quantity_change
    from public.consumable_transactions
    where delivery_note_id = p_delivery_note_id
  loop
    -- Add the quantity back to the consumeable table
    update public.consumables
    set quantity = quantity - item.quantity_change
    where id = item.consumable_id;
  end loop;

  -- Delete the delivery note items
  delete from public.inventory_transactions where delivery_note_id = p_delivery_note_id;

  -- Delete the delivery note items consumeables
  delete from public.consumable_transactions where delivery_note_id = p_delivery_note_id;

  -- Delete the delivery note itself
  delete from public.delivery_notes where id = p_delivery_note_id;
end;
$$ language plpgsql security definer;

