library(shiny)
library(jsonlite)
library(geojsonio)
library(dplyr)
source("mapboxtoken_setup.R")  # This file defines the mapbox_token variable

# Load data
hdallyears <- readRDS("hdallyears.rds")
ipeds_green_summed <- readRDS("ipeds_green_summed.rds")
# counties_sf <- readRDS("counties_sf_processed.rds")
counties_sf <- readRDS("counties_sf_simplified.rds")  # Load the simplified version

# Ensure GeoJSON data has unique IDs for feature-state
counties_sf <- counties_sf %>%
  mutate(id = row_number())  # Assign unique IDs to each county

# Merge data for institution search
hdallyears_joined <- hdallyears %>%
  left_join(ipeds_green_summed, by = "unitid")

ui <- fluidPage(
  # Set initial CSS style: hide the map until fully loaded
  tags$style(HTML("
    #map { 
      visibility: hidden;
    }
  ")),
  titlePanel("CCRC Green Job Seek Mapping"),
  
  # Layout: Left column for supply category selector, right column for search controls and the map container
  fluidRow(
    column(3,
           wellPanel(
             # Existing supply category selector
             selectInput("selected_green_category",
                         "Select Supply Category:",
                         choices = c("Green New & Emerging", 
                                     "Green Enhanced Skills", 
                                     "Green Increased Demand")),
             # New Filter: Climate Degree
             selectInput("climate_degree",
                         "Filter: Climate Degree",
                         choices = c("All Degrees", 
                                     "Energy & Climate Connected Degree", 
                                     "Non-Energy & Climate Connected Degree")),
             # New Filter: Career Cluster
             selectInput("career_cluster",
                         "Filter: Career Cluster",
                         choices = c("All Programs",
                                     "Advanced Manufacturing",
                                     "Agriculture",
                                     "Arts, Entertainment & Design",
                                     "Construction",
                                     "Digital Technology",
                                     "Education",
                                     "Energy & Natural Resources",
                                     "Financial Services",
                                     "Healthcare & Human Services",
                                     "Hospitality, Events & Tourism",
                                     "Management & Entrepreneurship",
                                     "Marketing & Sales",
                                     "Public Service & Safety",
                                     "Supply Chain & Transportation")),
             # New Filter: Entry Education Level
             selectInput("entry_education",
                         "Filter: Entry Education Level",
                         choices = c("Less than BA", "BA and Higher"))
           )
    ),
    column(9,
           wellPanel(
             fluidRow(
               column(8,
                      textInput("search_term", "Search by Institution:",
                                placeholder = "Type institution here...", width = "100%")
               ),
               column(4,
                      div(style = "margin-top: 25px;",
                          actionButton("search_btn", "Search"),
                          tags$button("Clear", onclick = "clearMap()", 
                                      style = "margin-left: 10px;", class = "btn btn-default")
                      )
               )
             )
           ),
           div(id = "map", style = "height:750px;")
    )
  ),
  
  # Footer
  fluidRow(
    column(12, align = "center",
           tags$footer(
             style = "margin-top: 20px; padding: 10px; font-size: 12px; background-color: #f8f9fa; border-top: 1px solid #e9ecef;",
             HTML("Created by Wei Wang, Joshua Rosenberg, Cameron Sublet and Bret Staudt Willet with the Community College Research Center at Teachers College, Columbia. 
                  Source code at: <a href='https://github.com/wwang93/CCRC_Mapping_JS' target='_blank'>GitHub</a>. 
                  Thanks to funding from JC Morgan Chase.")
           )
    )
  ),
  
  tags$head(
    # Include Mapbox GL JS CSS and JS library
    tags$link(href = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.css", rel = "stylesheet"),
    tags$script(src = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.js"),
    # Include the custom JS file (which now loads static data on the front end)
    tags$script(src = "mapbox-script.js"),
    # Pass the mapboxToken variable to the front end
    tags$script(HTML(paste0("const mapboxToken = '", mapbox_token, "';"))),
    # Load Turf.js library (if further processing is needed)
    tags$script(src="https://cdn.jsdelivr.net/npm/@turf/turf@6/turf.min.js")
  )
)

server <- function(input, output, session) {
  # Search button: Find records based on the entered institution name and selected supply category
  observeEvent(input$search_btn, {
    req(input$search_term)
    req(input$selected_green_category)
    
    # Filter data by institution name (instnm) and supply category (greencat)
    search_result <- hdallyears_joined %>%
      filter(grepl(input$search_term, instnm, ignore.case = TRUE),
             greencat == input$selected_green_category) %>%
      head(1)
    
    if (nrow(search_result) > 0) {
      # Construct the popup content: display the institution name, selected category, and the size value
      popup_text <- paste0(
        "<strong>", search_result$instnm, "</strong><br>",
        "Category: ", input$selected_green_category, "<br>",
        "Size: ", search_result$size
      )
      coords <- list(
        lng = search_result$longitud,
        lat = search_result$latitude,
        popup = popup_text
      )
      # Send search results to the front end
      session$sendCustomMessage(type = "updateSearch", coords)
    } else {
      showNotification("No Institution Found!", type = "error")
    }
  })
}

shinyApp(ui, server)
