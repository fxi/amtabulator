library(shiny)
library(amtabulator)

# Generate 1M rows of test data
n_rows <- 100e3
set.seed(123)

# Start timing
message("Generating test data...")

test_data <- data.frame(
  id = 1:n_rows,
  name = sample(
    c(
      "John",
      "Jane",
      "Bob",
      "Alice",
      "Charlie",
      "Diana",
      "Eric",
      "Fiona"
    ), n_rows,
    replace = TRUE
  ),
  number = round(runif(n_rows, 1, 1000), 2),
  is_active = sample(c(TRUE, FALSE), n_rows, replace = TRUE),
  category = sample(c("A", "B", "C", "D"), n_rows, replace = TRUE),
  date = sample(
    seq(
      as.Date("2023/01/01"),
      as.Date("2023/12/31"),
      by = "day"
    ), n_rows,
    replace = TRUE
  ),
  score = sample(1:100, n_rows, replace = TRUE),
  stringsAsFactors = FALSE
)

ui <- fluidPage(
  titlePanel("shinyTabulator Performance Test"),
  fluidRow(
    column(
      12,
      div(
        class = "alert alert-info",
        "Check R console for timing information"
      ),
      tabulator_output("large_table")
    )
  )
)

server <- function(input, output, session) {
  # Initialize table

  react_values <- reactiveValues()
  react_values$start_time <- Sys.time()

  output$large_table <- render_tabulator({
    message("Starting table render...")

    react_values$start_time <- Sys.time()
    react_values$diff <- NULL

    tabulator(
      data = test_data,
      options = list(
        height = "500px",
        virtualDom = TRUE,
        pagination = TRUE
      ),
      readOnly = "id" # Only make ID column read-only
    )
  })

  # Track when data is loaded
  observeEvent(input$large_table_data, {
    data_new <- tabulator_to_df(input$large_table_data)
    msg <- sprintf(
      "Initialized with %s rows, recieved %s rows",
      n_rows,
      nrow(data_new)
    )
    message(msg)
    if (!is.null(react_values$diff)) {
      react_values$diff <- Sys.time() - react_values$start_time
      message(sprintf("Initialized in %f", react_values$diff))
      react_values$diff <- NULL
    }
  })

  # Track cell edits
  observeEvent(input$large_table_cell_edit, {
    edit_info <- input$large_table_cell_edit
    message(sprintf(
      "Cell edit - Row: %s, Column: %s, Old: %s, New: %s",
      edit_info$row$id,
      edit_info$column,
      edit_info$oldValue,
      edit_info$newValue
    ))
  })
}

# Run the app
runApp(list(ui = ui, server = server), launch.browser = FALSE)
