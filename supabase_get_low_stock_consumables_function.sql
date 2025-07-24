CREATE OR REPLACE FUNCTION get_low_stock_consumables()
RETURNS TABLE (
    id integer,
    code text,
    name text,
    quantity integer,
    description text,
    expired_date timestamp with time zone,
    low_stock integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    updated_by uuid
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.code,
        c.name,
        c.quantity,
        c.description,
        CASE
            WHEN c.expired_date IS NOT NULL THEN c.expired_date::text::timestamp with time zone -- Cast to text then to timestamp
            ELSE NULL
        END AS expired_date,
        c.low_stock,
        c.created_at,
        c.updated_at,
        c.updated_by
    FROM
        consumables c
    WHERE
        c.quantity < c.low_stock;
END;
$$;