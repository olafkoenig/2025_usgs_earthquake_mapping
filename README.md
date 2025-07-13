# USGS Earthquake Data Downloader & Geospatial Analyzer

This Jupyter notebook automates the retrieval and geospatial processing of earthquake data and products from the USGS Earthquake Catalog and ShakeMap APIs.  
**Ultimate goal:** Prepare clean datasets and geodata for mapping and analysis of a major earthquake (magnitude 6+), ready for cartography and visualizations.

## 🌎 What does this notebook do?

- **Downloads** main USGS products for a target earthquake (M6+):

  - Main event metadata (properties)
  - ShakeMap and ground shaking data
  - Fault traces and geometry
  - Impacted cities
  - Population exposure
  - Forecasts and aftershocks
  - Event comments/annotations

- **Saves** all datasets as CSV and **GeoPackage (GPKG)** files for easy Geopandas or GIS integration.

- **Performs geospatial operations:**

  - Clips ShakeMap/ground motion grids to land/ocean (using Natural Earth ocean mask)
  - Computes distances from aftershocks to main fault
  - Joins, cleans, and harmonizes geometry for direct use in Geopandas or GIS.

- **Prepares data** for direct map-making (choropleth, city labels, impact, etc.) and statistical charts.

## ⚙️ User Parameters

Set these parameters at the top of the notebook:

| Parameter     | Description                                 | Example              |
| ------------- | ------------------------------------------- | -------------------- |
| `event_id`    | USGS Event ID or custom identifier          | "us7000j8ak"         |
| `region_bbox` | Bounding box for analysis (min/max lat/lon) | [33, 37, -122, -117] |
| `starttime`   | Start date (for aftershock queries)         | "2024-01-01"         |
| `endtime`     | End date (for aftershock queries)           | "2024-06-30"         |
| `output_path` | Output folder path                          | "./data/"            |

**Edit these as needed before running.**

## 📥 Output Files

- **GeoPackage (.gpkg)**: Geodata layers for maps (fault, cities, exposures, MMI polygons, etc.)
- **CSV**: Tables of properties, exposure, aftershocks, etc.
- **Plots**: (optional) Quick visual checks (e.g., epicenter, city distribution)

## 🔑 Main USGS Products Handled

- **Main Earthquake**: Event metadata and geometry
- **ShakeMap**: Ground shaking grids and contours
- **Properties**: Summary of event and impact
- **Comments**: Official annotations/descriptions
- **Cities**: Impacted places/cities with location
- **Exposure**: Population at risk, by shaking intensity
- **Forecast**: Aftershock forecasts and probabilities
- **Fault**: Main fault trace and geometry (polyline)
- **Aftershocks**: List and details of aftershocks in region

## 🗺️ Geospatial Processing

- **Clip** ShakeMap/MMI layers to exclude ocean (Natural Earth ocean mask)
- **Compute distance** from cities/exposures to fault
- **Join & clean** all layers for seamless map production

## 📝 How to use

1. Set parameters (`event_id`, region, output path, etc.) at the top.
2. Run the notebook sequentially.
3. Use output files in GIS software (QGIS, ArcGIS) or for charting.
