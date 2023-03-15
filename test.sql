CREATE TABLE orders ( 
    `ts` TIMESTAMP(3) ,
    `orderId` INTEGER,
    `customer` STRING,
    `product` STRING,
    `price` DOUBLE NOT NULL,
    `quantity` DOUBLE NOT NULL,
    `total` DOUBLE NOT NULL,
    `channel` STRING,
    WATERMARK FOR ts AS ts                        
) WITH ( 
    'connector' = 'filesystem', 
    'path' = 'file:///test/data/orders.csv', 
    'format' = 'csv',
    'csv.field-delimiter' = ';'
);

CREATE TABLE cancellations ( 
  ts TIMESTAMP(3), 
  orderId INTEGER, 
  customer STRING, 
  channel STRING, 
  reason STRING, 
  WATERMARK FOR ts AS ts
) with ( 
    'connector' = 'filesystem', 
    'path' = 'file:///test/data/cancellations.csv', 
    'format' = 'csv',
    'csv.field-delimiter' = ';'
);

CREATE TEMPORARY VIEW largeOrders
  AS SELECT * FROM orders WHERE quantity>1000;

CREATE TEMPORARY VIEW smallOrders
  AS SELECT * FROM orders WHERE quantity < 100;

CREATE TEMPORARY VIEW largeCancellations AS
    SELECT cancellations.orderId, largeOrders.ts AS order_ts, cancellations.ts AS cancel_ts, largeOrders.product, largeOrders.customer, largeOrders.quantity AS cancel_quantity
    FROM largeOrders JOIN cancellations
    ON largeOrders.orderId = cancellations.orderId
    WHERE largeOrders.ts BETWEEN cancellations.ts - interval '4' day AND cancellations.ts;

-- Suspicious orders:
-- largeCancellations following small orders
-- product name and customerName to match
CREATE TEMPORARY VIEW suspiciousOrders AS
    SELECT s.orderId, s.customer, s.product, s.quantity AS order_quantity, l.cancel_quantity, l.order_ts AS large_ts, s.ts as small_ts, l.cancel_ts
    FROM smallOrders s JOIN largeCancellations l
    ON s.product = l.product AND s.customer = l.customer
    WHERE s.ts BETWEEN l.cancel_ts - interval '1' day AND l.cancel_ts;

CREATE TEMPORARY VIEW filteredResults AS
    SELECT * from suspiciousOrders WHERE small_ts > large_ts;

SET 'sql-client.execution.result-mode'='TABLEAU';
select * from suspiciousOrders;

-- This turns the final IntervalJoin into a regular Join. 
-- why? Is this safe? Is this a bug?

--- select * from filteredResults;

