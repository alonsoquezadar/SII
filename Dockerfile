# Usamos la imagen oficial de Shiny
FROM rocker/shiny:latest

# Instalamos dependencias de Linux necesarias para arrow y duckdb
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Instalamos las librerías de R
RUN R -e "install.packages(c('shiny', 'bslib', 'duckdb', 'dplyr', 'DT', 'arrow', 'stringr'), repos='https://cloud.r-project.org/')"

# Borramos las apps de ejemplo de Shiny (¡Adiós pingüinos!)
RUN rm -rf /srv/shiny-server/*

# Copiamos TODOS tus archivos (app.R y la carpeta parquet_final) al servidor
COPY . /srv/shiny-server/

# Configuramos el puerto 7860 que exige Hugging Face
RUN sed -i 's/listen 3838;/listen 7860;/g' /etc/shiny-server/shiny-server.conf

# Damos permisos al usuario 'shiny'
RUN chown -R shiny:shiny /srv/shiny-server/

# Exponemos el puerto y arrancamos el servidor
EXPOSE 7860
USER shiny
CMD ["/usr/bin/shiny-server"]