library(shiny)
library(amtabulator)

ui <- fluidPage(
  tabulator_output("table")
)

server <- function(input, output) {
  output$table <- render_tabulator({
    tabulator(mtcars)
  })
}

shinyApp(ui, server)
