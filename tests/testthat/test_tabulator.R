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

# Test column configuration
test_that("tabulator handles column configurations correctly", {
  # Test hiding columns
  widget <- tabulator(data = mtcars, hide = c("mpg", "cyl"))
  hidden_cols <- sapply(widget$x$options$columns, function(x) isFALSE(x$visible))
  expect_true(sum(hidden_cols) >= 2)

  # Test fixed columns
  widget <- tabulator(data = mtcars, fixedCols = c("mpg"))
  fixed_cols <- sapply(widget$x$options$columns, function(x) isTRUE(x$frozen))
  expect_true(sum(fixed_cols) >= 1)
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

test_that("tabulatorUpdateWhere function sends correct message", {
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
