#' @import htmlwidgets
#' @importFrom shiny getDefaultReactiveDomain
#' @importFrom jsonlite fromJSON

NULL

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
#' @param add_selector_bar Boolean to add a selector bar (default: FALSE)
#' @param add_select_column Boolean to add a select column (default: FALSE)
#' @param return_select_column Boolean to include selection status in returned data (default: FALSE)
#' @param return_select_column_name Name for the returned selection column (default: "row_select")
#' @param columnOrder A character vector specifying the desired column order (default: NULL)
#'
#' @export
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
    add_selector_bar = FALSE,
    add_select_column = FALSE,
    return_select_column = FALSE,
    return_select_column_name = "row_select",
    columnOrder = NULL) {
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
  # https://tabulator.info/docs/6.3/columns#definition
  columns <- lapply(seq_along(colNames), function(i) {
    pos <- if (!is.null(columnOrder) && colNames[i] %in% columnOrder) {
      which(columnOrder == colNames[i])
    } else {
      i + length(columnOrder)
    }

    col <- list(
      field = colNames[i],
      title = if (is.null(columnHeaders[i])) colNames[i] else columnHeaders[i],
      order = pos
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
      } else if (is.numeric(df[[colNames[i]]])) {
        col$editor <- "number"
      } else if (is.logical(df[[colNames[i]]])) {
        col$editor <- "tickCross"
      } else {
        col$editor <- "input" # Default editor for other types
      }
    }

    # Set formatter for special cases
    if (is.logical(df[[colNames[i]]])) {
      col$formatter <- "tickCross"
    }

    col
  })

  columns <- columns[order(sapply(columns, function(x) x$order))]
  columns <- lapply(columns, function(c) {
    c$order <- NULL
    c
  })

  # Default options
  default_options <- list(
    # shiny_tabulator options
    add_selector_bar = add_selector_bar,
    add_select_column = add_select_column,
    return_select_column = return_select_column,
    return_select_column_name = return_select_column_name,
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
    clipboardPasteAction = "replace",
    clipboardCopyConfig = list(
      rowHeaders = FALSE,
      columnHeaders = FALSE
    ),
    pagination = FALSE,
    layout = ifelse(stretched[1] == "all", "fitDataFill", "fitColumns"),
    responsiveLayout = FALSE
  )

  # Merge user options with defaults
  options <- utils::modifyList(default_options, options)

  # Prepare dependencies
  deps <- htmlwidgets::getDependency("amtabulator", "amtabulator")

  if (!is.null(css)) {
    deps <- c(deps, htmltools::htmlDependency(
      name = "amtabulator-css",
      version = "0.0.1",
      src = dirname(css),
      stylesheet = basename(css)
    ))
  }

  # Create and return the widget
  htmlwidgets::createWidget(
    name = "amtabulator",
    x = list(options = options),
    package = "amtabulator",
    elementId = elementId,
    dependencies = deps
  )
}

#' Convert raw message to data.frame
#'
#' @param message Message from client
#'
#' @export
tabulator_to_df <- function(message) {
  if (length(message$data) == 0) {
    return(data.frame())
  }

  df <- as.data.frame(jsonlite::fromJSON(message$data), stringsAsFactors = FALSE)

  return(df)
}

#' Create a Tabulator output element
#'
#' @param outputId The ID of the output element
#' @param width The width of the element
#' @param height The height of the element
#'
#' @export
tabulator_output <- function(
    outputId,
    width = "100%",
    height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    outputId, "amtabulator",
    width,
    height,
    package = "amtabulator"
  )
}

#' Render a Tabulator widget
#'
#' @param expr An expression that returns a Tabulator configuration
#' @param env The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression?
#'
#' @export
render_tabulator <- function(
    expr,
    env = parent.frame(),
    quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, tabulator_output, env, quoted = TRUE)
}

#' Create a Tabulator proxy object
#'
#' @param input_id The ID of the Tabulator input element
#' @param session The Shiny session object
#'
#' @export
tabulator_proxy <- function(
    input_id,
    session = shiny::getDefaultReactiveDomain()) {
  structure(
    list(
      input_id = session$ns(input_id),
      session = session
    ),
    class = "amtabulator_proxy"
  )
}

#' Trigger data input (refresh)
#'
#' @param proxy A Tabulator proxy object
#'
#' @export
tabulator_trigger_data <- function(proxy) {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }
  proxy$session$sendCustomMessage(
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "trigger_data"
    )
  )
}

#' Update Tabulator data
#'
#' @param proxy A Tabulator proxy object
#' @param data A data frame with updated data
#' @param chunk_size The number of rows to update in each chunk (default: 1000)
#'
#' @export
tabulator_update_data <- function(proxy, data, chunk_size = 1000) {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  data_chunks <- split(data, ceiling(seq_len(nrow(data)) / chunk_size))

  for (i in seq_along(data_chunks)) {
    chunk <- data_chunks[[i]]

    proxy$session$sendCustomMessage(
      type = "tabulator_action",
      message = list(
        id = proxy$input_id,
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
tabulator_update_where <- function(
    proxy,
    col,
    value,
    whereCol,
    whereValue,
    operator = "==",
    chunk_size = 1000) {
  if (!inherits(proxy, "amtabulator_proxy")) {
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
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "update_where",
      value = message
    )
  )
}

#' Add rows to a Tabulator table
#'
#' @param proxy A Tabulator proxy object
#' @param data A list or data frame containing the rows to add
#' @param position Optional position to insert rows ("top" or "bottom", default: "bottom")
#'
#' @export
tabulator_add_rows <- function(proxy, data, position = "bottom") {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  # Validate position parameter
  if (!position %in% c("top", "bottom")) {
    stop("Position must be either 'top' or 'bottom'")
  }

  # Validate data
  if (is.null(data)) {
    stop("Data cannot be NULL")
  }

  if (!is.list(data) && !is.data.frame(data)) {
    stop("Data must be a list or data frame")
  }

  if (length(data) == 0) {
    stop("Data must contain at least one row")
  }

  # Check for mismatched column lengths
  if (is.list(data) || is.data.frame(data)) {
    lengths <- sapply(data, length)
    if (length(unique(lengths)) > 1) {
      stop("All columns in data must have the same length")
    }
  }

  proxy$session$sendCustomMessage(
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "add_rows",
      value = list(
        data = data,
        position = position
      )
    )
  )
}

#' Remove specific rows from a Tabulator table
#'
#' @param proxy A Tabulator proxy object
#' @param row_ids A vector of row IDs to remove
#'
#' @export
tabulator_remove_rows <- function(proxy, row_ids) {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  if (is.null(row_ids) || length(row_ids) == 0) {
    stop("row_ids must be a non-empty vector")
  }

  proxy$session$sendCustomMessage(
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "remove_rows",
      value = row_ids
    )
  )
}

#' Remove the first row from a Tabulator table
#'
#' @param proxy A Tabulator proxy object
#'
#' @export
tabulator_remove_first_row <- function(proxy) {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  proxy$session$sendCustomMessage(
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "remove_first_row"
    )
  )
}

#' Remove the last row from a Tabulator table
#'
#' @param proxy A Tabulator proxy object
#'
#' @export
tabulator_remove_last_row <- function(proxy) {
  if (!inherits(proxy, "amtabulator_proxy")) {
    stop("Invalid tabulator_proxy object")
  }

  proxy$session$sendCustomMessage(
    type = "tabulator_action",
    message = list(
      id = proxy$input_id,
      action = "remove_last_row"
    )
  )
}
