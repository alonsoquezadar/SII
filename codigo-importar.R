
#Carga todas las librerias necesarias para el análisis de datos
library(dplyr)
library(ggplot2)
library(readr)
library(arrow)
library(duckdb)
library(stringr)
library(purrr)
library(janitor)

# 1. DEFINIR RUTAS ABSOLUTAS
ruta_base <- "/Users/alonso/Desktop/Proyecto SII"
ruta_entrada <- file.path(ruta_base, "parquet")        # Donde están tus archivos actuales
ruta_salida <- file.path(ruta_base, "parquet_final")   # Donde quieres que queden

# Crear la carpeta de salida en la ubicación específica
if (!dir.exists(ruta_salida)) {
  dir.create(ruta_salida, recursive = TRUE)
}

# 2. Lista maestra de columnas (la misma de antes)
columnas_maestras <- c(
  "agno_comercial", "rut", "dv", "razon_social", "tramo_ventas",
  "n_trabajadores", "fecha_inicio", "fecha_termino", "fecha_inscripcion",
  "tipo_termino", "tipo_contribuyente", "subtipo_contribuyente",
  "tramo_capital_pos", "tramo_capital_neg", "rubro_economico",
  "subrubro_economico", "actividad_economica", "region",
  "provincia", "comuna", "r_presunta", "otros_regimenes"
)

# 3. Función de normalización (con el parche para 'fecha_termino')
normalizar_sii <- function(path_archivo) {
  df <- read_parquet(path_archivo)
  
  # Limpieza de nombres corruptos por encoding
  names(df) <- names(df) %>%
    str_replace_all("o.comercial|Año.comercial", "agno_comercial") %>%
    str_replace_all("Regi.n|Región", "region")
  
  # Renombrado específico para evitar duplicados
  df_estandar <- df %>%
    rename_with(~case_when(
      str_detect(., "ventas") ~ "tramo_ventas",
      str_detect(., "trabajadores") ~ "n_trabajadores",
      str_detect(., "inicio") ~ "fecha_inicio",
      str_detect(., "^Fecha.t.rmino") ~ "fecha_termino", 
      str_detect(., "^Tipo.t.rmino") ~ "tipo_termino",
      str_detect(., "inscrip") ~ "fecha_inscripcion",
      str_detect(., "positivo") ~ "tramo_capital_pos",
      str_detect(., "negativo") ~ "tramo_capital_neg",
      TRUE ~ .
    )) %>%
    janitor::clean_names()

  # Asegurar que existan todas las columnas
  for (col in columnas_maestras) {
    if (!col %in% names(df_estandar)) {
      df_estandar[[col]] <- NA
    }
  }
  
  return(df_estandar[, columnas_maestras])
}

# 4. EJECUCIÓN
archivos <- list.files(ruta_entrada, full.names = TRUE, pattern = "\\.parquet$")

if (length(archivos) == 0) {
  stop("No se encontraron archivos .parquet en: ", ruta_entrada)
}

walk(archivos, ~{
  nombre_archivo <- basename(.x)
  cat("Procesando y guardando en escritorio:", nombre_archivo, "...\n")
  
  df_limpio <- normalizar_sii(.x)
  
  # Guardar explícitamente en la ruta del escritorio
  write_parquet(df_limpio, file.path(ruta_salida, nombre_archivo))
})

cat("\n✅ ¡Listo! Los archivos están en:", ruta_salida)