CREATE OR REPLACE VIEW distinct_product_vendors AS
SELECT DISTINCT "from"
FROM products
WHERE "from" IS NOT NULL AND "from" != '';