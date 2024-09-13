# shinyTabulator

The shinyTabulator package provides an integration of the Tabulator.js library with R Shiny, allowing users to create interactive tables in their Shiny applications.

## Installation

You can install the development version of shinyTabulator from GitHub with:

```r
# install.packages("pak")
pak::pkg_install("fxi/shinyTabulator")
```

## Usage

Here's a basic example of how to use shinyTabulator in a Shiny app:

```r
library(shiny)
library(shinyTabulator)

ui <- fluidPage(
  tabulatorOutput("myTable"),
  actionButton("updateBtn", "Update Data")
)

server <- function(input, output, session) {
  output$myTable <- renderTabulator({
    tabulator(
      data = mtcars,
      options = list(
        columns = list(
          list(title = "Car", field = "row.names"),
          list(title = "MPG", field = "mpg"),
          list(title = "Cylinders", field = "cyl"),
          list(title = "Displacement", field = "disp"),
          list(title = "HP", field = "hp")
        )
      )
    )
  })
  
  observeEvent(input$updateBtn, {
    proxy <- tabulatorProxy("myTable")
    newData <- mtcars
    newData$mpg <- newData$mpg * 2
    tabulatorUpdateData(proxy, newData)
  })
}

shinyApp(ui, server)
```

## License

This project is licensed under the MIT License.
