-- TASK 1 -DATA CLEANING & TRANSFORMATION
---------------------------------------------------

-- Review source tables
SELECT * FROM canales;
SELECT * FROM productos;
SELECT * FROM tiendas;
SELECT * FROM ventas;

-- Count total sales records
SELECT COUNT(*) FROM ventas;

-- Check for duplicates by key dimensions
SELECT COUNT(*) as conteo FROM ventas
GROUP BY id_tienda, id_prod, id_canal, fecha
HAVING conteo > 1;

-- Identify and inspect duplicates
WITH duplicados AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY id_tienda, id_prod, id_canal, fecha, cantidad, precio_oficial, precio_oferta
    ) AS row_num
  FROM ventas)
SELECT * FROM duplicados WHERE row_num > 1;

-- Aggregated version: grouping by date and key dimensions
CREATE TABLE ventas_agr AS 
SELECT STR_TO_DATE(fecha, '%d/%m/%Y') as fecha,
  id_prod, id_tienda, id_canal,
  SUM(cantidad) as cantidad,
  AVG(precio_oficial) as precio_oficial,
  AVG(precio_oferta) as precio_oferta,
  SUM(cantidad) * AVG(precio_oferta) as facturacion
FROM ventas
GROUP BY 1,2,3,4;

-- Review new aggregated table
SELECT * FROM ventas_agr;

-- TASK 2: DATABASE STRUCTURE
---------------------------------------------------

-- Add primary key and foreign keys to ventas_agr
ALTER TABLE ventas_agr ADD id_venta INT AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE ventas_agr 
  ADD FOREIGN KEY (id_prod) REFERENCES productos(id_prod) ON DELETE CASCADE,
  ADD FOREIGN KEY (id_tienda) REFERENCES tiendas(id_tienda) ON DELETE CASCADE,
  ADD FOREIGN KEY (id_canal) REFERENCES canales(id_canal) ON DELETE CASCADE;

-- Create a view with logical "order" grouping by date, store and channel
CREATE VIEW v_ventas_agr_pedido AS 
WITH maestro_pedidos AS (
  SELECT fecha, id_tienda, id_canal,
    ROW_NUMBER() OVER () as id_pedido
  FROM ventas_agr
  GROUP BY fecha, id_tienda, id_canal
)
SELECT v.id_venta, m.id_pedido, v.fecha, v.id_prod, v.id_tienda, v.id_canal,
  v.cantidad, v.precio_oficial, v.precio_oferta, v.facturacion
FROM ventas_agr v
LEFT JOIN maestro_pedidos m 
  ON v.fecha = m.fecha AND v.id_tienda = m.id_tienda AND v.id_canal = m.id_canal;

-- TASK 3 - BASIC KPIs & INSIGHTS
---------------------------------------------------

-- Number of orders
SELECT MAX(id_pedido) FROM v_ventas_agr_pedido;

-- Date range
SELECT MIN(fecha) AS first_day, MAX(fecha) AS last_day FROM ventas_agr;

-- Unique products
SELECT COUNT(DISTINCT id_prod) FROM productos;

-- Unique stores
SELECT COUNT(DISTINCT id_tienda) FROM tiendas;

-- Available sales channels
SELECT DISTINCT canal FROM canales;

-- Top 3 channels by revenue
SELECT c.canal, FORMAT(SUM(facturacion),0) as total_facturacion 
FROM ventas_agr v
JOIN canales c ON v.id_canal = c.id_canal
GROUP BY canal 
ORDER BY SUM(facturacion) DESC
LIMIT 3;

-- Monthly revenue evolution by channel (last 12 complete months)
SELECT MONTHNAME(fecha) as mes, c.canal, FORMAT(SUM(facturacion),0) as total_facturacion 
FROM ventas_agr v
JOIN canales c ON v.id_canal = c.id_canal
WHERE fecha BETWEEN '2017-06-30' AND '2018-06-30'
GROUP BY MONTHNAME(fecha), c.canal 
ORDER BY mes, canal;

-- Top 50 stores by total revenue
SELECT t.nombre_tienda, FORMAT(SUM(facturacion),0) as total_facturacion 
FROM ventas_agr v
JOIN tiendas t ON v.id_tienda = t.id_tienda
GROUP BY t.nombre_tienda 
ORDER BY SUM(facturacion) DESC
LIMIT 50;

-- Revenue evolution by country and quarter
SELECT YEAR(fecha) as year, QUARTER(fecha) as quarter, t.pais, FORMAT(SUM(facturacion),0) as total_facturacion 
FROM ventas_agr v
JOIN tiendas t ON v.id_tienda = t.id_tienda
GROUP BY t.pais, year, quarter
ORDER BY t.pais, year, quarter
LIMIT 50;

-- TASK 4 - ADVANCED PRODUCT ANALYSIS
---------------------------------------------------

-- Top 20 products with highest margin per line
WITH tabla_margen AS (
  SELECT *, ROUND(((precio - coste) / coste) * 100, 0) AS margen
  FROM productos
)
SELECT * FROM (
  SELECT id_prod, linea, producto, margen,
    ROW_NUMBER() OVER (PARTITION BY linea ORDER BY margen DESC) AS ranking
  FROM tabla_margen) AS ranking
WHERE ranking <= 20;

-- Identify outliers in discount (above 90th percentile)
WITH descuento AS (
  SELECT *, ROUND(((precio_oficial - precio_oferta) / precio_oficial) * 100, 2) as descuento
  FROM (
    SELECT id_prod, AVG(precio_oficial) as precio_oficial, AVG(precio_oferta) as precio_oferta
    FROM ventas_agr
    GROUP BY id_prod
  ) AS prod
)
SELECT * FROM (
  SELECT id_prod, descuento, ROUND(CUME_DIST() OVER (ORDER BY descuento) * 100, 2) as acum
  FROM descuento
) AS acumulados
WHERE acum >= 90;

-- Product coverage for 90% of revenue
CREATE VIEW facturacion_porcentual AS
WITH fact_prod_perc AS ( 
  WITH fac_prod AS (
    SELECT id_prod, SUM(facturacion) AS fact_prod
    FROM ventas_agr
    GROUP BY id_prod
  )
  SELECT *, ROUND((acumulado / total), 2) AS percent
  FROM (
    SELECT *, SUM(fact_prod) OVER (ORDER BY fact_prod DESC) AS acumulado,
      SUM(fact_prod) OVER () AS total
    FROM fac_prod
  ) AS per
)
SELECT * FROM fact_prod_perc
WHERE percent >= 0.9;

-- TASK 5 - CUSTOMER SEGMENTATION & POTENTIAL
---------------------------------------------------

-- Segment stores by #orders and revenue
CREATE VIEW v_matriz_segmentacion AS 
WITH pedidos_fact_tienda AS ( 
  SELECT id_tienda, COUNT(id_pedido) AS num_pedidos, SUM(facturacion) AS fact_tienda
  FROM v_ventas_agr_pedido
  GROUP BY id_tienda
),
medias AS (
  SELECT AVG(num_pedidos) AS avg_pedidos, AVG(fact_tienda) AS avg_fact
  FROM pedidos_fact_tienda
)
SELECT *,
  CASE
    WHEN num_pedidos <= avg_pedidos AND fact_tienda <= avg_fact THEN 'Low-Low'
    WHEN num_pedidos <= avg_pedidos AND fact_tienda > avg_fact THEN 'Low-High'
    WHEN num_pedidos > avg_pedidos AND fact_tienda <= avg_fact THEN 'High-Low'
    WHEN num_pedidos > avg_pedidos AND fact_tienda > avg_fact THEN 'High-High'
    ELSE 'Error'
  END AS segment
FROM pedidos_fact_tienda, medias;

-- Count clients per segment
SELECT segment, COUNT(*) FROM v_matriz_segmentacion GROUP BY segment;

-- Reactivation: identify inactive stores (>90 days)
WITH ult_fecha_total AS (
  SELECT MAX(fecha) AS ult_fecha_total FROM ventas_agr
),
ult_fecha_tienda AS (
  SELECT id_tienda, MAX(fecha) AS ult_fecha_tienda
  FROM ventas_agr
  GROUP BY id_tienda
)
SELECT *, DATEDIFF(ult_fecha_total, ult_fecha_tienda) AS dias_sin_compra
FROM ult_fecha_tienda, ult_fecha_total
WHERE DATEDIFF(ult_fecha_total, ult_fecha_tienda) > 90;

-- TASK 6 - ITEM-ITEM RECOMMENDER SYSTEM
---------------------------------------------------

-- Product pairs bought in same order
CREATE TABLE recomendador AS
SELECT v1.id_prod AS antecedente, v2.id_prod AS consecuente, COUNT(v1.id_pedido) AS frecuencia
FROM v_ventas_agr_pedido v1
INNER JOIN v_ventas_agr_pedido v2
  ON v1.id_pedido = v2.id_pedido
  AND v1.id_prod < v2.id_prod
GROUP BY v1.id_prod, v2.id_prod;

-- Recommend products to a specific store based on co-purchases
WITH input_cliente AS (
  SELECT DISTINCT id_prod, id_tienda
  FROM ventas_agr
  WHERE id_tienda = '1201'
),
productos_recomendados AS (
  SELECT consecuente, SUM(frecuencia) AS frecuencia
  FROM input_cliente c
  LEFT JOIN recomendador r ON c.id_prod = r.antecedente
  GROUP BY consecuente
)
SELECT consecuente AS recomendado, frecuencia
FROM productos_recomendados r
LEFT JOIN input_cliente c ON r.consecuente = c.id_prod
WHERE c.id_prod IS NULL
LIMIT 10;
