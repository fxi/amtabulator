# shinyTabulator

shinyTabulator integrates the Tabulator.js library with R Shiny, enabling interactive and feature-rich tables in Shiny applications.

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pkg_install("fxi/shinyTabulator")
```

## Key Features

- Interactive tables with sorting, filtering, and pagination
- Editable cells with various data types (text, number, dropdown, etc.)
- Row selection and multi-row operations
- Conditional formatting and styling
- Real-time data updates and event handling

## Basic Usage

```r
library(shiny)
library(shinyTabulator)

ui <- fluidPage(
  tabulatorOutput("myTable")
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
}

shinyApp(ui, server)
```

## Advanced Features

### Data Updates

Use `tabulatorProxy()` and `tabulatorUpdateData()` to update table data:

```r
proxy <- tabulatorProxy("myTable")
tabulatorUpdateData(proxy, newData)
```

### Event Handling

React to table events such as cell edits, row selection, and data changes:

```r
observeEvent(input$myTable_cell_edit, {
  # Handle cell edit event
})

observeEvent(input$myTable_data_selection, {
  # Handle row selection event
})

observeEvent(input$myTable_data_changed, {
  # Handle data change event
})
```

### Conditional Updates

Update specific cells based on conditions:

```r
tabulatorUpdateWhere(proxy,
  col = "mpg",
  value = 0,
  whereCol = "cyl",
  whereValue = 8,
  operator = "=="
)
```

### Converting Tabulator Data to R Data Frame

The `tabulatorToDf` function is crucial for handling data returned from the Tabulator widget. It converts the raw JSON message from the client-side Tabulator into an R data frame:

```r
observeEvent(input$myTable_data_changed, {
  changed_data <- tabulatorToDf(input$myTable_data_changed)
  # Now 'changed_data' is a regular R data frame
  print(str(changed_data))
})
```

This function is particularly useful when working with events that return table data, such as data changes or row selections.

## Documentation

For more detailed documentation and examples, please refer to the package vignettes and function documentation.

## License

This project is licensed under the MIT License.
