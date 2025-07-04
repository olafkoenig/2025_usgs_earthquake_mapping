# 2025_seisme_python
Pipeline to retrieve USGS earthquake data


🛰️ Earthquake Data Analysis — USGS API
End-to-end workflow for querying, analyzing, and visualizing earthquake data from the USGS API
Includes mainshock, aftershocks, population impact, historical events, losses, and more.

✨ Overview
This project provides a reproducible workflow to interact with the USGS (ComCat) API, retrieve and explore detailed earthquake event data, and generate interactive visualizations using Python.
It is designed for transparency, flexibility, and ease of use in notebooks, making it perfect for data journalism, research, or rapid geodata analysis.

🚀 Quickstart
Clone this repository

bash
Copier
Modifier
git clone https://github.com/YOUR-USERNAME/earthquake-usgs.git
cd earthquake-usgs
Set up your Python environment and install dependencies

bash
Copier
Modifier
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
Typical requirements:

requests or httpx

pandas

geopandas

folium

matplotlib, branca, numpy

jupyter or quarto (for notebooks and reporting)

libcomcat (for USGS queries)

🗺️ How to use — Querying the USGS API
1. Define your area of interest (GeoJSON) and time window
Place your GeoJSON file (e.g., myanmar.json) in the data directory.
In your script or notebook:

python
Copier
Modifier
import geopandas as gpd
from datetime import datetime
from libcomcat.search import search

geojson_path = "myanmar.json"
gdf = gpd.read_file(geojson_path)
if gdf.crs is not None and gdf.crs.to_epsg() != 4326:
    gdf = gdf.to_crs(4326)
minx, miny, maxx, maxy = gdf.total_bounds

date_start = "2025-03-22"
date_end = "2025-04-30"
starttime = datetime.fromisoformat(date_start)
endtime = datetime.fromisoformat(date_end)

events = search(
    minlongitude=minx, minlatitude=miny,
    maxlongitude=maxx, maxlatitude=maxy,
    starttime=starttime, endtime=endtime,
)
2. Mainshock and Aftershock Search
Identify the mainshock (e.g., by time, magnitude, or properties).

Search for aftershocks by running a second query, starting from the mainshock time plus a time offset.

python
Copier
Modifier
mainshock_time = "2025-03-28T00:00:00.000000Z"
mainshock_dt = datetime.fromisoformat(mainshock_time.replace("Z", "+00:00"))
aftershock_start = mainshock_dt
aftershock_end = mainshock_dt + timedelta(days=7)

aftershocks = search(
    minlongitude=minx, minlatitude=miny,
    maxlongitude=maxx, maxlatitude=maxy,
    starttime=aftershock_start,
    endtime=aftershock_end,
)
3. Build DataFrames and GeoDataFrames
Turn your results into pandas DataFrames and GeoDataFrames for easy analysis and mapping.

python
Copier
Modifier
import pandas as pd
import geopandas as gpd

cols = ["id", "time", "magnitude", "depth", "latitude", "longitude"]
df = pd.DataFrame([{c: getattr(e, c, None) for c in cols} for e in events])
gdf = gpd.GeoDataFrame(
    df, geometry=gpd.points_from_xy(df.longitude, df.latitude), crs="EPSG:4326"
)
🌍 Visualization Example
Map aftershocks with Folium:

python
Copier
Modifier
import folium
from branca.colormap import linear
import numpy as np

def mag_to_radius(mag):
    return 2 * np.exp(mag - 4)

colormap = linear.YlOrRd_09.scale(df["magnitude"].min(), df["magnitude"].max())
m = folium.Map(location=[df["latitude"].mean(), df["longitude"].mean()], zoom_start=6, tiles="Cartodb dark_matter")
colormap.add_to(m)

for _, row in df.iterrows():
    folium.CircleMarker(
        location=[row["latitude"], row["longitude"]],
        radius=mag_to_radius(row["magnitude"]),
        color="black",
        weight=1,
        fill=True,
        fill_color=colormap(row["magnitude"]),
        fill_opacity=0.6,
        popup=f"Mag {row['magnitude']:.1f}<br>ID: {row['id']}"
    ).add_to(m)

m  # In Jupyter/Quarto: displays interactive map
📦 USGS Products and JSON Data
You can fetch additional event products (rupture, losses, historical events, comments, etc.) using the USGS ComCat API, parse them as JSON, and convert to DataFrames for analysis or mapping.

🔖 Notes
Notebook trust: For Folium/Leaflet maps to display in Jupyter, select File → Trust Notebook (GitHub cannot display interactive maps by default).

For static outputs: Export maps as HTML or use screenshots for articles.

QMD/Quarto support: Use Quarto to render rich HTML reports (.qmd files support interactive widgets).

