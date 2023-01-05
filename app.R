library(shiny)
source("import_template.R")

map <- read.csv(file.path("data", "Mapping.csv"), na.strings = "", encoding = "UTF-8", stringsAsFactors = F)
scrb <- read.csv(file.path("data", "MappingSCRB.csv"), na.strings = "", encoding = "UTF-8", stringsAsFactors = F)

# Create UI to allow user to select a local file
ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  h2("AtoM import converter"),
  # user inputs original description csv
  selectInput("inst", label = "Institution", choices = c("SFU Archives", "SFU Special Collections", "Other")),
  fileInput("descriptions", "Upload descriptions (csv)"),
  
  # If the institution is outside SFU, prompt upload of field mapping csv
  conditionalPanel(
    condition = "input.inst == 'Other'",
    fileInput("map", "Upload mapping (csv)")
  ),
  uiOutput("atom")
  
)

server <- function(input, output, session) {
  data <- eventReactive(input$descriptions, {
    read.csv(input$descriptions$datapath, stringsAsFactors = F, na.strings="", check.names = FALSE)
  })
  
  map_reactive <- reactive({
    if(input$inst == "Other") {
      return(read.csv(input$map$datapath, stringsAsFactors = F, na.strings = "", encoding = "UTF-8"))
    } else if (input$inst == "SFU Archives"){
      return(map)
    } else if (input$inst == "SFU Special Collections"){
      return(scrb)
    }
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