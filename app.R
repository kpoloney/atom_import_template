library(shiny)
source("import_template.R")
map <- read.csv(file.path("data", "Mapping.csv"), na.strings = "", encoding = "UTF-8", stringsAsFactors = F)

# Create UI to allow user to select a local file
ui <- fluidPage(
  
  # user inputs original description csv
  selectInput("inst", label = "Institution", choices = c("SFU Archives", "Other")),
  fileInput("descriptions", "Upload Descriptions"),
  
  # make this conditional based on input inst
  conditionalPanel(
    condition = "input.inst != 'SFU Archives'",
    fileInput("map", "Upload Mapping")
  ),
  uiOutput("atom")
  
)

server <- function(input, output, session) {
  data <- eventReactive(input$descriptions, {
    read.csv(input$descriptions$datapath, stringsAsFactors = F)
  })
  
  map_reactive <- reactive({
    if(input$inst != "SFU Archives")
      return(read.csv(input$map$datapath, stringsAsFactors = F, na.strings = ""))
    else
      return(map)
  })

  # output transformed data for download
  output$atom <- renderUI({
    req(input$descriptions)
    downloadButton("download")
  })
  
  output$download <- downloadHandler(
    filename = function(){
      "atom_import.csv"
    },
    content = function(file){
      write.csv(transform_template(data(), map_reactive(), as.character(input$inst)), file, na = "", row.names = F)
    }
  )
  
}

shinyApp(ui, server)
