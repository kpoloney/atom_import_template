library(shiny)
source("import_template.R")
map <- read.csv(file.path("data", "Mapping.csv"), na.strings = "", stringsAsFactors = F)

# Create UI to allow user to select a local file
ui <- fluidPage(
  
  # user inputs original description csv
  fileInput("descriptions", "Upload"),
  downloadButton("download", "atom_import.csv")
  
)

server <- function(input, output, session) {
  data <- eventReactive(input$descriptions, {
    read.csv(input$descriptions$datapath, stringsAsFactors = F)
  })
  
  # output transformed data for download
  output$download <- downloadHandler(
    filename = function(){
      "atom_import.csv"
    },
    content = function(file){
      write.csv(transform_template(data(), map), file, na = "", row.names = F)
    }
  )
  
}

shinyApp(ui, server)
