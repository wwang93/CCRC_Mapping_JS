library(dplyr)
library(geojsonio)
library(jsonlite)



################################################################################

# Load data
hdallyears <- readRDS("data/hdallyears.rds")
ipeds_green_summed <- readRDS("data/ipeds_green_summed.rds")
counties_sf <- readRDS("data/counties_sf_processed.rds")

# Ensure GeoJSON data has unique IDs for feature-state
counties_sf <- 
  counties_sf %>%
  mutate(id = row_number())  # Assign unique IDs to each county

# Merge data
hdallyears_joined <- 
  hdallyears %>%
  left_join(ipeds_green_summed, by = "unitid")



################################################################################

function(input, output, session) {
  # Save counties_sf data to reactiveValues
  map_data <- 
    reactiveValues(
    county_data = counties_sf
  )
  
  # Convert counties_sf to GeoJSON and send to front end
  observe({
    if (!inherits(map_data$county_data, "sf")) {
      stop("map_data$county_data must be an sf object")
    }
    
    counties_geojson <- geojsonio::geojson_json(map_data$county_data)
    
    # Debug: output partial GeoJSON data
    print("Sending GeoJSON data to frontend")
    print(substr(counties_geojson, 1, 500))
    
    session$sendCustomMessage(type = "updateCounties", counties_geojson)
  })
  
  # Search button: find records based on the entered school name and selected supply category
  observeEvent(input$search_btn, {
    req(input$search_term)
    req(input$selected_green_category)
    
    # Filter data by school name (instnm) and supply category (greencat)
    search_result <- hdallyears_joined %>%
      filter(grepl(input$search_term, instnm, ignore.case = TRUE),
             greencat == input$selected_green_category) %>%
      head(1)
    
    if (nrow(search_result) > 0) {
      # Constructing the HTML content of the popup window: displaying the name of the school, the selected category, and the size value
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
  
  
  # Note: The Clear button calls the front-end clearMap() function directly in the UI.
  # So there's no need for an additional observeEvent to handle the Clear button here.
}