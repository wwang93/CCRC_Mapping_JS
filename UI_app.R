library(shiny)
library(jsonlite)
library(geojsonio)
library(dplyr)
source("mapboxtoken_setup.R")

# Load data
hdallyears <- readRDS("hdallyears.rds")
ipeds_green_summed <- readRDS("ipeds_green_summed.rds")
counties_sf <- readRDS("counties_sf_processed.rds")

# Ensure GeoJSON data has unique IDs for feature-state
counties_sf <- counties_sf %>%
  mutate(id = row_number())  # Assign unique IDs to each county

# Merge data
hdallyears_joined <- hdallyears %>%
  left_join(ipeds_green_summed, by = "unitid")

# UI
ui <- fluidPage(
  titlePanel("CCRC Green Job Seek Mapping"),
  
  # 整个页面分成左右两列：
  fluidRow(
    # 左侧：供给类别选择器，占3/12宽度
    column(3,
           wellPanel(
             selectInput("selected_green_category",
                         "Select Supply Category:",
                         choices = c("Green New & Emerging", 
                                     "Green Enhanced Skills", 
                                     "Green Increased Demand"))
           )
    ),
    # 右侧：上方搜索控件，下方地图，占9/12宽度
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
                          # 使用 HTML 按钮绑定前端的 clearMap() 函数
                          tags$button("Clear", onclick = "clearMap()", 
                                      style = "margin-left: 10px;", class = "btn btn-default")
                      )
               )
             )
           ),
           # 地图区域
           div(id = "map", style = "height: 700px;")
    )
  ),
  
  # 页脚
  fluidRow(
    column(
      12, align = "center",
      tags$footer(
        style = "margin-top: 20px; padding: 10px; font-size: 12px; background-color: #f8f9fa; border-top: 1px solid #e9ecef;",
        HTML("Created by Wei Wang, Joshua Rosenberg, and Cameron Sublet at the University of Tennessee, Knoxville with the Community College Research Center at Teachers College, Columbia. 
              Source code at: <a href='https://github.com/wwang93/CCRC_Mapping_JS' target='_blank'>GitHub</a>. 
              Thanks to funding from JC Morgan Chase.")
      )
    )
  ),
  
  # 引入 Mapbox GL JS 资源和自定义 JS 文件
  tags$head(
    tags$link(href = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.css", rel = "stylesheet"),
    tags$script(src = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.js"),
    tags$script(src = "mapbox-script.js"),
    tags$script(HTML(paste0("const mapboxToken = '", mapbox_token, "';")))
  )
)



# Server
server <- function(input, output, session) {
  # Save counties_sf data to reactiveValues
  map_data <- reactiveValues(
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

shinyApp(ui, server)
