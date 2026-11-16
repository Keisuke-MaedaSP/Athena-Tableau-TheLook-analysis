-- Athena用テーブル作成例。実行前に <YOUR_BUCKET> と各LOCATIONを実際のS3保存先に置き換える。
-- 同名のデータベースやテーブルが存在する場合は、その状態を確認してから実行する。
CREATE DATABASE thelook_bi;

-- 以下はデータベース thelook_bi を選択して実行する。
CREATE EXTERNAL TABLE thelook_bi.orders (
  order_id BIGINT,
  user_id BIGINT,
  status STRING,
  gender STRING,
  created_at TIMESTAMP,
  returned_at TIMESTAMP,
  shipped_at TIMESTAMP,
  delivered_at TIMESTAMP,
  num_of_item BIGINT
)
STORED AS PARQUET
LOCATION 's3://<YOUR_BUCKET>/processed/athena_source/orders/';

CREATE EXTERNAL TABLE thelook_bi.order_items (
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
  sale_price DOUBLE
)
STORED AS PARQUET
LOCATION 's3://<YOUR_BUCKET>/processed/athena_source/order_items/';

CREATE EXTERNAL TABLE thelook_bi.products (
  id BIGINT,
  cost DOUBLE,
  category STRING,
  name STRING,
  brand STRING,
  retail_price DOUBLE,
  department STRING,
  sku STRING,
  distribution_center_id BIGINT
)
STORED AS PARQUET
LOCATION 's3://<YOUR_BUCKET>/processed/athena_source/products/';
