library(shiny)
library(jsonlite)
library(geojsonio)
library(dplyr)

# Load data
hdallyears <- readRDS("hdallyears.rds")
ipeds_green_summed <- readRDS("ipeds_green_summed.rds")
counties_sf <- readRDS("counties_sf_processed.rds")

# Ensure GeoJSON data has unique IDs for feature-state
counties_sf <- counties_sf %>%
  mutate(id = row_number()) # Add unique ID for each feature

# Merge data
hdallyears_joined <- hdallyears %>%
  left_join(ipeds_green_summed, by = "unitid")

# UI
ui <- fluidPage(
  titlePanel("CCRC Mapping with Mapbox GL JS"),
  
  fluidRow(
    column(
      width = 10,
      div(
        style = "display: flex; align-items: center;",
        textInput("search_term", "Search by Institution:", placeholder = "Type institution here...", width = "100%"),
        actionButton("search_btn", "Search", style = "margin-left: 10px;"),
        actionButton("clear_btn", "Clear", style = "margin-left: 10px;")
      )
    )
  ),
  
  fluidRow(
    column(6, align = "center",
           selectInput("selected_green_category",
                       "Select Supply Category:",
                       choices = c("Green New & Emerging", "Green Enhanced Skills", "Green Increased Demand"))
    )
  ),
  
  # Map output with JavaScript integration
  fluidRow(
    column(12, tags$div(id = "map", style = "height: 700px;"))
  ),
  
  # Include Mapbox GL JS resources
  tags$head(
    tags$link(href = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.css", rel = "stylesheet"),
    tags$script(src = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.js"),
    tags$script(src = "mapbox-script.js"),
    tags$script(HTML(paste0("const mapboxToken = '", Sys.getenv("MAPBOX_TOKEN"), "';")))
  )
)

# Server
server <- function(input, output, session) {
  # Reactive values to manage dynamic data
  map_data <- reactiveValues(
    search_coords = NULL,
    county_data = counties_sf
  )
  
  # Prepare JSON for Mapbox
  observe({
    if (!inherits(map_data$county_data, "sf")) {
      stop("map_data$county_data must be an sf object")
    }
    
    # Convert sf object to GeoJSON string
    counties_geojson <- geojsonio::geojson_json(map_data$county_data)
    
    
    # Debugging: Print GeoJSON data to console
    print("Sending GeoJSON data to frontend")
    print(substr(counties_geojson, 1, 500)) # Optional: Print first 500 characters
    
    # Send GeoJSON to frontend
    session$sendCustomMessage(type = "updateCounties", counties_geojson)
  })

}

shinyApp(ui, server)
