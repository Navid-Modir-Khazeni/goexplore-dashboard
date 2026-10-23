-- GoExplore: alle KPI-Views für das Dashboard
-- Voraussetzung: die Tabellen daily_sales, retailers, products, methods und externe_daten
-- sind im Dataset go_explore geladen (Spaltennamen mit Unterstrichen).
-- Projekt-ID (go-explore123) und Dataset (go_explore) bei Bedarf anpassen.
-- Die Reihenfolge ist wichtig: kpi_marktschaetzung baut auf kpi_land auf,
-- kpi_land_vergleich baut auf kpi_land und kpi_marktschaetzung_zusammenfassung auf.


-- 1. Umsatz je Land mit Einwohnern und BIP
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_land` AS
SELECT
  r.Country AS land,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  COUNT(*) AS anzahl_verkaeufe,
  COUNT(DISTINCT s.Retailer_code) AS anzahl_haendler,
  CAST(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), COUNT(DISTINCT s.Retailer_code)) AS NUMERIC) AS umsatz_pro_haendler,
  ANY_VALUE(e.Einwohner) AS einwohner,
  ANY_VALUE(e.BIP_Mrd_EUR) AS bip_mrd_eur,
  ROUND(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), ANY_VALUE(e.Einwohner)), 2) AS umsatz_pro_einwohner,
  ROUND(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), ANY_VALUE(e.BIP_Mrd_EUR)), 0) AS umsatz_pro_mrd_bip
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.retailers` AS r
  ON s.Retailer_code = r.Retailer_code
JOIN `go-explore123.go_explore.externe_daten` AS e
  ON r.Country = e.Land
GROUP BY r.Country
ORDER BY umsatz DESC;


-- 2. Kennzahlen je Händlertyp
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_haendlertyp` AS
SELECT
  r.Type AS haendlertyp,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  CAST(SUM((s.Unit_price - s.Unit_sale_price) * s.Quantity) AS NUMERIC) AS rabattbetrag,
  CAST(SUM(s.Unit_price * s.Quantity) AS NUMERIC) AS listenumsatz,
  ROUND(AVG(s.Unit_sale_price), 2) AS durchschnittspreis,
  COUNT(*) AS anzahl_verkaeufe,
  COUNT(DISTINCT s.Retailer_code) AS anzahl_haendler,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_price - s.Unit_sale_price) * s.Quantity), SUM(s.Unit_price * s.Quantity)), 4) AS rabatt_anteil,
  CAST(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), COUNT(*)) AS NUMERIC) AS durchschnittlicher_bestellwert,
  ROUND(SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT s.Retailer_code)), 2) AS verkaeufe_pro_haendler,
  CAST(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), COUNT(DISTINCT s.Retailer_code)) AS NUMERIC) AS umsatz_pro_haendler
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.retailers` AS r
  ON s.Retailer_code = r.Retailer_code
GROUP BY r.Type;


-- 3. Fachgeschäfte im Vergleich zu allgemeinen Geschäften
-- Einteilung ist eine Annahme, abgeleitet aus den Beispielen des CEO
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_geschaeftsart` AS
SELECT
  CASE
    WHEN r.Type IN ('Golf Shop', 'Eyewear Store') THEN 'Fachgeschäft'
    WHEN r.Type IN ('Sports Store', 'Outdoors Shop', 'Department Store', 'Warehouse Store') THEN 'Allgemeines Geschäft'
    WHEN r.Type = 'Direct Marketing' THEN 'Direktvertrieb'
    ELSE 'Sonstige'
  END AS geschaeftsart,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  COUNT(*) AS anzahl_verkaeufe,
  COUNT(DISTINCT s.Retailer_code) AS anzahl_haendler,
  ROUND(AVG(s.Unit_sale_price), 2) AS durchschnittspreis,
  CAST(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), COUNT(*)) AS NUMERIC) AS durchschnittlicher_bestellwert,
  ROUND(SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT s.Retailer_code)), 2) AS verkaeufe_pro_haendler,
  CAST(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), COUNT(DISTINCT s.Retailer_code)) AS NUMERIC) AS umsatz_pro_haendler,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_price - s.Unit_sale_price) * s.Quantity), SUM(s.Unit_price * s.Quantity)), 4) AS rabatt_anteil,
  CAST(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity) AS NUMERIC) AS bruttogewinn,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity), SUM(s.Quantity * s.Unit_sale_price)), 4) AS bruttomarge
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.retailers` AS r
  ON s.Retailer_code = r.Retailer_code
JOIN `go-explore123.go_explore.products` AS p
  ON s.Product_number = p.Product_number
GROUP BY geschaeftsart
ORDER BY umsatz DESC;


-- 4. Umsatz und Umsatzanteil je Bestellweg
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_bestellweg` AS
SELECT
  m.Order_method_type AS bestellweg,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  ROUND(SAFE_DIVIDE(SUM(s.Quantity * s.Unit_sale_price), SUM(SUM(s.Quantity * s.Unit_sale_price)) OVER ()), 4) AS umsatzanteil
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.methods` AS m
  ON s.Order_method_code = m.Order_method_code
GROUP BY m.Order_method_type
ORDER BY umsatz DESC;


-- 5. Umsatz, Bruttogewinn und Bruttomarge je Produktlinie
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_produktlinie` AS
SELECT
  p.Product_line AS produktlinie,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  CAST(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity) AS NUMERIC) AS bruttogewinn,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity), SUM(s.Quantity * s.Unit_sale_price)), 4) AS bruttomarge
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.products` AS p
  ON s.Product_number = p.Product_number
GROUP BY p.Product_line
ORDER BY umsatz DESC;


-- 6. Umsatz, Bruttogewinn und Bruttomarge je Produkt (mit Marke)
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_produkt` AS
SELECT
  p.Product AS produkt,
  p.Product_brand AS marke,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  CAST(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity) AS NUMERIC) AS bruttogewinn,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity), SUM(s.Quantity * s.Unit_sale_price)), 4) AS bruttomarge
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.products` AS p
  ON s.Product_number = p.Product_number
GROUP BY produkt, marke;


-- 7. Umsatz, Bruttogewinn und Bruttomarge je Marke
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_marke` AS
SELECT
  p.Product_brand AS marke,
  CAST(SUM(s.Quantity * s.Unit_sale_price) AS NUMERIC) AS umsatz,
  CAST(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity) AS NUMERIC) AS bruttogewinn,
  ROUND(SAFE_DIVIDE(SUM((s.Unit_sale_price - p.Unit_cost) * s.Quantity), SUM(s.Quantity * s.Unit_sale_price)), 4) AS bruttomarge
FROM `go-explore123.go_explore.daily_sales` AS s
JOIN `go-explore123.go_explore.products` AS p
  ON s.Product_number = p.Product_number
GROUP BY marke
ORDER BY bruttogewinn DESC;


-- 8. Umsatz pro Monat (Verlauf)
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_umsatz_monat` AS
SELECT
  DATE_TRUNC(Date, MONTH) AS monat,
  EXTRACT(YEAR FROM Date) AS jahr,
  EXTRACT(MONTH FROM Date) AS monat_nr,
  CAST(SUM(Quantity * Unit_sale_price) AS NUMERIC) AS umsatz
FROM `go-explore123.go_explore.daily_sales`
GROUP BY monat, jahr, monat_nr
ORDER BY monat;


-- 9. Umsatzwachstum ganzer Jahre (2018 ist nur ein Teiljahr und bleibt leer)
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_umsatzwachstum` AS
WITH jahresumsatz AS (
  SELECT
    EXTRACT(YEAR FROM Date) AS jahr,
    SUM(Quantity * Unit_sale_price) AS umsatz
  FROM `go-explore123.go_explore.daily_sales`
  GROUP BY jahr
)
SELECT
  jahr,
  CAST(umsatz AS NUMERIC) AS umsatz,
  IF(
    jahr = 2018,
    NULL,
    ROUND(SAFE_DIVIDE(umsatz - LAG(umsatz) OVER (ORDER BY jahr), LAG(umsatz) OVER (ORDER BY jahr)), 4)
  ) AS umsatzwachstum
FROM jahresumsatz
ORDER BY jahr;


-- 10. Umsatzwachstum im fairen Vergleich, nur Januar bis Juli
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_wachstum_janjul` AS
WITH jahresumsatz AS (
  SELECT
    EXTRACT(YEAR FROM Date) AS jahr,
    SUM(Quantity * Unit_sale_price) AS umsatz
  FROM `go-explore123.go_explore.daily_sales`
  WHERE EXTRACT(MONTH FROM Date) BETWEEN 1 AND 7
  GROUP BY jahr
)
SELECT
  jahr,
  CAST(umsatz AS NUMERIC) AS umsatz_jan_jul,
  ROUND(SAFE_DIVIDE(umsatz - LAG(umsatz) OVER (ORDER BY jahr), LAG(umsatz) OVER (ORDER BY jahr)), 4) AS wachstum
FROM jahresumsatz
ORDER BY jahr;


-- 11. Marktschätzung der Zielländer: jedes Zielland mit seinen Vergleichsländern
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_marktschaetzung` AS
WITH vergleich AS (
  SELECT 'Czech Republic' AS zielland, 'Germany' AS vergleichsland UNION ALL
  SELECT 'Czech Republic', 'Austria' UNION ALL
  SELECT 'Czech Republic', 'Sweden' UNION ALL
  SELECT 'Norway', 'Sweden' UNION ALL
  SELECT 'Norway', 'Finland' UNION ALL
  SELECT 'Norway', 'Denmark' UNION ALL
  SELECT 'Poland', 'Germany' UNION ALL
  SELECT 'Poland', 'Spain' UNION ALL
  SELECT 'Poland', 'Canada' UNION ALL
  SELECT 'Portugal', 'Spain' UNION ALL
  SELECT 'Portugal', 'Belgium' UNION ALL
  SELECT 'Portugal', 'Austria'
)
SELECT
  v.zielland,
  v.vergleichsland,
  ROUND(SAFE_DIVIDE(l.umsatz, l.einwohner) * z.Einwohner, 0) AS geschaetzter_umsatz_einwohner,
  ROUND(SAFE_DIVIDE(l.umsatz, l.bip_mrd_eur) * z.BIP_Mrd_EUR, 0) AS geschaetzter_umsatz_bip
FROM vergleich AS v
JOIN `go-explore123.go_explore.kpi_land` AS l
  ON l.land = v.vergleichsland
JOIN `go-explore123.go_explore.externe_daten` AS z
  ON z.Land = v.zielland
ORDER BY v.zielland, v.vergleichsland;


-- 12. Marktschätzung: Mittelwert und Spanne je Zielland
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_marktschaetzung_zusammenfassung` AS
SELECT
  zielland,
  ROUND(AVG(geschaetzter_umsatz_einwohner), 0) AS mittel_einwohner,
  MIN(geschaetzter_umsatz_einwohner) AS min_einwohner,
  MAX(geschaetzter_umsatz_einwohner) AS max_einwohner,
  ROUND(AVG(geschaetzter_umsatz_bip), 0) AS mittel_bip,
  MIN(geschaetzter_umsatz_bip) AS min_bip,
  MAX(geschaetzter_umsatz_bip) AS max_bip
FROM `go-explore123.go_explore.kpi_marktschaetzung`
GROUP BY zielland
ORDER BY zielland;


-- 13. Umsatz pro Einwohner: bestehende Länder (Ist-Wert) und Zielländer (Schätzung)
CREATE OR REPLACE VIEW `go-explore123.go_explore.kpi_land_vergleich` AS
WITH ist AS (
  SELECT
    land,
    'Ist-Wert' AS datenart,
    umsatz_pro_einwohner,
    umsatz,
    einwohner AS einwohner_ist
  FROM `go-explore123.go_explore.kpi_land`
),
schaetzung AS (
  SELECT
    m.zielland AS land,
    'Schätzung' AS datenart,
    ROUND(SAFE_DIVIDE(m.mittel_einwohner, e.Einwohner), 2) AS umsatz_pro_einwohner,
    CAST(NULL AS NUMERIC) AS umsatz,
    CAST(NULL AS INT64) AS einwohner_ist
  FROM `go-explore123.go_explore.kpi_marktschaetzung_zusammenfassung` AS m
  JOIN `go-explore123.go_explore.externe_daten` AS e
    ON e.Land = m.zielland
)
SELECT * FROM ist
UNION ALL
SELECT * FROM schaetzung;
