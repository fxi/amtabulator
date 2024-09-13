#' Create a Tabulator widget
#'
#' @param data A data frame or matrix
#' @param options A list of Tabulator.js options
#' @param elementId The ID of the element
#' @param readOnly A boolean for the whole table, or a vector of column ids or names
#' @param columnHeaders Custom column headers
#' @param hide A vector of column ids or names, or a number of columns to hide from left
#' @param fixedCols A vector of column ids or names, or a number of columns to freeze from left
#' @param stretched Stretching mode for columns (default: "all")
#' @param dropDown A list of dropdown options for specific columns
#' @param css Optional path to custom CSS file
#' @param add_selector_bar Boolean to add a selector bar (default: TRUE)
#' @param add_select_column Boolean to add a select column (default: FALSE)
#' @param select_column_name Name for the select column (default: "amSelect")
#'
#' @export
#' @importFrom htmlwidgets createWidget
tabulator <- function(
  data,
  options = list(),
  elementId = NULL,
  readOnly = FALSE,
  columnHeaders = NULL,
  hide = NULL,
  fixedCols = NULL,
  stretched = c("all", "last", "none"),
  dropDown = list(),
  css = NULL,
  add_selector_bar = TRUE,
  add_select_column = FALSE,
  select_column_name = "amSelect"
) {
  # Prepare data and columns
  df <- as.data.frame(data, stringsAsFactors = FALSE)
  colNames <- colnames(df)

  if (is.null(columnHeaders)) {
    columnHeaders <- colNames
  }

  # Helper function to get column indices
  get_col_indices <- function(cols, all_cols) {
    if (is.numeric(cols)) {
      return(cols)
    } else if (is.character(cols)) {
      return(match(cols, all_cols))
    } else if (is.logical(cols)) {
      return(which(cols))
    } else {
      return(integer(0))
    }
  }

  # Prepare readOnly
  if (is.logical(readOnly) && length(readOnly) == 1) {
    readOnly <- rep(readOnly, length(colNames))
  } else {
    readOnly_indices <- get_col_indices(readOnly, colNames)
    readOnly <- rep(FALSE, length(colNames))
    readOnly[readOnly_indices] <- TRUE
  }

  # Prepare hide
  if (is.numeric(hide) && length(hide) == 1) {
    hide <- seq_len(hide)
  } else {
    hide <- get_col_indices(hide, colNames)
  }

  # Prepare fixedCols
  if (is.numeric(fixedCols) && length(fixedCols) == 1) {
    fixedCols <- seq_len(fixedCols)
  } else {
    fixedCols <- get_col_indices(fixedCols, colNames)
  }

  # Prepare columns
  columns <- lapply(seq_along(colNames), function(i) {
    col <- list(
      field = colNames[i],
      title = columnHeaders[i]
    )

    # Handle hidden columns
    if (i %in% hide) {
      col$visible <- FALSE
    }

    # Handle frozen columns
    if (i %in% fixedCols) {
      col$frozen <- TRUE
    }

    # Set editor and formatter based on column type
    if (!isTRUE(readOnly[i])) {
      if (!is.null(dropDown[[colNames[i]]])) {
        col$editor <- "list"
        col$editorParams <- list(values = dropDown[[colNames[i]]])
      } else if (is.numeric(df[[i]])) {
        col$editor <- "number"
      } else if (is.logical(df[[i]])) {
        col$editor <- "tickCross"
      } else {
        col$editor <- "input" # Default editor for other types
      }
    }

    # Set formatter for special cases
    if (is.logical(df[[i]])) {
      col$formatter <- "tickCross"
    }

    col
  })

  # Default options
  default_options <- list(
    # shinyTabulator options
    add_selector_bar = add_selector_bar,
    add_select_column = add_select_column,
    select_column_name = select_column_name,
    # tabulator options
    columns = columns,
    index = NULL,
    height = "600px",
    data = df,
    tooltips = TRUE,
    addRowPos = "top",
    history = TRUE,
    movableColumns = FALSE,
    resizableRows = FALSE,
    clipboard = TRUE,
    clipboardCopyRowRange = "range",
    clipboardPasteParser = "range",
    clipboardPasteAction = "range",
    clipboardCopyConfig = list(
      rowHeaders = FALSE,
      columnHeaders = FALSE
    ),
    pagination = FALSE,
    layout = ifelse(stretched[1] == "all", "fitDataFill", "fitColumns"),
    responsiveLayout = FALSE
  )

  # Merge user options with defaults
  options <- modifyList(default_options, options)

  # Prepare dependencies
  deps <- htmlwidgets::getDependency("tabulator", "shinyTabulator")
  if (!is.null(css)) {
    deps <- c(deps, htmltools::htmlDependency(
      name = "custom-tabulator-css",
      version = "0.1.0",
      src = dirname(css),
      stylesheet = basename(css)
    ))
  }

  # Create and return the widget
  htmlwidgets::createWidget(
    name = "tabulator",
    x = list(options = options),
    package = "shinyTabulator",
    elementId = elementId,
    dependencies = deps
  )
}



#' Convert raw message to data.frame
#'
#' @param message Message from client
#'
#' @export
#' @importFrom htmlwidgets shinyWidgetOutput
tabulatorToDf <- function(message) {
  if (length(message$data) == 0) {
    return(data.frame())
  }

  df <- as.data.frame(jsonlite::fromJSON(message$data), stringsAsFactors = FALSE)

  return(df)
}





#' Create a Tabulator output element
#'
#' @param outputId The ID of the output element
#' @param width The width of the element (default: '100%')
#' @param height The height of the element (default: '400px')
#'
#' @export
#' @importFrom htmlwidgets shinyWidgetOutput
tabulatorOutput <- function(
  outputId,
  width = "100%",
  height = "400px"
) {
  htmlwidgets::shinyWidgetOutput(
    outputId, "tabulator",
    width,
    height,
    package = "shinyTabulator"
  )
}

#' Render a Tabulator widget
#'
#' @param expr An expression that returns a Tabulator configuration
#' @param env The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression?
#'
#' @export
#' @importFrom htmlwidgets shinyRenderWidget
renderTabulator <- function(expr,
  env = parent.frame(),
  quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, tabulatorOutput, env, quoted = TRUE)
}

#' Create a Tabulator proxy object
#'
#' @param inputId The ID of the Tabulator input element
#' @param session The Shiny session object
#'
#' @export
#' @importFrom shiny getDefaultReactiveDomain
tabulatorProxy <- function(inputId,
  session = shiny::getDefaultReactiveDomain()) {
  structure(
    list(
      inputId = session$ns(inputId),
      session = session
    ),
    class = "tabulator_proxy"
  )
}

#' Update Tabulator data
#'
#' @param proxy A Tabulator proxy object
#' @param data A data frame with updated data
#' @param chunk_size The number of rows to update in each chunk (default: 1000)
#'
#' @export
tabulatorUpdateData <- function(proxy, data, chunk_size = 1000) {
  if (!inherits(proxy, "tabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  data_chunks <- split(data, ceiling(seq_len(nrow(data)) / chunk_size))

  for (i in seq_along(data_chunks)) {
    chunk <- data_chunks[[i]]

    proxy$session$sendCustomMessage(
      type = "tabulator-update",
      message = list(
        id = proxy$inputId,
        action = "update_data",
        value = list(
          data = chunk,
          chunk = i,
          total_chunks = length(data_chunks)
        )
      )
    )
  }
}

#' Update Tabulator values using a conditional system
#'
#' @param proxy A Tabulator proxy object
#' @param col The column to update
#' @param value The new value to set
#' @param whereCol The column to check for the condition
#' @param whereValue The value to compare against in the condition
#' @param operator The comparison operator (e.g., ">", "<", "==", etc.)
#' @param chunk_size The number of rows to update in each chunk (default: 1000)
#'
#' @export
tabulatorUpdateWhere <- function(
  proxy,
  col,
  value,
  whereCol,
  whereValue,
  operator = "==",
  chunk_size = 1000) {
  if (!inherits(proxy, "tabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  message <- list(
    col = col,
    value = value,
    whereCol = whereCol,
    whereValue = whereValue,
    operator = operator,
    chunk_size = chunk_size
  )

  proxy$session$sendCustomMessage(
    type = "tabulator-update",
    message = list(id = proxy$inputId, action = "update_where", value = message)
  )
}
