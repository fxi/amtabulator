library(shiny)
devtools::load_all()

# Sample data
initial_data <- data.frame(
  id = 1:5,
  name = c("Alice", "Bob", "Charlie", "David", "Eve"),
  age = c(25, 30, 35, 40, 45),
  city = c("New York", "London", "Paris", "Tokyo", "Berlin"),
  stringsAsFactors = FALSE
)

ui <- fluidPage(
  titlePanel("Tabulator Row Manipulation Demo"),
  sidebarLayout(
    sidebarPanel(
      h4("Add Row"),
      textInput("new_name", "Name"),
      numericInput("new_age", "Age", value = 25),
      textInput("new_city", "City"),
      radioButtons("add_position", "Add Position",
        choices = c("Bottom" = "bottom", "Top" = "top")
      ),
      actionButton("add_btn", "Add Row", class = "btn-primary"),
      hr(),
      h4("Remove Specific Row"),
      numericInput("remove_id", "Row ID to Remove", value = 1),
      actionButton("remove_btn", "Remove Row", class = "btn-danger"),
      hr(),
      actionButton("remove_first_btn", "Remove First Row", class = "btn-warning"),
      actionButton("remove_last_btn", "Remove Last Row", class = "btn-warning")
    ),
    mainPanel(
      tabulator_output("table")
    )
  )
)

server <- function(input, output, session) {
  # Initialize the table
  output$table <- render_tabulator({
    tabulator(
      data = initial_data,
      options = list(
        layout = "fitColumns",
        pagination = FALSE,
        index = "id", # Important for row removal by ID
        columns = list(
          list(title = "ID", field = "id"),
          list(title = "Name", field = "name"),
          list(title = "Age", field = "age"),
          list(title = "City", field = "city")
        )
      )
    )
  })

  # Create proxy
  proxy <- tabulator_proxy("table")

  # Add row handler
  observeEvent(input$add_btn, {
    if (nchar(input$new_name) > 0 && nchar(input$new_city) > 0) {
      data <- tabulator_to_df(input$table_data)

      new_data <- list(
        id = max(data$id) + 1,
        name = input$new_name,
        age = input$new_age,
        city = input$new_city
      )

      tabulator_add_rows(proxy, new_data, position = input$add_position)

      # Clear inputs
      updateTextInput(session, "new_name", value = "")
      updateNumericInput(session, "new_age", value = 25)
      updateTextInput(session, "new_city", value = "")
    }
  })

  # Remove specific row handler
  observeEvent(input$remove_btn, {
    if (!is.na(input$remove_id)) {
      tabulator_remove_rows(proxy, input$remove_id)
    }
  })

  # Remove first row handler
  observeEvent(input$remove_first_btn, {
    tabulator_remove_first_row(proxy)
  })

  # Remove last row handler
  observeEvent(input$remove_last_btn, {
    tabulator_remove_last_row(proxy)
  })

  # Listen for table changes
  observeEvent(input$table_data, {
    data <- tabulator_to_df(input$table_data)
    print(paste("Table updated. Now has", nrow(data), "rows"))
  })
}

runApp(list(ui = ui, server = server), launch.browser = FALSE)
