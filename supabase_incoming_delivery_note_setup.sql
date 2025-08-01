-- Create incoming_delivery_notes table first
CREATE TABLE public.incoming_delivery_notes (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    from_vendor_name text NULL, -- Free text for vendor name
    delivery_date timestamp with time zone NOT NULL,
    to_branch_id uuid NOT NULL,
    to_branch_name text NOT NULL,
    keterangan text NULL,
    CONSTRAINT incoming_delivery_notes_pkey PRIMARY KEY (id),
    CONSTRAINT incoming_delivery_notes_to_branch_id_fkey FOREIGN KEY (to_branch_id) REFERENCES public.branches(id) ON DELETE NO ACTION
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.incoming_delivery_notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Enable read access for all users" ON public.incoming_delivery_notes FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON public.incoming_delivery_notes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Enable update for authenticated users" ON public.incoming_delivery_notes FOR UPDATE USING (true);
CREATE POLICY "Enable delete for authenticated users" ON public.incoming_delivery_notes FOR DELETE USING (true);

-- Now, add incoming_delivery_note_id to inventory_transactions and consumable_transactions
ALTER TABLE public.inventory_transactions
ADD COLUMN incoming_delivery_note_id uuid NULL;

ALTER TABLE public.inventory_transactions
ADD CONSTRAINT inventory_transactions_incoming_delivery_note_id_fkey
FOREIGN KEY (incoming_delivery_note_id) REFERENCES public.incoming_delivery_notes(id) ON DELETE NO ACTION;

ALTER TABLE public.consumable_transactions
ADD COLUMN incoming_delivery_note_id uuid NULL;

ALTER TABLE public.consumable_transactions
ADD CONSTRAINT consumable_transactions_incoming_delivery_note_id_fkey
FOREIGN KEY (incoming_delivery_note_id) REFERENCES public.incoming_delivery_notes(id) ON DELETE NO ACTION;

-- Create create_incoming_delivery_note_and_transactions RPC function
CREATE OR REPLACE FUNCTION public.create_incoming_delivery_note_and_transactions(
    p_from_vendor_name text,
    p_delivery_date timestamp with time zone,
    p_to_branch_id uuid,
    p_to_branch_name text,
    p_keterangan text,
    p_items jsonb -- Array of {id, name, quantity, type, description}
)
RETURNS uuid
LANGUAGE plpgsql
AS $function$
DECLARE
    v_incoming_delivery_note_id uuid;
    item_data jsonb;
    v_product_id uuid;
    v_consumable_id int;
    v_quantity_change int;
    v_item_type text;
    v_item_name text;
    v_reason text;
BEGIN
    -- 1. Create the incoming delivery note entry
    INSERT INTO public.incoming_delivery_notes (
        from_vendor_name,
        delivery_date,
        to_branch_id,
        to_branch_name,
        keterangan
    )
    VALUES (
        p_from_vendor_name,
        p_delivery_date,
        p_to_branch_id,
        p_to_branch_name,
        p_keterangan
    )
    RETURNING id INTO v_incoming_delivery_note_id;

    -- 2. Create transactions for each item and update stock
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_item_type := item_data->>'type';
        v_quantity_change := (item_data->>'quantity')::int;
        v_item_name := item_data->>'name';
        v_reason := item_data->>'description'; -- Use 'description' from frontend as 'reason'

        IF v_item_type = 'product' THEN
            v_product_id := (item_data->>'id')::uuid;

            -- Insert into existing inventory_transactions table with type 'in'
            INSERT INTO public.inventory_transactions (
                product_id,
                product_name,
                quantity_change,
                reason,
                type, -- Set type to 'in'
                incoming_delivery_note_id, -- Link to incoming delivery note
                to_branch_id, -- The branch receiving the product
                to_branch_name -- The name of the branch receiving the product
            )
            VALUES (
                v_product_id,
                v_item_name,
                v_quantity_change,
                v_reason,
                'in',
                v_incoming_delivery_note_id,
                p_to_branch_id,
                p_to_branch_name
            );

            -- Update branch_products quantity (add quantity)
            INSERT INTO public.branch_products (branch_id, product_id, quantity)
            VALUES (p_to_branch_id, v_product_id, v_quantity_change)
            ON CONFLICT (branch_id, product_id) DO UPDATE
            SET quantity = branch_products.quantity + EXCLUDED.quantity;

        ELSIF v_item_type = 'consumable' THEN
            v_consumable_id := (item_data->>'id')::int;

            -- Insert into existing consumable_transactions table with type 'in'
            INSERT INTO public.consumable_transactions (
                consumable_id,
                consumable_name,
                quantity_change,
                reason,
                type, -- Set type to 'in'
                incoming_delivery_note_id, -- Link to incoming delivery note
                branch_destination_id, -- Use existing column
                branch_destination_name -- Use existing column
            )
            VALUES (
                v_consumable_id,
                v_item_name,
                v_quantity_change,
                v_reason,
                'in',
                v_incoming_delivery_note_id,
                p_to_branch_id, -- This is the branch receiving the consumable
                p_to_branch_name -- This is the name of the branch receiving the consumable
            );

            -- Update consumables quantity (add quantity)
            UPDATE public.consumables
            SET quantity = quantity + v_quantity_change
            WHERE id = v_consumable_id;
        END IF;
    END LOOP;

    RETURN v_incoming_delivery_note_id;
END;
$function$;

-- Create delete_incoming_delivery_note_and_reverse_stock RPC function
CREATE OR REPLACE FUNCTION public.delete_incoming_delivery_note_and_reverse_stock(
    p_incoming_delivery_note_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    r record;
    v_to_branch_id uuid;
    v_to_branch_name text;
BEGIN
    -- Get branch info from the incoming delivery note
    SELECT to_branch_id, to_branch_name INTO v_to_branch_id, v_to_branch_name
    FROM public.incoming_delivery_notes
    WHERE id = p_incoming_delivery_note_id;

    -- Reverse product transactions
    FOR r IN SELECT * FROM public.inventory_transactions
             WHERE incoming_delivery_note_id = p_incoming_delivery_note_id
    LOOP
        UPDATE public.branch_products
        SET quantity = quantity - r.quantity_change
        WHERE branch_id = v_to_branch_id AND product_id = r.product_id;

        INSERT INTO public.inventory_transactions (
            product_id,
            product_name,
            quantity_change,
            reason,
            type,
            from_branch_id,
            to_branch_id,
            from_branch_name,
            to_branch_name
        )
        VALUES (
            r.product_id,
            r.product_name,
            -1 * r.quantity_change,
            'Reversal of Incoming DN: ' || r.reason,
            'out',
            v_to_branch_id,
            NULL,
            v_to_branch_name,
            NULL
        );
    END LOOP;

    DELETE FROM public.inventory_transactions
    WHERE incoming_delivery_note_id = p_incoming_delivery_note_id;

    -- Reverse consumable transactions
    FOR r IN SELECT * FROM public.consumable_transactions
             WHERE incoming_delivery_note_id = p_incoming_delivery_note_id
    LOOP
        UPDATE public.consumables
        SET quantity = quantity - r.quantity_change
        WHERE id = r.consumable_id;

        INSERT INTO public.consumable_transactions (
            consumable_id,
            consumable_name,
            quantity_change,
            reason,
            type,
            branch_destination_id,
            branch_destination_name,
            delivery_note_id
        )
        VALUES (
            r.consumable_id,
            r.consumable_name,
            -1 * r.quantity_change,
            'Reversal of Incoming DN: ' || r.reason,
            'out',
            v_to_branch_id,
            v_to_branch_name,
            NULL
        );
    END LOOP;

    DELETE FROM public.consumable_transactions
    WHERE incoming_delivery_note_id = p_incoming_delivery_note_id;

    DELETE FROM public.incoming_delivery_notes
    WHERE id = p_incoming_delivery_note_id;
END;
$function$;



-- New RPC function for updating incoming delivery notes
CREATE OR REPLACE FUNCTION public.update_incoming_delivery_note_and_transactions(
    p_incoming_delivery_note_id uuid,
    p_from_vendor_name text,
    p_delivery_date timestamp with time zone,
    p_to_branch_id uuid,
    p_to_branch_name text,
    p_keterangan text,
    p_new_items jsonb, -- New list of items
    p_original_items jsonb -- Original list of items for reversal
)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
    item_data jsonb;
    v_product_id uuid;
    v_consumable_id int;
    v_quantity_change int;
    v_item_type text;
    v_item_name text;
    v_reason text;
BEGIN
    -- 1. Reverse stock for all original items.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_original_items)
    LOOP
        v_item_type := item_data->>'type';
        v_quantity_change := (item_data->>'quantity_change')::int;

        IF v_item_type = 'product' THEN
            v_product_id := (item_data->>'product_id')::uuid;
            -- Subtract original quantity from branch_products
            UPDATE public.branch_products
            SET quantity = quantity - v_quantity_change
            WHERE branch_id = p_to_branch_id AND product_id = v_product_id;

        ELSIF v_item_type = 'consumable' THEN
            v_consumable_id := (item_data->>'consumable_id')::int;
            -- Subtract original quantity from consumables
            UPDATE public.consumables
            SET quantity = quantity - v_quantity_change
            WHERE id = v_consumable_id;
        END IF;
    END LOOP;

    -- 2. Unlink the old transactions by setting their foreign key to NULL.
    UPDATE public.inventory_transactions
    SET incoming_delivery_note_id = NULL
    WHERE incoming_delivery_note_id = p_incoming_delivery_note_id;

    UPDATE public.consumable_transactions
    SET incoming_delivery_note_id = NULL
    WHERE incoming_delivery_note_id = p_incoming_delivery_note_id;

    -- 3. Update the incoming_delivery_notes entry itself.
    UPDATE public.incoming_delivery_notes
    SET
        from_vendor_name = p_from_vendor_name,
        delivery_date = p_delivery_date,
        to_branch_id = p_to_branch_id,
        to_branch_name = p_to_branch_name,
        keterangan = p_keterangan
    WHERE id = p_incoming_delivery_note_id;

    -- 4. Create new 'in' transactions for the updated items and update stock.
    FOR item_data IN SELECT * FROM jsonb_array_elements(p_new_items)
    LOOP
        v_item_type := item_data->>'type';
        v_quantity_change := (item_data->>'quantity')::int;
        v_item_name := item_data->>'name';
        v_reason := item_data->>'description';

        IF v_item_type = 'product' THEN
            v_product_id := (item_data->>'id')::uuid;

            -- Insert new inventory transaction
            INSERT INTO public.inventory_transactions (
                product_id, product_name, quantity_change, reason, type,
                incoming_delivery_note_id, to_branch_id, to_branch_name
            )
            VALUES (
                v_product_id, v_item_name, v_quantity_change, v_reason, 'in',
                p_incoming_delivery_note_id, p_to_branch_id, p_to_branch_name
            );

            -- Update branch_products quantity
            INSERT INTO public.branch_products (branch_id, product_id, quantity)
            VALUES (p_to_branch_id, v_product_id, v_quantity_change)
            ON CONFLICT (branch_id, product_id) DO UPDATE
            SET quantity = branch_products.quantity + EXCLUDED.quantity;

        ELSIF v_item_type = 'consumable' THEN
            v_consumable_id := (item_data->>'id')::int;

            -- Insert new consumable transaction
            INSERT INTO public.consumable_transactions (
                consumable_id, consumable_name, quantity_change, reason, type,
                incoming_delivery_note_id, branch_destination_id, branch_destination_name
            )
            VALUES (
                v_consumable_id, v_item_name, v_quantity_change, v_reason, 'in',
                p_incoming_delivery_note_id, p_to_branch_id, p_to_branch_name
            );

            -- Update consumables quantity
            UPDATE public.consumables
            SET quantity = quantity + v_quantity_change
            WHERE id = v_consumable_id;
        END IF;
    END LOOP;
END;
$function$;