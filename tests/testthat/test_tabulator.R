library(testthat)
library(shinyTabulator)
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

test_that("tabulatorOutput function creates a shiny output", {
  output <- tabulatorOutput("test")
  
  # Test the overall structure
  expect_s3_class(output, "shiny.tag.list")
  
  # Test the div structure
  div <- output[[1]]
  expect_s3_class(div, "shiny.tag")
  expect_equal(div$name, "div")
  
  # Test the attributes
  expect_equal(div$attribs$id, "test")
  expect_equal(div$attribs$style, "width:100%;height:400px;")
  expect_equal(div$attribs$class[1], "tabulator html-widget html-widget-output shiny-report-size")
  
  # Test dependencies
  deps <- attr(output, "html_dependencies")
  expect_true(length(deps) >= 2)  # At least htmlwidgets and shiny-tabulator
  
  # Check for shiny-tabulator dependency
  tabulator_dep <- deps[[length(deps)]]  # Usually the last dependency
  expect_equal(tabulator_dep$name, "shiny-tabulator")
  expect_equal(tabulator_dep$package, "shinyTabulator")
})

test_that("renderTabulator function creates a render function", {
  render_func <- renderTabulator({tabulator(mtcars)})
  expect_type(render_func, "closure")
})

# Test proxy functionality
test_that("tabulatorProxy function creates a proxy object", {
  # Create a mock session properly
  session <- structure(list(ns = function(x) x), class = "ShinySession")
  proxy <- tabulatorProxy("test", session)
  expect_s3_class(proxy, "tabulator_proxy")
  expect_equal(proxy$inputId, "test")
})

test_that("tabulatorUpdateData function sends correct message", {
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
  
  proxy <- tabulatorProxy("test", session)
  tabulatorUpdateData(proxy, mtcars[1:2,])
  
  expect_equal(session$lastCustomMessage$type, "tabulator-update")
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
  
  proxy <- tabulatorProxy("test", session)
  
  tabulatorUpdateWhere(
    proxy, 
    col = "mpg", 
    value = 100, 
    whereCol = "hp", 
    whereValue = 150, 
    operator = ">"
  )
  
  expect_equal(session$lastCustomMessage$type, "tabulator-update")
  expect_equal(session$lastCustomMessage$message$action, "update_where")
  expect_equal(session$lastCustomMessage$message$value$col, "mpg")
  expect_equal(session$lastCustomMessage$message$value$whereValue, 150)
})

# Test data conversion
test_that("tabulatorToDf converts message correctly", {
  # Test empty message
  empty_msg <- list(data = character(0))
  expect_equal(dim(tabulatorToDf(empty_msg))[1], 0)
  
  # Test with data
  json_data <- jsonlite::toJSON(mtcars[1:2, ])
  msg <- list(data = json_data)
  converted_df <- tabulatorToDf(msg)
  expect_s3_class(converted_df, "data.frame")
  expect_equal(nrow(converted_df), 2)
})
