# Credit: build on the exmaple in https://rstudio.github.io/leaflet/shiny.html
library(sf)
library(shiny)
library(leaflet)
# library(leaflet.extras)
flows = st_read("../../who-data/accra/flows.gpkg") 
ui = bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                sliderInput("range", "Flows (n/day)", 1, 500,
                            value = c(50, 500), step = 10
                ),
                selectInput("year", "Scenario", c(2016, 2017)
                ),
                selectInput("mode", "Mode of transport", c("Walking", "Cycling"))
  )
)

server = function(input, output, session) {
  
  map_centre = st_centroid(flows) %>% 
    st_coordinates()
  
  # Reactive expression for the data subsetted to what the user selected
  filteredData = reactive({
    sel = flows$flow >= input$range[1] &
      flows$flow <= input$range[2]
    flows[sel, ]
  })
  
  output$map = renderLeaflet({
    # Things that do not change go here:
    leaflet() %>% addTiles() %>%
      setView(lng = mean(map_centre[, "X"]), mean(map_centre[, "Y"]), zoom = 12)
  })
  
  # Changes to the map performed in an observer
  observe({
    d = filteredData()
    pal = colorNumeric(palette = "RdYlBu", domain = range(d$flow))
    proxy = leafletProxy("map", data = d) %>% 
      clearShapes()
    # Show or hide legend
    proxy %>% clearControls() %>% addPolylines(color = ~pal(flow), weight = d$flow / 100)
  })
}

shinyApp(ui, server)