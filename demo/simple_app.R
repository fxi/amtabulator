library(shiny)
# library(amtabulator)


devtools::load_all("./")


# Prepare the iris dataset
iris_data <- iris
names(iris_data) <- gsub("\\.", "_", tolower(names(iris_data)))
iris_data$large <- iris_data$petal_width > 1
iris_data$cat <- seq_len(nrow(iris_data))
iris_data <- iris_data[, c("cat", setdiff(names(iris_data), "cat"))]
iris_data$hidden <- "a"

ui <- fluidPage(
  titlePanel("Iris Dataset Tabulator Demo with Event Listeners"),
  sidebarLayout(
    sidebarPanel(
      actionButton("updateBtn", "Update Random sepal length"),
      actionButton("updateConditionalBtn", "Update sepal Length 0 where Petal Length > 5"),
      actionButton("submitBtn", "Submit"),
      hr(),
      h4("Event Summaries"),
      verbatimTextOutput("cellEditSummary"),
      verbatimTextOutput("selectionSummary"),
      verbatimTextOutput("dataChangedSummary"),
      verbatimTextOutput("submitSummary")
    ),
    mainPanel(
      tabulator_output("iris_table", height = "400px")
    )
  )
)

server <- function(input, output, session) {
  # Initialize data
  react_iris_data <- reactiveVal(iris_data)
  col_names <- names(iris_data)
  read_only <- col_names[!(col_names %in% "species")]

  output$iris_table <- render_tabulator({
    tabulator(
      data = isolate(react_iris_data()), # prevent re-initialization
      add_selector_bar = TRUE,
      add_select_column = TRUE,
      return_select_column_name = "am_select",
      return_select_column = TRUE,
      readOnly = read_only,
      fixed = "cat",
      stretched = "last",
      columnOrder = c("cat", "species", "large"),
      hide = "hidden",
      options = list(
        index = "cat"
      )
    )
  })


  observeEvent(input$updateBtn, {
    proxy <- tabulator_proxy("iris_table")
    new_data <- react_iris_data()
    new_data$sepal_length <- round(runif(nrow(new_data), min = 4, max = 8), 1)
    react_iris_data(new_data)
    tabulator_update_data(proxy, react_iris_data())
  })

  observeEvent(input$updateConditionalBtn, {
    proxy <- tabulator_proxy("iris_table")
    tabulator_update_where(proxy,
      col = "sepal_length",
      value = 0,
      whereCol = "petal_length",
      whereValue = 5,
      operator = ">"
    )
  })

  # Cell edit event listener
  observeEvent(input$iris_table_cell_edit, {
    edit_info <- input$iris_table_cell_edit
    output$cellEditSummary <- renderText({
      sprintf(
        "Cell Edited: Row %s, Column: %s, Old Value: %s, New Value: %s",
        edit_info$row$cat, edit_info$column, edit_info$oldValue, edit_info$newValue
      )
    })
  })

  # Selection event listener
  observeEvent(input$iris_table_selection, {
    df <- tabulator_to_df(input$iris_table_selection)
    output$selectionSummary <- renderText({
      sprintf("Rows Selected: %d", nrow(df))
    })
  })

  observeEvent(input$submitBtn, {
    df <- tabulator_to_df(input$iris_table_data)
    df_select <- tabulator_to_df(input$iris_table_selection)

    n_df_select <- nrow(df_select)
    n_df <- nrow(df)
    n_df_checked <- nrow(df[df$am_select, ])

    output$submitSummary <- renderText({
      sprintf(
        "Submited
        \n-table: %d
        \n-selected %d
        \n-checked %d",
        n_df,
        n_df_select,
        n_df_checked
      )
    })
  })
}
runApp(list(ui = ui, server = server), launch.browser = FALSE)
