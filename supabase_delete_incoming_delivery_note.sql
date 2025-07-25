
create or replace function public.delete_incoming_delivery_note_and_reverse_stock(p_incoming_delivery_note_id uuid)
returns void as $$
declare
  inv_item record;
  cons_item record;
begin
  -- Reverse inventory stock for products
  for inv_item in
    select product_id, quantity_change, to_branch_id
    from public.inventory_transactions
    where incoming_delivery_note_id = p_incoming_delivery_note_id
  loop
    update public.branch_products
    set quantity = quantity - inv_item.quantity_change
    where branch_id = inv_item.to_branch_id and product_id = inv_item.product_id;
  end loop;

  -- Reverse stock for consumables
  for cons_item in
    select consumable_id, quantity_change
    from public.consumable_transactions
    where incoming_delivery_note_id = p_incoming_delivery_note_id
  loop
    update public.consumables
    set quantity = quantity - cons_item.quantity_change
    where id = cons_item.consumable_id;
  end loop;

  -- Delete the inventory transactions
  delete from public.inventory_transactions where incoming_delivery_note_id = p_incoming_delivery_note_id;

  -- Delete the consumable transactions
  delete from public.consumable_transactions where incoming_delivery_note_id = p_incoming_delivery_note_id;

  -- Delete the incoming delivery note itself
  delete from public.incoming_delivery_notes where id = p_incoming_delivery_note_id;
end;
$$ language plpgsql security definer;
