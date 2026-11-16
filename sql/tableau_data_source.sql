-- Tableau分析用：販売完了明細を基準に注文・商品情報を結合する
SELECT
    oi.id,
    oi.order_id,
    o.user_id,
    o.created_at,
    oi.sale_price,
    pr.category,
    COALESCE(pr.brand, '不明') AS brand
FROM thelook_bi.order_items AS oi
LEFT JOIN thelook_bi.orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN thelook_bi.products AS pr
    ON oi.product_id = pr.id
WHERE oi.status = 'complete'
