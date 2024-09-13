library(shiny)
library(shinyTabulator) # Assuming this is the name of your package

# Prepare the iris dataset
iris_data <- iris
names(iris_data) <- gsub("\\.", "_", tolower(names(iris_data)))
iris_data$large <- iris_data$petal_width > 1
iris_data$cat <- seq_len(nrow(iris_data))
iris_data <- iris_data[, c("cat", setdiff(names(iris_data), "cat"))]

devtools::load_all()



ui <- fluidPage(
  titlePanel("Iris Dataset Tabulator Demo with Event Listeners"),
  sidebarLayout(
    sidebarPanel(
      actionButton("updateBtn", "Update Random sepal length"),
      actionButton("updateConditionalBtn", "Update sepal Length 0 where Petal Length > 5"),
      hr(),
      h4("Event Summaries"),
      verbatimTextOutput("cellEditSummary"),
      verbatimTextOutput("selectionSummary"),
      verbatimTextOutput("dataChangedSummary")
    ),
    mainPanel(
      tabulatorOutput("irisTable")
    )
  )
)

server <- function(input, output, session) {
  # Initialize data
  react_iris_data <- reactiveVal(iris_data)

  read_only <- !(names(iris_data) %in% "species")

  output$irisTable <- renderTabulator({
    tabulator(
      data = isolate(react_iris_data()), # prevent re-initialization
      add_selector_bar = TRUE,
      add_select_column = TRUE,
      readOnly = read_only,
      fixed = "cat",
      options = list(
        index = "cat"
      )
    )
  })

  observeEvent(input$updateBtn, {
    proxy <- tabulatorProxy("irisTable")
    new_data <- react_iris_data()
    new_data$sepal_length <- round(runif(nrow(new_data), min = 4, max = 8), 1)
    react_iris_data(new_data)
    tabulatorUpdateData(proxy, new_data)
  })

  observeEvent(input$updateConditionalBtn, {
    proxy <- tabulatorProxy("irisTable")
    tabulatorUpdateWhere(proxy,
      col = "sepal_length",
      value = 0,
      whereCol = "petal_length",
      whereValue = 5,
      operator = ">"
    )
  })

  # Cell edit event listener
  observeEvent(input$irisTable_cell_edit, {
    edit_info <- input$irisTable_cell_edit
    output$cellEditSummary <- renderText({
      sprintf(
        "Cell Edited: Row %s, Column: %s, Old Value: %s, New Value: %s",
        edit_info$row$cat, edit_info$column, edit_info$oldValue, edit_info$newValue
      )
    })
  })

  # Selection event listener
  observeEvent(input$irisTable_data_selection, {
    df <- tabulatorToDf(input$irisTable_data_selection)
    output$selectionSummary <- renderText({
      sprintf("Rows Selected: %d", nrow(df))
    })
  })

  # Data changed event listener
  observeEvent(input$irisTable_data_changed, {
    df <- tabulatorToDf(input$irisTable_data_changed)
    browser()
    output$dataChangedSummary <- renderText({
      sprintf("Data Changed: %d rows affected", nrow(df))
    })
  })
}
runApp(list(ui = ui, server = server), launch.browser = FALSE)
