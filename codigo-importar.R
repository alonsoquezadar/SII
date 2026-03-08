# Importa el archivo txt '/Users/alonso/Desktop/Proyecto SII/PUB_NOM_ACTECOS.txt'
# Asigna el resultado a una variable llamada 'datos'
#Carga todas las librerias necesarias para el análisis de datos
library(dplyr)
library(ggplot2)
library(readr)
library(arrow)

# carga el archivo txt en una variable llamada 'df'
#importar datos

df <- read.table(
  '/Users/alonso/Desktop/Proyecto SII/PUB_EMPRESAS_PJ_2020_A_2024/PUB_EMPRESAS_PJ_2024.txt',
  header = TRUE, sep = "\t", quote = "\"",
  fill = TRUE, stringsAsFactors = FALSE
)

#Guarda el dataframe en un archivo parquet
write_parquet(df, '/Users/alonso/Desktop/Proyecto SII/Parquet_Emp_2022-2024/EMP_2024.parquet')

# Importar y guardar en parquet todos los archivos de las carpetas

# Definir carpetas y sus rangos de años
carpetas <- list(
  list(ruta = '/Users/alonso/Desktop/Proyecto SII/PUB_EMPRESAS_PJ_2005_A_2009', agnos = 2005:2009),
  list(ruta = '/Users/alonso/Desktop/Proyecto SII/PUB_EMPRESAS_PJ_2010_A_2014', agnos = 2010:2014),
  list(ruta = '/Users/alonso/Desktop/Proyecto SII/PUB_EMPRESAS_PJ_2015_A_2019', agnos = 2015:2019),
  list(ruta = '/Users/alonso/Desktop/Proyecto SII/PUB_EMPRESAS_PJ_2020_A_2024', agnos = 2020:2024)
)

# Carpeta de salida
output_dir <- '/Users/alonso/Desktop/Proyecto SII/parquet'
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Loop
for (carpeta in carpetas) {
  for (agno in carpeta$agnos) {
    archivo_txt <- file.path(carpeta$ruta, paste0('PUB_EMPRESAS_PJ_', agno, '.txt'))
    archivo_parquet <- file.path(output_dir, paste0('PUB_EMPRESAS_PJ_', agno, '.parquet'))
    
    if (file.exists(archivo_txt)) {
      cat('Procesando:', agno, '...')
      df <- read.table(archivo_txt, header = TRUE, sep = "\t", 
                       quote = "\"", fill = TRUE, stringsAsFactors = FALSE)
      write_parquet(df, archivo_parquet)
      cat(' OK (', nrow(df), 'filas)\n')
    } else {
      cat('No encontrado:', archivo_txt, '\n')
    }
  }
}

cat('Listo! Archivos en:', output_dir, '\n')