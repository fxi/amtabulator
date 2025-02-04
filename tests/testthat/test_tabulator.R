library(testthat)
library(amtabulator)
library(shiny)
library(htmlwidgets)

# Test basic widget creation
test_that("tabulator function creates a widget", {
  widget <- tabulator(data = mtcars)
  expect_s3_class(widget, "htmlwidget")
  # The widget structure is different - let's check the correct structure
  expect_type(widget$x$options$data, "list")
  expect_true(is.list(widget$x$options$columns))
})

# Test widget options
test_that("tabulator widget handles options correctly", {
  # Test with custom options
  custom_options <- list(height = "800px", movableColumns = TRUE)
  widget <- tabulator(data = mtcars, options = custom_options)
  expect_equal(widget$x$options$height, "800px")
  expect_true(widget$x$options$movableColumns)
})

# Test readOnly parameter
test_that("tabulator handles readOnly parameter correctly", {
  df <- data.frame(
    cat = c("A", "B"),
    ph = c(7.0, 7.5),
    turbid = c(0.5, 0.7),
    caco3 = c(10, 15)
  )

  # Test boolean TRUE for all columns
  widget <- tabulator(df, readOnly = TRUE)
  expect_true(all(sapply(widget$x$options$columns, function(col) is.null(col$editor))))

  # Test boolean FALSE for all columns
  widget <- tabulator(df, readOnly = FALSE)
  expect_true(all(sapply(widget$x$options$columns, function(col) !is.null(col$editor))))

  # Test column indices
  widget <- tabulator(df, readOnly = c(1, 3))
  cols <- widget$x$options$columns
  expect_null(cols[[1]]$editor)
  expect_false(is.null(cols[[2]]$editor))
  expect_null(cols[[3]]$editor)
  expect_false(is.null(cols[[4]]$editor))

  # Test column names
  widget <- tabulator(df, readOnly = c("cat", "turbid"))
  cols <- widget$x$options$columns
  expect_null(cols[[1]]$editor)
  expect_false(is.null(cols[[2]]$editor))
  expect_null(cols[[3]]$editor)
  expect_false(is.null(cols[[4]]$editor))

  # Test error on mixing types
  expect_error(
    tabulator(df, readOnly = c(1, "cat")),
    "readOnly must be either all indices or all names, no mixing allowed"
  )

  # Test error on invalid column names
  expect_error(
    tabulator(df, readOnly = c("invalid", "column")),
    "Column names not found"
  )

  # Test error on invalid column indices
  expect_error(
    tabulator(df, readOnly = c(0, 5)),
    "Column indices must be between 1 and"
  )
})

# Test fixedCols parameter
test_that("tabulator handles fixedCols parameter correctly", {
  df <- data.frame(
    cat = c("A", "B"),
    ph = c(7.0, 7.5),
    turbid = c(0.5, 0.7),
    caco3 = c(10, 15)
  )

  # Test NULL
  widget <- tabulator(df, fixedCols = NULL)
  cols <- widget$x$options$columns
  expect_true(all(sapply(cols, function(col) isFALSE(col$frozen))))

  # Test column indices
  widget <- tabulator(df, fixedCols = 3)
  cols <- widget$x$options$columns
  expect_true(cols[[1]]$frozen)
  expect_true(cols[[2]]$frozen)
  expect_true(cols[[3]]$frozen)
  expect_false(cols[[4]]$frozen)

  # Test column names
  widget <- tabulator(df, fixedCols = "turbid")
  cols <- widget$x$options$columns
  expect_true(cols[[1]]$frozen)
  expect_true(cols[[2]]$frozen)
  expect_true(cols[[3]]$frozen)
  expect_false(cols[[4]]$frozen)

  # Test error on invalid column names
  expect_error(
    tabulator(df, fixedCols = "invalid"),
    "Column names not found"
  )

  # Test error on invalid column indices
  expect_error(
    tabulator(df, fixedCols = 5),
    "Column indices must be between 1 and"
  )
})

# Test hide parameter
test_that("tabulator handles hide parameter correctly", {
  df <- data.frame(
    cat = c("A", "B"),
    ph = c(7.0, 7.5),
    turbid = c(0.5, 0.7),
    caco3 = c(10, 15)
  )

  # Test NULL
  widget <- tabulator(df, hide = NULL)
  expect_true(all(sapply(widget$x$options$columns, function(col) is.null(col$visible) || col$visible)))

  # Test column indices
  widget <- tabulator(df, hide = c(1, 3))
  cols <- widget$x$options$columns
  expect_false(cols[[1]]$visible)
  expect_true(is.null(cols[[2]]$visible) || cols[[2]]$visible)
  expect_false(cols[[3]]$visible)
  expect_true(is.null(cols[[4]]$visible) || cols[[4]]$visible)

  # Test column names
  widget <- tabulator(df, hide = c("cat", "turbid"))
  cols <- widget$x$options$columns
  expect_false(cols[[1]]$visible)
  expect_true(is.null(cols[[2]]$visible) || cols[[2]]$visible)
  expect_false(cols[[3]]$visible)
  expect_true(is.null(cols[[4]]$visible) || cols[[4]]$visible)

  # Test error on invalid column names
  expect_error(
    tabulator(df, hide = "invalid"),
    "Column names not found"
  )

  # Test error on invalid column indices
  expect_error(
    tabulator(df, hide = 5),
    "Column indices must be between 1 and"
  )
})

# Test columnOrder parameter
test_that("tabulator handles columnOrder parameter correctly", {
  df <- data.frame(
    cat = c("A", "B"),
    ph = c(7.0, 7.5),
    turbid = c(0.5, 0.7),
    caco3 = c(10, 15)
  )

  # Test NULL
  widget <- tabulator(df, columnOrder = NULL)
  cols <- widget$x$options$columns
  expect_equal(sapply(cols, function(col) col$field), c("cat", "ph", "turbid", "caco3"))

  # Test specific order with column names
  widget <- tabulator(df, columnOrder = c("cat", "caco3"))
  cols <- widget$x$options$columns
  expect_equal(sapply(cols, function(col) col$field), c("cat", "caco3", "ph", "turbid"))

  # Test specific order with column indices
  widget <- tabulator(df, columnOrder = c(1, 4))
  cols <- widget$x$options$columns
  expect_equal(sapply(cols, function(col) col$field), c("cat", "caco3", "ph", "turbid"))

  # Test error on invalid column names
  expect_error(
    tabulator(df, columnOrder = c("invalid", "column")),
    "Column names not found"
  )

  # Test error on invalid column indices
  expect_error(
    tabulator(df, columnOrder = c(0, 5)),
    "Column indices must be between 1 and"
  )
})

# Test columns parameter
test_that("tabulator handles columns parameter correctly", {
  df <- data.frame(
    A = 1:3,
    B = 4:6,
    C = 7:9
  )

  # Define custom columns
  custom_columns <- list(
    list(field = "A", title = "Column A", editor = "input"),
    list(field = "C", title = "Column C", editor = "number")
  )

  # Test with primary columns parameter
  widget <- tabulator(data = df, columns = custom_columns)
  expect_equal(widget$x$options$columns, custom_columns)
  expect_equal(length(widget$x$options$columns), 2)
  expect_equal(widget$x$options$columns[[1]]$field, "A")
  expect_equal(widget$x$options$columns[[2]]$field, "C")

  # Test with columns in options
  options_columns <- list(
    list(field = "B", title = "Column B", editor = "number"),
    list(field = "C", title = "Column C", editor = "input")
  )
  widget_options <- tabulator(data = df, options = list(columns = options_columns))
  expect_equal(widget_options$x$options$columns, options_columns)
  expect_equal(length(widget_options$x$options$columns), 2)
  expect_equal(widget_options$x$options$columns[[1]]$field, "B")
  expect_equal(widget_options$x$options$columns[[2]]$field, "C")

  # Test primary columns parameter takes precedence over options columns
  widget_both <- tabulator(
    data = df,
    columns = custom_columns,
    options = list(columns = options_columns)
  )
  expect_equal(widget_both$x$options$columns, custom_columns)
  expect_equal(length(widget_both$x$options$columns), 2)
  expect_equal(widget_both$x$options$columns[[1]]$field, "A")
  expect_equal(widget_both$x$options$columns[[2]]$field, "C")

  # Test without any columns parameter (auto-generation)
  widget_auto <- tabulator(data = df)
  expect_equal(length(widget_auto$x$options$columns), 3)
  expect_equal(widget_auto$x$options$columns[[1]]$field, "A")
  expect_equal(widget_auto$x$options$columns[[2]]$field, "B")
  expect_equal(widget_auto$x$options$columns[[3]]$field, "C")
})

# Test empty table initialization and proxy operations
test_that("tabulator handles empty table initialization and updates", {
  # Create empty table with only columns defined
  columns <- list(
    list(field = "A", title = "Column A", formatter = "number"),
    list(field = "B", title = "Column B", formatter = "string")
  )
  widget <- tabulator(
    data = NULL,
    columns = columns
  )
  
  # Check initial state
  expect_equal(widget$x$options$columns, columns)
  expect_equal(nrow(widget$x$options$data), 0)
  
  # Test proxy operations on empty table
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )
  proxy <- tabulator_proxy("test", session)
  
  # Test update_data
  new_data <- data.frame(A = 1:2, B = c("x", "y"))
  tabulator_update_data(proxy, new_data)
  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "update_data")
  expect_equal(session$lastCustomMessage$message$value$data, new_data[1:2,])
  
  # Test replace_data
  replace_data <- data.frame(A = 3:4, B = c("z", "w"))
  tabulator_replace_data(proxy, replace_data)
  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "replace_data")
  expect_equal(session$lastCustomMessage$message$value, replace_data)
})

# Test replace_data functionality and structure
test_that("tabulator_replace_data maintains data structure and replaces values", {
  # Create a mock session
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )
  proxy <- tabulator_proxy("test", session)
  
  # Test with different data structures
  # 1. Simple numeric data
  numeric_data <- data.frame(
    A = 1:3,
    B = 4:6
  )
  tabulator_replace_data(proxy, numeric_data)
  expect_equal(session$lastCustomMessage$message$value, numeric_data)
  
  # 2. Mixed data types
  mixed_data <- data.frame(
    str = c("a", "b", "c"),
    num = 1:3,
    bool = c(TRUE, FALSE, TRUE),
    stringsAsFactors = FALSE
  )
  tabulator_replace_data(proxy, mixed_data)
  expect_equal(session$lastCustomMessage$message$value, mixed_data)
  
  # 3. Data with special characters
  special_data <- data.frame(
    name = c("John's", "Mary-Jane", "Smith & Co"),
    value = 1:3,
    stringsAsFactors = FALSE
  )
  tabulator_replace_data(proxy, special_data)
  expect_equal(session$lastCustomMessage$message$value, special_data)
  
  # Test error handling
  expect_error(tabulator_replace_data(proxy, list(a = 1)), "data must be a data.frame")
  expect_error(tabulator_replace_data(proxy, NULL), "data must be a data.frame")
})

test_that("tabulator_output function creates a shiny output", {
  output <- tabulator_output("test")

  # Test the overall structure
  expect_s3_class(output, "shiny.tag.list")

  # Test the div structure
  div <- output[[1]]
  expect_s3_class(div, "shiny.tag")
  expect_equal(div$name, "div")

  # Test the attributes
  expect_equal(div$attribs$id, "test")
  expect_equal(div$attribs$style, "width:100%;height:400px;")
  expect_equal(div$attribs$class[1], "amtabulator html-widget html-widget-output shiny-report-size")

  # Test dependencies
  deps <- attr(output, "html_dependencies")
  expect_true(length(deps) >= 2) # At least htmlwidgets and amtabulator

  # Check for shiny-tabulator dependency
  tabulator_dep <- deps[[length(deps)]] # Usually the last dependency
  expect_equal(tabulator_dep$name, "amtabulator")
  expect_equal(tabulator_dep$package, "amtabulator")
})

test_that("render_tabulator function creates a render function", {
  render_func <- render_tabulator({
    tabulator(mtcars)
  })
  expect_type(render_func, "closure")
})

# Test proxy functionality
test_that("tabulator_proxy function creates a proxy object", {
  # Create a mock session properly
  session <- structure(list(ns = function(x) x), class = "ShinySession")
  proxy <- tabulator_proxy("test", session)
  expect_s3_class(proxy, "amtabulator_proxy")
  expect_equal(proxy$input_id, "test")
})

test_that("tabulator_update_data function sends correct message", {
  # Create a proper mock session with the required methods
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)
  tabulator_update_data(proxy, mtcars[1:2, ])

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "update_data")
  expect_true(!is.null(session$lastCustomMessage$message$value$data))
})

test_that("tabulator_update_where function sends correct message", {
  # Create a proper mock session with the required methods
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)

  tabulator_update_where(
    proxy,
    col = "mpg",
    value = 100,
    whereCol = "hp",
    whereValue = 150,
    operator = ">"
  )

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "update_where")
  expect_equal(session$lastCustomMessage$message$value$col, "mpg")
  expect_equal(session$lastCustomMessage$message$value$whereValue, 150)
})

# Test data conversion
test_that("tabulator_to_df converts message correctly", {
  # Test empty message
  empty_msg <- list(data = character(0))
  expect_equal(dim(tabulator_to_df(empty_msg))[1], 0)

  # Test with data
  json_data <- jsonlite::toJSON(mtcars[1:2, ])
  msg <- list(data = json_data)
  converted_df <- tabulator_to_df(msg)
  expect_s3_class(converted_df, "data.frame")
  expect_equal(nrow(converted_df), 2)
})

# Test row manipulation functions
test_that("tabulator_add_rows sends correct message", {
  # Create a mock session
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)

  # Test adding rows at bottom (default)
  new_rows <- list(
    name = c("John", "Jane"),
    age = c(25, 30)
  )
  tabulator_add_rows(proxy, new_rows)

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "add_rows")
  expect_equal(session$lastCustomMessage$message$value$data, new_rows)
  expect_equal(session$lastCustomMessage$message$value$position, "bottom")

  # Test adding rows at top
  tabulator_add_rows(proxy, new_rows, position = "top")
  expect_equal(session$lastCustomMessage$message$value$position, "top")

  # Test with invalid position
  expect_error(tabulator_add_rows(proxy, new_rows, position = "invalid"))
})

test_that("tabulator_remove_rows sends correct message", {
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)

  # Test removing specific rows
  row_ids <- c("row1", "row2")
  tabulator_remove_rows(proxy, row_ids)

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "remove_rows")
  expect_equal(session$lastCustomMessage$message$value, row_ids)
})

test_that("tabulator_remove_first_row sends correct message", {
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)

  tabulator_remove_first_row(proxy)

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "remove_first_row")
})

test_that("tabulator_remove_last_row sends correct message", {
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )

  proxy <- tabulator_proxy("test", session)

  tabulator_remove_last_row(proxy)

  expect_equal(session$lastCustomMessage$type, "tabulator_action")
  expect_equal(session$lastCustomMessage$message$action, "remove_last_row")
})

test_that("row manipulation functions validate proxy input", {
  not_a_proxy <- list(input_id = "test")

  # Test error handling for invalid proxy
  expect_error(tabulator_add_rows(not_a_proxy, list()), "Invalid tabulator_proxy object")
  expect_error(tabulator_remove_rows(not_a_proxy, c()), "Invalid tabulator_proxy object")
  expect_error(tabulator_remove_first_row(not_a_proxy), "Invalid tabulator_proxy object")
  expect_error(tabulator_remove_last_row(not_a_proxy), "Invalid tabulator_proxy object")
})

test_that("tabulator_add_rows validates input data", {
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {},
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )
  proxy <- tabulator_proxy("test", session)

  # Test with empty data
  expect_error(tabulator_add_rows(proxy, list()))

  # Test with NULL data
  expect_error(tabulator_add_rows(proxy, NULL))

  # Test with mismatched column lengths
  bad_data <- list(
    name = c("John", "Jane"),
    age = c(25)  # One less value than names
  )
  expect_error(tabulator_add_rows(proxy, bad_data))
})

# Integration test - combining multiple operations
test_that("row manipulation functions work together", {
  session <- structure(
    list(
      ns = function(x) x,
      sendCustomMessage = function(type, message) {
        session$lastCustomMessage <<- list(type = type, message = message)
      },
      lastCustomMessage = NULL
    ),
    class = "ShinySession"
  )
  proxy <- tabulator_proxy("test", session)

  # Add rows
  new_rows <- list(name = c("John", "Jane"), age = c(25, 30))
  tabulator_add_rows(proxy, new_rows)
  expect_equal(session$lastCustomMessage$message$action, "add_rows")

  # Remove specific rows
  tabulator_remove_rows(proxy, c("row1"))
  expect_equal(session$lastCustomMessage$message$action, "remove_rows")

  # Remove first row
  tabulator_remove_first_row(proxy)
  expect_equal(session$lastCustomMessage$message$action, "remove_first_row")

  # Remove last row
  tabulator_remove_last_row(proxy)
  expect_equal(session$lastCustomMessage$message$action, "remove_last_row")
})
