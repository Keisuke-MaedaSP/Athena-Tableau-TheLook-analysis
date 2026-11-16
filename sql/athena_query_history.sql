--データベースの作成
create database thelook_bi;

--ordersテーブルの作成
create external table orders (
  order_id BIGINT,
  user_id BIGINT,
  status string,
  gender string,
  created_at TIMESTAMP,
  returned_at TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  num_of_item BIGINT
)
stored as parquet
location 's3://<YOUR_BUCKET>/processed/athena_source/orders/';

--ordersテーブルの読み込み確認
select order_id, created_at from orders limit 5;

--ordersテーブルの件数確認
select count(*) from orders;

--created_at列のマイクロ秒が0以外の値のAthenaでの処理の確認
select order_id, created_at from orders
where order_id = 77;

--order_itemsテーブルの作成
create external table order_items (
  id BIGINT,
  order_id BIGINT,
  user_id BIGINT,
  product_id BIGINT,
  inventory_item_id BIGINT,
  status STRING,
  created_at TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  returned_at TIMESTAMP,
  sale_price double
)
stored as parquet
location 's3://<YOUR_BUCKET>/athena_source/order_items/';

--order_itemsテーブルの読み込み確認
select order_id, created_at from orders limit 5;

--order_itemsテーブルの件数確認
select count(*) from order_items;

--productsテーブルの作成
create external table products (
  id BIGINT,
  cost double,
  category STRING,
  name STRING,
  brand STRING,
  retail_price double,
  department STRING,
  sku STRING,
  distribution_center_id BIGINT
)
stored as parquet
location 's3://<YOUR_BUCKET>/athena_source/products/';

--productsテーブルの読み込み確認
select id, name from products limit 5;

--productsテーブルの件数確認
select count(*) from products;

--productsのidに重複があるか確認
select id, count(*) from products
group by id
having count(*) >= 2;

--productsのidにNULLがあるか確認
select count(*) from products
where id is null;

--order_itemsとproductsの結合後にproductsのidにNULLがあるか確認
select count(*) as pr_id_null from order_items as oi
Left join products as pr
on oi.product_id = pr.id
where pr.id is null;

--ordersのorder_idに重複があるか確認
select order_id, count() from orders
group by order_id
having count() >= 2;

--ordersのorder_idにNULLがあるか確認
select count(*) from orders
where order_id is null;

--order_itemsとordersの結合後にordersのorder_idにNULLがあるか確認
select count(*) from order_items as oi
Left join orders as o
on oi.order_id = o.order_id
where o.order_id is null;

--order_items, orders, --order_itemsとproductsの結合
select oi.id,
  oi.order_id,
  o.created_at,
  pr.category,
  pr.brand
from order_items as oi
Left join products as pr
on oi.product_id = pr.id
Left join orders as o
on oi.order_id = o.order_id
limit 5;

--3テーブル結合後の件数確認
select count(*)
from order_items as oi
Left join products as pr
on oi.product_id = pr.id
Left join orders as o
on oi.order_id = o.order_id;

--order_itemsのstatusの種類確認
select status, count(*) from order_items
group by status;

--order_itemsのstatusがcompleteの件数、金額確認
select count(*), sum(sale_price) from order_items
where status = 'complete';

--order_itemsのstatusがcompleteのorder_idのユニーク数を確認
select count (distinct order_id) from order_items
where status = 'complete';

--order_itemsのstatusがcompleteの１注文当たりの平均売上金額
select 
  sum(sale_price) / count(distinct order_id) as avg_complete_sale_price
from order_items
where status = 'complete';

--注文数がNULLの場合も想定した平均売上金額のクエリ
select 
  sum(sale_price) / nullif(count(distinct order_id), 0) as avg_complete_sale_price
from order_items
where status = 'complete';

--条件に該当する注文がないときに平均がNULLとなるか確認
select 
  sum(sale_price) / nullif(count(distinct order_id), 0) as avg_complete_sale_price,
  count(distinct order_id) as unique_order_count
from order_items
where status = 'complete'
and 1 = 0;

--NULLIFの動きの確認
select nullif(0, 0) is null, nullif(5, 0);

--3テーブルを必要な列に絞って結合
select oi.id,
  oi.order_id,
  o.created_at,
  oi.sale_price,
  pr.category,
  pr.brand
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete';

--3テーブル結合後の販売金額合計とユニークなオーダーIDの確認
select
  count(distinct oi.order_id),
  sum(oi.sale_price)
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete';

--order_itemsのstatusがcompleteでsale_priceがNULLの件数確認
select count(*)
from order_items
where status = 'complete'
and sale_price is null;

--ordersとorder_itemsの結合後のcreated_atの欠損数確認
select count(*) from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.status = 'complete'
and o.created_at is null;

--結合後のcategory, brandに欠損があるか確認
select count(*) from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and (pr.category is null
or pr.brand is null);

--結合後のcategoryの欠損数を確認
select count(*) from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and pr.category is null;

--結合後のbrandの欠損数を確認
select count(*) from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and pr.brand is null;

--結合後のbrandの欠損数と販売金額を確認
select count(*), sum(oi.sale_price) from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and pr.brand is null;

--結合後のbrandの空文字、空白の数を確認
select count(*) from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and trim(pr.brand) = '';

--結合後のbrandの欠損を確認し、NULLの場合に「不明」とする
select pr.name,
  coalesce(pr.brand, '不明') 
from order_items as oi
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete'
and pr.brand is null;

--Tableau用結合データの取得
select oi.id,
  oi.order_id,
  o.created_at,
  oi.sale_price,
  pr.category,
  coalesce(pr.brand, '不明') as brand
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
left join products as pr
on oi.product_id = pr.id
where oi.status = 'complete';

--sale_priceの期間を考慮した集計、Tableauと一致するか確認
select sum(oi.sale_price)
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.status = 'complete'
and o.created_at >= TIMESTAMP '2022-05-01 00:00:00'
and o.created_at < TIMESTAMP '2022-06-01 00:00:00';

--2022年5月のユニークな購入者数、Tableauと一致するか確認
select count(distinct o.user_id)
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.status = 'complete'
and o.created_at >= TIMESTAMP '2022-05-01 00:00:00'
and o.created_at < TIMESTAMP '2022-06-01 00:00:00';

--2022年5月末の境界の注文者がいるか確認
select count(*)
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.status = 'complete'
and o.created_at > TIMESTAMP '2022-05-31 23:59:59'
and o.created_at < TIMESTAMP '2022-06-01 00:00:00';

--2022年5月のユニークな注文数、Tableauと一致するか確認
select count(distinct o.order_id)
from order_items as oi
left join orders as o
on oi.order_id = o.order_id
where oi.status = 'complete'
and o.created_at >= TIMESTAMP '2022-05-01 00:00:00'
and o.created_at < TIMESTAMP '2022-06-01 00:00:00';



































