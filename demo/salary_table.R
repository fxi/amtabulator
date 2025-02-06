library(shiny)
library(amtabulator)

# Sample data
demo_data <- data.frame(
  id = 1:5,
  name = c("John", "Jane", "Bob", "Alice", "Charlie"),
  status = c("Active", "Away", "Active", "Inactive", "Away"),
  skill_level = c("Beginner", "Expert", "Intermediate", "Expert", "Beginner"),
  department = c("IT", "HR", "IT", "Finance", "HR"),
  salary = c(50000, 60000, 55000, 65000, 58000),
  stringsAsFactors = FALSE
)

# Define dropdown options
status_options <- c("Active", "Away", "Inactive")
skill_options <- c("Beginner", "Intermediate", "Expert")
department_options <- c("IT", "HR", "Finance", "Marketing", "Sales")

ui <- fluidPage(
  titlePanel("Tabulator Dropdown Demo"),
  fluidRow(
    column(
      6,
      # Main tabulator widget
      tabulator_output("demo_table"),
    ),
    column(
      6,
      selectInput("raise_dept", "Select Department",
        choices = department_options
      ),
      numericInput("raise_amount", "Raise Percentage",
        value = 10, min = 1, max = 100
      ),
      actionButton("apply_raise", "Apply Raise")
    ),
  )
)

server <- function(input, output, session) {
  # Initialize tabulator
  output$demo_table <- render_tabulator({
    tabulator(
      data = demo_data,
      options = list(
        add_selector_bar = FALSE,
        height = "400px",
        initialSort = list(
          list(column = "name", dir = "asc")
        )
      ),
      add_export_bar = TRUE,
      # Column configuration
      columnHeaders = c(
        "ID",
        "Name",
        "Status",
        "Skill Level",
        "Department",
        "Salary"
      ),
      # Set specific columns as read-only
      readOnly = c("id"),
      # Configure dropdowns for multiple columns
      dropDown = list(
        status = status_options,
        skill_level = skill_options,
        department = department_options
      )
    )
  })

  # Handle data changes
  observeEvent(input$demo_table_data, {
    data <- tabulator_to_df(input$demo_table_data)
    print(data)
  })

  # Handle salary update button
  observeEvent(input$apply_raise, {
    # Get current data
    data <- tabulator_to_df(input$demo_table_data)

    # Calculate new salaries for selected department
    dept_rows <- data$department == input$raise_dept
    new_salaries <- data$salary
    new_salaries[dept_rows] <- round(new_salaries[dept_rows] * (1 + input$raise_amount / 100))


    # Update using proxy
    proxy <- tabulator_proxy("demo_table")

    new_data <- data.frame(
      id = data$id,
      name = data$name,
      status = data$status,
      skill_level = data$skill_level,
      department = data$department,
      salary = new_salaries
    )

    tabulator_update_data(proxy, new_data)
  })
}


runApp(list(ui = ui, server = server), launch.browser = FALSE)
