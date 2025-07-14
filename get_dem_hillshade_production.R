# ========== PARAMETRES VIA LIGNE DE COMMANDE (optparse) ==========

library(optparse)

option_list <- list(
  make_option("--data_dir", type = "character", default = "data_input/dem", help = "Dossier de travail (tous les fichiers dedans)"),
  make_option("--area_file", type = "character", default = "myanmar.json", help = "Nom du fichier GeoJSON de la zone d'intérêt (dans data_dir)"),
  make_option("--dem_margin", type = "double", default = 1, help = "Marge autour de la zone en degrés décimaux"),
  make_option("--dem_zoom", type = "integer", default = 8, help = "Zoom du DEM (1-14, influera sur la résolution)"),
  make_option("--dem_export_name", type = "character", default = "dem_elevatr.tif", help = "Nom du fichier DEM exporté (dans data_dir)"),
  make_option("--blend_export_name", type = "character", default = "hillshades_blend.tif", help = "Nom du fichier blend final (dans data_dir)"),
  make_option("--hs_azimuths", type = "character", default = "350,15,270", help = "Liste des azimuts (séparés par virgule)"),
  make_option("--hs_altitudes", type = "character", default = "70,60,55", help = "Liste des altitudes (séparés par virgule)"),
  make_option("--add_slope", type = "logical", default = TRUE, help = "Ajouter la couche pente ? TRUE/FALSE"),
  make_option("--aggregate_factor", type = "integer", default = NA, help = "Facteur d'agrégation (NULL = natif, sinon entier)"),
  make_option("--n_workers", type = "integer", default = 2, help = "Nombre de workers pour le calcul parallèle"),
  make_option("--blend_weights", type = "character", default = "0.6,0,0,0.6", help = "Pondérations pour le blend (séparés par virgule)")
)

opt <- parse_args(OptionParser(option_list = option_list))

# Conversion des paramètres textes en vecteurs numériques (pour azimuth, altitude, blend)
HS_AZIMUTHS  <- as.numeric(strsplit(opt$hs_azimuths, ",")[[1]])
HS_ALTITUDES <- as.numeric(strsplit(opt$hs_altitudes, ",")[[1]])
BLEND_WEIGHTS <- as.numeric(strsplit(opt$blend_weights, ",")[[1]])
ADD_SLOPE <- as.logical(opt$add_slope)
if (is.null(opt$aggregate_factor) || is.na(opt$aggregate_factor) || opt$aggregate_factor == "" ) {
  AGGREGATE_FACTOR <- NULL
} else {
  AGGREGATE_FACTOR <- as.numeric(opt$aggregate_factor)
}

DATA_DIR <- opt$data_dir
AREA_FILE <- opt$area_file
DEM_MARGIN <- opt$dem_margin
DEM_ZOOM <- opt$dem_zoom
DEM_EXPORT_NAME <- opt$dem_export_name
BLEND_EXPORT_NAME <- opt$blend_export_name

N_WORKERS <- opt$n_workers

# Création automatique des chemins
AREA_PATH <- file.path(AREA_FILE)
dem_export_path <- file.path(DATA_DIR, DEM_EXPORT_NAME)
DEM_EXPORT_PATH <- dem_export_path


blend_export_path <- file.path(DATA_DIR, BLEND_EXPORT_NAME)
BLEND_EXPORT_PATH <- blend_export_path


if (!dir.exists(DATA_DIR)) {
  dir.create(DATA_DIR, recursive = TRUE)
}

cat("======== PARAMETRES UTILISES ========\n")
cat(sprintf("Dossier travail      : %s\n", DATA_DIR))
cat(sprintf("Fichier zone         : %s\n", AREA_PATH))
cat(sprintf("Marge DEM            : %s°\n", DEM_MARGIN))
cat(sprintf("Zoom DEM             : %s\n", DEM_ZOOM))
cat(sprintf("DEM export           : %s\n", dem_export_path))
cat(sprintf("Blend export         : %s\n", blend_export_path))
cat(sprintf("Azimuths hillshade   : %s\n", paste(HS_AZIMUTHS, collapse = ",")))
cat(sprintf("Altitudes hillshade  : %s\n", paste(HS_ALTITUDES, collapse = ",")))
cat(sprintf("Add slope            : %s\n", ADD_SLOPE))
cat(sprintf("Aggregate factor     : %s\n", AGGREGATE_FACTOR))
cat(sprintf("Workers (CPU)        : %s\n", N_WORKERS))
cat(sprintf("Blend weights        : %s\n", paste(BLEND_WEIGHTS, collapse = ",")))
cat("=====================================\n\n")


# ========== USER SETTINGS ==========

# ==============================
# ---- Packages ----
library(sf)
library(terra)
library(elevatr)
library(future)
library(future.apply)
# ==============================
# ---- AOI ----

area_of_interest <- sf::st_read(AREA_PATH)
# ==============================

# ---- Function ----

get_dem_from_sf <- function(sf_obj, export_name, margin = 1, zoom = 10) {
  if (sf::st_crs(sf_obj) != sf::st_crs(4326)) {
    sf_obj <- sf::st_transform(sf_obj, 4326)
  }
  bbox <- sf::st_bbox(sf_obj)
  bbox_expanded <- bbox
  bbox_expanded["xmin"] <- bbox["xmin"] - margin
  bbox_expanded["xmax"] <- bbox["xmax"] + margin
  bbox_expanded["ymin"] <- bbox["ymin"] - margin
  bbox_expanded["ymax"] <- bbox["ymax"] + margin
  bbox_polygon <- sf::st_as_sfc(bbox_expanded)
  bbox_sf <- sf::st_sf(geometry = bbox_polygon)
  dem_raster <- elevatr::get_elev_raster(locations = bbox_sf, z = zoom, clip = "bbox")
  terra::writeRaster(terra::rast(dem_raster), export_name, overwrite = TRUE)
  terra::rast(dem_raster)
}
# ==============================
# ---- Download DEM ----

dem <- get_dem_from_sf(
  area_of_interest,
  export_name = DEM_EXPORT_PATH,
  margin = DEM_MARGIN,
  zoom = DEM_ZOOM
)
# ==============================
# ---- Generate hillshades ----

generate_relief_layers_parallel <- function(
    dem_path,
    azimuths = c(350, 15, 270),
    altitudes = c(70, 60, 55),
    add_slope = TRUE,
    aggregate_factor = NULL,
    workers = 2
) {
  future::plan(multisession, workers = workers)
  dem <- terra::rast(dem_path)
  if (!is.null(aggregate_factor)) {
    dem <- aggregate(dem, fact = aggregate_factor)
  }
  hs_files <- future.apply::future_lapply(
    seq_along(azimuths),
    function(i) {
      dem_worker <- terra::rast(dem_path)
      if (!is.null(aggregate_factor)) {
        dem_worker <- aggregate(dem_worker, fact = aggregate_factor)
      }
      slope_rad <- terrain(dem_worker, v = "slope", unit = "radians")
      aspect_rad <- terrain(dem_worker, v = "aspect", unit = "radians")
      hs <- shade(
        slope_rad,
        aspect_rad,
        angle = altitudes[i],
        direction = azimuths[i]
      )
      tempfile_hs <- tempfile(fileext = ".tif")
      terra::writeRaster(hs, tempfile_hs, overwrite = TRUE)
      tempfile_hs
    },
      future.seed = TRUE
  )
  hs_list <- lapply(hs_files, terra::rast)
  if (add_slope) {
    slope_deg <- terrain(dem, v = "slope", unit = "degrees")
    slope_deg <- (slope_deg - min(values(slope_deg), na.rm = TRUE)) / (max(values(slope_deg), na.rm = TRUE) - min(values(slope_deg), na.rm = TRUE))
    hs_list[[length(hs_list) + 1]] <- slope_deg
  }
  names(hs_list) <- c(paste0("hs_", seq_along(azimuths)), if (add_slope) "slope")
  rast(hs_list)
}
# ==============================
# ---- Blending hillshades ----

blend_relief_layers <- function(relief_stack, weights, plot = TRUE) {
  n_layers <- nlyr(relief_stack)
  if (length(weights) != n_layers) stop("Number of weights must match number of layers")
  weights <- weights / sum(weights)
  blended <- relief_stack[[1]] * weights[1]
  for (i in 2:n_layers) {
    blended <- blended + relief_stack[[i]] * weights[i]
  }
  if (plot) plot(blended, col = gray.colors(256), main = "Relief blend")
  blended
}

# ==============================
# ==============================
# ==============================
  
  # Générer stack hillshades + pente
relief_stack <- generate_relief_layers_parallel(
  dem_path = DEM_EXPORT_PATH,
  azimuths = HS_AZIMUTHS,
  altitudes = HS_ALTITUDES,
  add_slope = ADD_SLOPE,
  aggregate_factor = AGGREGATE_FACTOR,
  workers = N_WORKERS
)

# (Optionnel) Visualiser la pente inversée
if ("slope" %in% names(relief_stack)) {
  slope_inv <- 1 - relief_stack[["slope"]]
  plot(slope_inv, col = gray.colors(256))
}

# Blending
relief_blend <- blend_relief_layers(
  relief_stack,
  weights = BLEND_WEIGHTS
)

# Export
terra::writeRaster(
  relief_blend,
  filename = BLEND_EXPORT_PATH,
  overwrite = TRUE
)

