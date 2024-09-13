
library(testthat)
library(shinyTabulator)

test_that("tabulator function creates a widget", {
  widget <- tabulator(data = mtcars)
  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$name, "tabulator")
})

test_that("tabulatorOutput function creates a shiny output", {
  output <- tabulatorOutput("test")
  expect_type(output, "list")
  expect_equal(output$name, "tabulator")
})

test_that("renderTabulator function creates a render function", {
  render_func <- renderTabulator({tabulator(mtcars)})
  expect_type(render_func, "closure")
})

test_that("tabulatorProxy function creates a proxy object", {
  proxy <- tabulatorProxy("test")
  expect_s3_class(proxy, "tabulator_proxy")
})

test_that("tabulatorUpdateData function sends correct message", {
  session <- shiny::MockShinySession$new()
  proxy <- tabulatorProxy("test", session)

  session$userData$tabulator_index_col <- "row.names"

  tabulatorUpdateData(proxy, mtcars)

  expect_equal(session$lastCustomMessage$type, "tabulator-update")
  expect_equal(session$lastCustomMessage$message$action, "updateData")
})

test_that("tabulatorUpdateWhere function sends correct message", {
  session <- shiny::MockShinySession$new()
  proxy <- tabulatorProxy("test", session)

  tabulatorUpdateWhere(proxy, col = "mpg", value = 100, whereCol = "hp", whereValue = 150, operator = ">")

  expect_equal(session$lastCustomMessage$type, "tabulator-update")
  expect_equal(session$lastCustomMessage$message$action, "updateWhere")
})
