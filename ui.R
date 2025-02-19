source("mapboxtoken_setup.R")



################################################################################
## Navigation bar at top of window
################################################################################

navbarPage(
  
  tags$head(
    includeCSS("styles.css")
  ),
  
  title = 
    div(
      img(src = "green-job-mapping-logo-small.png", 
          height = "28px"),
      "CCRC Green Jobs Mapping"
  ),
  id="nav",

  
################################################################################
## First tab: Window for interactive map
################################################################################
  
  tabPanel("Interactive Map",
           div(class="outer",
               div(id = "map", style = "height: 100%;"),
               
               
               
################################################################################
## Floating panel for input controls
################################################################################

               absolutePanel(id = "controls", 
                             class = "panel panel-default", 
                             fixed = TRUE,
                             draggable = TRUE, 
                             top = 60, left = "auto", right = 20, bottom = "auto",
                             width = 360, height = "auto",
                             
                             h2("Green Jobs Explorer"),
                             
                             selectInput("selected_green_category",
                                         "Select Supply Category:",
                                         choices = c("Green New & Emerging", 
                                                     "Green Enhanced Skills", 
                                                     "Green Increased Demand")
                             ),
                             textInput("search_term", "Search by Institution:",
                                       placeholder = "Type institution here...", 
                                       width = "100%"
                             ),
                             actionButton("search_btn", "Search"),
                             tags$button("Clear", onclick = "clearMap()", 
                                         style = "margin-left: 10px;", class = "btn btn-default"
                             )
               ),
           )
  ),
  
  
  
  
  

################################################################################
## Second Tab
################################################################################

  tabPanel("Background",
           img(src = "green-job-mapping-logo-small.png", 
               height = "60px"),
           h2("About the CCRC Green Jobs Mapping App"),
           fluidRow(
             column(3,
                    selectInput("states", "States", c("All states"="", structure(state.abb, names=state.name), "Washington, DC"="DC"), multiple=TRUE)
             ),
             column(3,
                    conditionalPanel("input.states",
                                     selectInput("cities", "Cities", c("All cities"=""), multiple=TRUE)
                    )
             ),
             column(3,
                    conditionalPanel("input.states",
                                     selectInput("zipcodes", "Zipcodes", c("All zipcodes"=""), multiple=TRUE)
                    )
             )
           ),
           fluidRow(
             column(1,
                    numericInput("minScore", "Min score", min=0, max=100, value=0)
             ),
             column(1,
                    numericInput("maxScore", "Max score", min=0, max=100, value=100)
             )
           )
  ),



################################################################################
## Citation at bottom of window
################################################################################

  tags$footer(
    class = "footer",
    tags$p("Created by Wei Wang, Joshua Rosenberg, Cameron Sublet, and Bret Staudt Willet,", 
           "with the",
           tags$a(href="https://ccrc.tc.columbia.edu/", "Community College Research Center"),
           "at Teachers College, Columbia."),
    tags$p("Source code on", 
           tags$a(href="https://github.com/wwang93/CCRC_Mapping_JS", "GitHub."),
           "Thanks to funding from JC Morgan Chase."
    )
  ),




################################################################################
## Introducing Mapbox GL JS Resources and Custom JS Files
################################################################################

  tags$head(
    tags$link(href = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.css", rel = "stylesheet"),
    tags$script(src = "https://api.mapbox.com/mapbox-gl-js/v2.14.1/mapbox-gl.js"),
    tags$script(src = "mapbox-script.js"),
    tags$script(HTML(paste0("const mapboxToken = '", mapbox_token, "';")))
  )


)