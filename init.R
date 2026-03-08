# init.R
# Este script instala las librerías necesarias en el servidor de Hugging Face
my_packages <- c("shiny", "bslib", "duckdb", "dplyr", "DT", "arrow", "stringr")

install_if_missing <- function(p) {
  if (!p %in% installed.packages()[, "Package"]) {
    install.packages(p, dependencies = TRUE)
  }
}

invisible(sapply(my_packages, install_if_missing))