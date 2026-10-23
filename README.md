# GoExplore Dashboard

Dashboard-Projekt aus dem Data-Analytics-Bootcamp: Aufbau eines automatisierten Berichtssystems für den Outdoor-Ausrüster GoExplore mit Google Sheets, BigQuery und Data Studio.

**Autor:** Navid Modir Khazeni
**Dashboard:** Als PDF im Ordner `docs` (`GoExplore_Dashboard.pdf`)

## Ausgangslage

GoExplore ist ein schnell wachsender Anbieter für Camping- und Wanderausrüstung. Nachdem der einzige Data Scientist das Unternehmen verlassen hat, blieb nur eine einzige Excel-Datei übrig. Aufgabe war ein Dashboard, mit dem Management und Fachabteilungen selbstständig Erkenntnisse gewinnen können, ohne dass jedes Mal eine Analyse angefragt werden muss.

## Fragestellungen

Der CEO hat zwei Vorgaben gemacht:

1. **Europa-Abteilung:** Wie groß ist das Umsatzpotenzial in Tschechien, Norwegen, Polen und Portugal? Die Einschätzung beruht auf dem Vergleich mit Nachbarländern und Ländern ähnlicher Größe (Einwohnerzahl oder BIP), in denen GoExplore bereits aktiv ist.
2. **Retailer Connections:** Unterscheiden sich Fachgeschäfte (zum Beispiel Golfläden oder Optiker) von allgemeinen Geschäften (zum Beispiel Sport oder Outdoor)? Genannte Kennzahlen: durchschnittlicher Bestellwert, durchschnittlicher Produktpreis und Bestellungen pro Filiale.

Ich habe die Fragen um Anliegen weiterer Stakeholder ergänzt: CEO, Marketing sowie Product und Finance.

## Das Dashboard

Das Dashboard hat vier Seiten. Jeder Stakeholder hat eine Seite für seine Fragen, und über Filter kann er selbst auswählen, was er sehen möchte.

| Seite | Stakeholder | Leitfrage | Inhalt |
|---|---|---|---|
| Wachstumsanalyse | CEO | Wächst das Unternehmen? | Umsatz und Bruttogewinn im Jahresvergleich (Januar bis Juli), Wachstum zum Vorjahr, Umsatzverlauf pro Monat, Filter Jahr und Monat |
| Marktanalyse | Leiter Europa | Wie groß ist das Umsatzpotenzial in den vier Zielländern? | Erwarteter Umsatz nach Einwohnerzahl und nach BIP, Weltkarte mit Umsatz pro Einwohner, Filter Land |
| Händlertypen | Retailer Connections, Marketing | Unterscheiden sich Fachgeschäfte von allgemeinen Geschäften? Wo wird rabattiert, welche Bestellwege zählen? | Vier Vergleichsdiagramme nach Geschäftsart, Rabatt je Händlertyp, Umsatzanteil je Bestellweg, Kennzahlen mit Filter Händlertyp |
| Produktanalyse | Product und Finance | Welche Produkte und Produktlinien sind profitabel? | Bruttogewinn und Bruttomarge je Produktlinie, Top 10 Produkte und Top 10 Marken nach Bruttogewinn |

## Vorgehen

1. **Google Sheets:** Daten erkunden, Zusammenhänge der vier Tabellen verstehen, KPIs planen, erste Kennzahlen und Pivot-Tabellen berechnen. Die Ergebnisse dienten später als Kontrollwerte.
2. **BigQuery:** Die Rohdaten (unverändert) als Tabellen laden und alle Kennzahlen mit SQL berechnen. Jede Kennzahl liegt als View vor, also als gespeicherte Abfrage, die bei jedem Aufruf frisch aus den Rohdaten rechnet.
3. **Data Studio:** Das Dashboard liest direkt aus den BigQuery-Views. Kommen neue Verkaufsdaten dazu, aktualisiert sich das Dashboard ohne Handarbeit.

## Daten

| Tabelle | Inhalt |
|---|---|
| `daily_sales` | 149.257 Verkaufszeilen von Januar 2015 bis Juli 2018 |
| `retailers` | Händler mit Typ und Land |
| `products` | Produktkatalog mit Linie, Typ, Marke, Stückkosten und Listenpreis |
| `methods` | Bestellwege |
| `externe_daten` | Einwohner und BIP der 21 Länder mit Verkäufen und der vier Zielländer für das Jahr 2017 |

Die externen Daten stammen vom Internationalen Währungsfonds (Stand 2017). Die Einwohnerzahl wurde aus BIP und BIP pro Kopf abgeleitet. Das BIP wurde mit dem Jahresdurchschnittskurs 2017 (1 Euro entspricht 1,1297 US-Dollar) in Euro umgerechnet.

## KPIs

| KPI | Berechnung | View |
|---|---|---|
| Umsatz | Menge mal Verkaufspreis | in allen Views |
| Umsatzwachstum | (Umsatz Jahr minus Vorjahr) geteilt durch Umsatz Vorjahr, nur Januar bis Juli | `kpi_wachstum_janjul` |
| Durchschnittlicher Bestellwert | Umsatz geteilt durch Anzahl Verkäufe | `kpi_haendlertyp`, `kpi_geschaeftsart` |
| Durchschnittlicher Produktpreis | Mittelwert des Verkaufspreises | `kpi_haendlertyp`, `kpi_geschaeftsart` |
| Verkäufe pro Händler | Anzahl Verkäufe geteilt durch Anzahl Händler | `kpi_haendlertyp`, `kpi_geschaeftsart` |
| Umsatz pro Händler | Umsatz geteilt durch Anzahl Händler | `kpi_haendlertyp`, `kpi_land` |
| Rabatt in Prozent | Rabattbetrag geteilt durch Listenumsatz | `kpi_haendlertyp` |
| Bruttogewinn | (Verkaufspreis minus Stückkosten) mal Menge | `kpi_produktlinie`, `kpi_produkt`, `kpi_marke` |
| Bruttomarge | Bruttogewinn geteilt durch Umsatz | `kpi_produktlinie`, `kpi_geschaeftsart` |
| Umsatz pro Einwohner | Umsatz geteilt durch Einwohner | `kpi_land`, `kpi_land_vergleich` |
| Erwarteter Umsatz der Zielländer | Umsatz pro Einwohner (bzw. pro Mrd. Euro BIP) der Vergleichsländer mal Einwohner (bzw. BIP) des Ziellands | `kpi_marktschaetzung` |
| Umsatzanteil je Bestellweg | Umsatz des Bestellwegs geteilt durch Gesamtumsatz | `kpi_bestellweg` |

## Annahmen und Grenzen

1. In den Daten gibt es keine Bestellnummer. Eine Verkaufszeile zählt als eine Bestellung, und ein Händler gilt als eine Filiale.
2. Die Einteilung der Händlertypen ist eine Annahme, die ich aus den Beispielen des CEO abgeleitet habe. Fachgeschäfte sind Golf Shop und Eyewear Store, allgemeine Geschäfte sind Sports Store, Outdoors Shop, Department Store und Warehouse Store. Direct Marketing hat keine Filialen und wird in diesem Vergleich nicht berücksichtigt.
3. Die Marktschätzung zeigt das **Umsatzpotenzial von GoExplore** auf Basis vergleichbarer Länder und keine Gesamtmarktgröße. Vergleichsländer: Tschechien (Deutschland, Österreich, Schweden), Norwegen (Schweden, Finnland, Dänemark), Polen (Deutschland, Spanien, Kanada), Portugal (Spanien, Belgien, Österreich). Die Beträge gelten für den Zeitraum Januar 2015 bis Juli 2018.
4. Jeder Monat im Datensatz enthält nur etwa zehn Verkaufstage. Die Zahlen sind ein Ausschnitt, und alle Vergleiche gelten innerhalb dieses Datensatzes.
5. Der Jahresvergleich beschränkt sich auf Januar bis Juli, weil 2018 nur bis Juli vorliegt.
6. Der Bruttogewinn berücksichtigt nur die Stückkosten. Andere Kosten wie Logistik, Personal oder Marketing sind nicht enthalten.
7. Die Rohdaten wurden nicht bereinigt.

## Projektstruktur

```
GoExplore-Dashboard/
├── README.md
├── data/        Rohdaten als CSV (Spaltennamen mit Unterstrichen für BigQuery)
├── sql/         kpi_views.sql mit allen Views
└── docs/        KPI_Plan.pdf (Stakeholder, Fragen und KPIs) und GoExplore_Dashboard.pdf (das fertige Dashboard)
```

## Nachbauen

1. In BigQuery ein Dataset anlegen (bei mir `go_explore`) und die fünf CSV-Dateien aus `data/` als Tabellen hochladen (Auto detect, eine Kopfzeile überspringen).
2. In `sql/kpi_views.sql` die Projekt-ID anpassen (bei mir `go-explore123`) und das Skript ausführen. Es legt alle Views an.
3. In Data Studio einen Bericht anlegen und die Views als Datenquellen hinzufügen.

## Verwendete Werkzeuge

Google Sheets, Google BigQuery (SQL), Google Data Studio (Looker Studio)
