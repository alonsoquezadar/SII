library(shiny)
library(bslib)
library(duckdb)
library(dplyr)
library(DT)

# Conexión a datos mediante DuckDB
con <- dbConnect(duckdb())
try({
  dbExecute(con, "CREATE VIEW empresas AS SELECT * FROM read_parquet('parquet_final/*.parquet')")
}, silent = TRUE)

# Interfaz de Usuario
ui <- page_sidebar(
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  title = "SII Dashboard - Chile",
  sidebar = sidebar(
    title = "Filtros",
    selectInput("agno", "Año Comercial:", choices = NULL),
    selectInput("reg", "Región:", choices = NULL),
    actionButton("update", "Filtrar Datos", class = "btn-primary w-100")
  ),
  card(
    card_header("Resultados de la búsqueda"),
    DTOutput("tabla_sii")
  )
)

# Servidor
server <- function(input, output, session) {
  observe({
    agnos <- dbGetQuery(con, "SELECT DISTINCT agno_comercial FROM empresas ORDER BY agno_comercial DESC")[[1]]
    regs <- dbGetQuery(con, "SELECT DISTINCT region FROM empresas ORDER BY region")[[1]]
    updateSelectInput(session, "agno", choices = agnos)
    updateSelectInput(session, "reg", choices = c("Todas", regs))
  })
  
  resultado <- eventReactive(input$update, {
    query <- tbl(con, "empresas") %>% filter(agno_comercial == !!as.numeric(input$agno))
    if (input$reg != "Todas") {
      query <- query %>% filter(region == !!input$reg)
    }
    query %>% head(100) %>% collect()
  }, ignoreNULL = FALSE)
  
  output$tabla_sii <- renderDT({
    datatable(resultado(), options = list(pageLength = 10, scrollX = TRUE))
  })
}

shinyApp(ui, server)