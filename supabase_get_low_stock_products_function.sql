CREATE OR REPLACE FUNCTION get_low_stock_products(p_branch_id uuid)
RETURNS TABLE (
    id uuid,
    product_id uuid,
    branch_id uuid,
    quantity integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    product_name text,
    product_code text,
    product_description text,
    product_merk text,
    product_kondisi text,
    product_tahun_perolehan text,
    product_nilai_residu double precision,
    product_pengguna text,
    product_price double precision,
    product_low_stock integer,
    branch_name text
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        bp.id,
        bp.product_id,
        bp.branch_id,
        bp.quantity,
        bp.created_at,
        p.updated_at,
        p.name AS product_name,
        p.code AS product_code,
        p.description AS product_description,
        p.merk AS product_merk,
        p.kondisi AS product_kondisi,
        p.tahun_perolehan AS product_tahun_perolehan,
        p.nilai_residu::double precision AS product_nilai_residu,
        p.pengguna AS product_pengguna,
        p.price::double precision AS product_price, -- Explicitly cast to double precision
        p.low_stock AS product_low_stock,
        b.name AS branch_name
    FROM
        branch_products bp
    JOIN
        products p ON bp.product_id = p.id
    JOIN
        branches b ON bp.branch_id = b.id
    WHERE
        bp.branch_id = p_branch_id AND bp.quantity < p.low_stock;
END;
$$;