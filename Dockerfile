# 1. Usamos una imagen que ya tiene R y Shiny instalado
FROM rocker/shiny:latest

# 2. Instalamos las librerías de LINUX que Arrow y DuckDB necesitan para vivir
# Sin esto, el proceso muere en silencio
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Instalamos los paquetes de R (esta vez de forma infalible)
RUN R -e "install.packages(c('shiny', 'bslib', 'duckdb', 'dplyr', 'DT', 'arrow', 'stringr'), repos='https://cloud.r-project.org/')"

# 4. Copiamos tus archivos al servidor
WORKDIR /home/shinyapp
COPY . .

# 5. Permisos para que la app pueda leer los Parquet
RUN chown -hR shiny:shiny /home/shinyapp

# 6. Puerto que exige Hugging Face
EXPOSE 7860

# 7. Comando para arrancar el dashboard
CMD ["R", "-e", "shiny::runApp('/home/shinyapp/app.R', host = '0.0.0.0', port = 7860)"]