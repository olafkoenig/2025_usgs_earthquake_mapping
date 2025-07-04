# 2025_seisme_python
Pipeline to retrieve USGS earthquake data

# 🛰️ Earthquake Data Analysis — USGS API

**End-to-end workflow for querying, analyzing, and visualizing earthquake data from the USGS API**  
*Mainshock, aftershocks, impact, historical events, losses, and more.*

---

## ✨ Overview

This project shows how to work with the USGS (ComCat) earthquake API, from querying events, building DataFrames, to mapping and analysis.  
All in Python, notebook-friendly, and perfect for reproducible geodata work or data journalism.

---

## 🚀 Quickstart

1. **Clone and install**

```bash
git clone https://github.com/YOUR-USERNAME/earthquake-usgs.git
cd earthquake-usgs
python -m venv venv
source venv/bin/activate      # Windows : .\venv\Scripts\activate
pip install -r requirements.txt
```

---

## 🗺️ USGS API: Typical Workflow

```python
import geopandas as gpd
import pandas as pd
import folium
from branca.colormap import linear
from datetime import datetime, timedelta
from libcomcat.search import search

# 1. Load your AOI (area of interest)
geojson_path = "myanmar.json"
gdf = gpd.read_file(geojson_path)
if gdf.crs and gdf.crs.to_epsg() != 4326:
    gdf = gdf.to_crs(4326)
minx, miny, maxx, maxy = gdf.total_bounds

# 2. Search for earthquakes
date_start, date_end = "2025-03-22", "2025-04-30"
events = search(
    minlongitude=minx, minlatitude=miny,
    maxlongitude=maxx, maxlatitude=maxy,
    starttime=datetime.fromisoformat(date_start),
    endtime=datetime.fromisoformat(date_end),
)

cols = ["id", "time", "magnitude", "depth", "latitude", "longitude"]
df = pd.DataFrame([{c: getattr(e, c, None) for c in cols] for e in events])

# 3. Identify mainshock (by time or magnitude)
mainshock_time = "2025-03-28T00:00:00.000000Z"
mainshock_dt = datetime.fromisoformat(mainshock_time.replace("Z", "+00:00"))

# 4. Find aftershocks (e.g. 7 days after mainshock)
aftershocks = search(
    minlongitude=minx, minlatitude=miny,
    maxlongitude=maxx, maxlatitude=maxy,
    starttime=mainshock_dt,
    endtime=mainshock_dt + timedelta(days=7),
)
df_after = pd.DataFrame([{c: getattr(e, c, None) for c in cols] for e in aftershocks])

# 5. Map results with Folium
colormap = linear.YlOrRd_09.scale(df["magnitude"].min(), df["magnitude"].max())
m = folium.Map(
    location=[df["latitude"].mean(), df["longitude"].mean()],
    zoom_start=6,
    tiles="Cartodb dark_matter"
)
for _, row in df.iterrows():
    folium.CircleMarker(
        location=[row["latitude"], row["longitude"]],
        radius=2 * (row["magnitude"] - 3),
        color=colormap(row["magnitude"]),
        fill=True, fill_opacity=0.7, stroke=False,
        popup=f"Mag {row['magnitude']}<br>ID: {row['id']}"
    ).add_to(m)

m.save("earthquakes_map.html")
```

---

## 📎 Notes

* Official docs → <https://earthquake.usgs.gov/fdsnws/event/1/>  
* You can query extra products (ShakeMap, rupture, losses, historical events…) via the event detail JSON.  
* All notebooks can be rendered with **Jupyter** or **Quarto ( `.qmd` )** for publishing on GitHub Pages, Netlify, etc.  

---

## ✍️ Credits

Project by **Olaf König**  
MIT License
