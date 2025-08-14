-- Step 1: Drop the old function
DROP FUNCTION IF EXISTS get_combined_report(text,text,text);

-- Step 2: Create the corrected function with matching data types
CREATE OR REPLACE FUNCTION get_combined_report(
    start_date TEXT,
    end_date TEXT,
    item_name_filter TEXT
)
RETURNS TABLE (
    "date" TIMESTAMPTZ,
    "itemName" TEXT,
    quantity INTEGER,
    "fromVendor" TEXT,
    "toBranch" TEXT,
    note_type TEXT
)
AS $$
BEGIN
    RETURN QUERY
    -- Outgoing Products
    SELECT
        it.created_at AS "date",
        p.name AS "itemName",
        -it.quantity_change AS quantity,
        NULL AS "fromVendor",
        it.to_branch_name AS "toBranch",
        'Out' AS note_type
    FROM
        inventory_transactions it
    JOIN products p ON it.product_id = p.id
    WHERE
        it.delivery_note_id IS NOT NULL
        AND it.type = 'out'
        AND it.created_at >= start_date::TIMESTAMPTZ
        AND it.created_at <= end_date::TIMESTAMPTZ
        AND (item_name_filter IS NULL OR p.name ILIKE '%' || item_name_filter || '%')

    UNION ALL

    -- Outgoing Consumables
    SELECT
        ct.created_at AS "date",
        c.name AS "itemName",
        -ct.quantity_change AS quantity,
        NULL AS "fromVendor",
        ct.branch_destination_name AS "toBranch",
        'Out' AS note_type
    FROM
        consumable_transactions ct
    JOIN consumables c ON ct.consumable_id = c.id
    WHERE
        ct.delivery_note_id IS NOT NULL
        AND ct.type = 'out'
        AND ct.created_at >= start_date::TIMESTAMPTZ
        AND ct.created_at <= end_date::TIMESTAMPTZ
        AND (item_name_filter IS NULL OR c.name ILIKE '%' || item_name_filter || '%')

    UNION ALL

    -- Incoming Products
    SELECT
        it.created_at AS "date",
        p.name AS "itemName",
        it.quantity_change AS quantity,
        idn.from_vendor_name AS "fromVendor",
        NULL AS "toBranch",
        'In' AS note_type
    FROM
        inventory_transactions it
    JOIN products p ON it.product_id = p.id
    LEFT JOIN incoming_delivery_notes idn ON it.incoming_delivery_note_id = idn.id
    WHERE
        it.type = 'in'
        AND it.created_at >= start_date::TIMESTAMPTZ
        AND it.created_at <= end_date::TIMESTAMPTZ
        AND (item_name_filter IS NULL OR p.name ILIKE '%' || item_name_filter || '%')

    UNION ALL

    -- Incoming Consumables
    SELECT
        ct.created_at AS "date",
        c.name AS "itemName",
        ct.quantity_change AS quantity,
        idn.from_vendor_name AS "fromVendor",
        NULL AS "toBranch",
        'In' AS note_type
    FROM
        consumable_transactions ct
    JOIN consumables c ON ct.consumable_id = c.id
    LEFT JOIN incoming_delivery_notes idn ON ct.incoming_delivery_note_id = idn.id
    WHERE
        ct.type = 'in'
        AND ct.created_at >= start_date::TIMESTAMPTZ
        AND ct.created_at <= end_date::TIMESTAMPTZ
        AND (item_name_filter IS NULL OR c.name ILIKE '%' || item_name_filter || '%');

END;
$$ LANGUAGE plpgsql;