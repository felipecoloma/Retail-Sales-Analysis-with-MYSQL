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

-- TASK 4 - PRODUCT ANALYSIS
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

-- TASK 5 - INVENTORY ANALYSIS 
---------------------------------------------------

-- Segment products by ABC category (A: top sellers, B: moderate, C: low)
ALTER TABLE productos
ADD COLUMN categoria_abc VARCHAR(25);

WITH cantidad_ventas_totales AS (
  SELECT 
    id_prod,
    SUM(cantidad) AS total_cantidad_vendida
  FROM ventas_agr
  GROUP BY id_prod
),
total_general AS (
  SELECT SUM(total_cantidad_vendida) AS total FROM cantidad_ventas_totales
),
ventas_con_porcentaje AS (
  SELECT 
    c.id_prod,
    c.total_cantidad_vendida,
    t.total AS total_general,
    SUM(c.total_cantidad_vendida) OVER (
      ORDER BY c.total_cantidad_vendida DESC
    ) AS acumulado,
    ROUND(
      SUM(c.total_cantidad_vendida) OVER (
        ORDER BY c.total_cantidad_vendida DESC
      ) / t.total, 4
    ) AS porcentaje_acumulado
  FROM cantidad_ventas_totales c
  CROSS JOIN total_general t
),
categorias_abc AS (
  SELECT
    p.id_prod,
    CASE
      WHEN v.porcentaje_acumulado <= 0.80 THEN 'A'
      WHEN v.porcentaje_acumulado <= 0.95 THEN 'B'
      WHEN v.porcentaje_acumulado > 0.95 THEN 'C'
      ELSE 'sin movimientos'
    END AS categoria_abc
  FROM productos p
  LEFT JOIN ventas_con_porcentaje v ON p.id_prod = v.id_prod
)
UPDATE productos p
JOIN categorias_abc c ON p.id_prod = c.id_prod
SET 
  p.categoria_abc = c.categoria_abc;

-- TASK 6 - RECOMMENDER STOCK MINIMUN 
---------------------------------------------------

-- Calculate recommended minimum stock level using demand and variability

ALTER TABLE productos
ADD COLUMN stock_minimo INT;

WITH ventas_diarias AS (
  SELECT 
    id_prod,
    fecha,
    SUM(cantidad) AS cantidad_dia
  FROM ventas_agr
  GROUP BY id_prod, fecha
),
estadisticas_ventas AS (
  SELECT 
    id_prod,
    AVG(cantidad_dia) AS demanda_promedio_diaria,
    STDDEV_POP(cantidad_dia) AS desviacion_ventas
  FROM ventas_diarias
  GROUP BY id_prod
)
, stock_minimo_calc AS (
  SELECT 
    id_prod,
    CEIL(demanda_promedio_diaria * 5 + 1.65 * desviacion_ventas * SQRT(5)) AS stock_minimo_estimado
  FROM estadisticas_ventas
)
UPDATE productos p
JOIN stock_minimo_calc s ON p.id_prod = s.id_prod
SET p.stock_minimo = s.stock_minimo_estimado;
