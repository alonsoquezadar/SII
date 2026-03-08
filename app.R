# --- 1. CONFIGURACIÓN DE LIBRERÍAS (Forzada para el servidor) ---
paquetes <- c("shiny", "bslib", "duckdb", "dplyr", "DT", "arrow", "stringr")

for (pkg in paquetes) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
    library(pkg, character.only = TRUE)
  }
}


#Instalación de paquetes necesarios shiny, bslib, duckdb, dplyr, DT
library(shiny)
library(bslib)
library(duckdb)
library(dplyr)
library(DT)

# --- Conexión a los datos locales (que luego subirás) ---
con <- dbConnect(duckdb())
# Registramos la carpeta como una tabla virtual
dbExecute(con, "CREATE VIEW empresas AS SELECT * FROM read_parquet('parquet_final/*.parquet')")

ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "Explorador de Empresas - SII Chile",
  sidebar = sidebar(
    title = "Filtros de Análisis",
    selectInput("agno", "Año Comercial:", choices = NULL),
    selectInput("reg", "Región:", choices = NULL),
    selectInput("tramo", "Tramo Ventas:", choices = NULL),
    hr(),
    actionButton("update", "Actualizar Tabla", class = "btn-primary w-100")
  ),
  
  card(
    card_header("Base de Datos Estructurada (Top 500 registros)"),
    DTOutput("tabla_sii")
  )
)

server <- function(input, output, session) {
  
  # Cargar selectores dinámicamente al iniciar
  observe({
    agnos <- dbGetQuery(con, "SELECT DISTINCT agno_comercial FROM empresas ORDER BY agno_comercial DESC")[[1]]
    regs <- dbGetQuery(con, "SELECT DISTINCT region FROM empresas ORDER BY region")[[1]]
    tramos <- dbGetQuery(con, "SELECT DISTINCT tramo_ventas FROM empresas")[[1]]
    
    updateSelectInput(session, "agno", choices = agnos)
    updateSelectInput(session, "reg", choices = c("Todas", regs))
    updateSelectInput(session, "tramo", choices = c("Todos", tramos))
  })
  
  # Filtrado con DuckDB (eficiencia máxima)
  resultado <- eventReactive(input$update, {
    query <- tbl(con, "empresas") %>%
      filter(agno_comercial == !!as.numeric(input$agno))
    
    if (input$reg != "Todas") query <- query %>% filter(region == !!input$reg)
    if (input$tramo != "Todos") query <- query %>% filter(tramo_ventas == !!input$tramo)
    
    query %>% 
      select(rut, dv, razon_social, actividad_economica, tramo_ventas) %>%
      head(500) %>% 
      collect()
  }, ignoreNULL = FALSE)
  
  output$tabla_sii <- renderDT({
    datatable(resultado(), options = list(pageLength = 10, scrollX = TRUE))
  })
}

shinyApp(ui, server)