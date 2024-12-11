#' @import htmlwidgets
#' @importFrom shiny getDefaultReactiveDomain
#' @importFrom jsonlite fromJSON

NULL

#' Helper function to validate and get column indices.
#'
#' @param cols Columns specified as indices or names.
#' @param all_cols All available column names.
#' @keywords internal
get_col_indices <- function(cols, all_cols) {
  if (is.null(cols)) {
    return(integer(0))
  }

  if (is.numeric(cols)) {
    if (any(cols < 1 | cols > length(all_cols))) {
      stop("Column indices must be between 1 and ", length(all_cols))
    }
    return(cols)
  } else if (is.character(cols)) {
    idx <- match(cols, all_cols)
    if (any(is.na(idx))) {
      stop("Column names not found: ", paste(cols[is.na(idx)], collapse = ", "))
    }
    return(idx)
  }
  stop("Columns must be specified as either indices or names")
}

#' Helper function to create columns configuration.
#'
#' @param df Data frame containing the data.
#' @param colNames Column names.
#' @param columnHeaders Custom column headers.
#' @param readOnly Read-only columns.
#' @param hide Columns to hide.
#' @param fixedCols Columns to fix.
#' @param columnOrder Desired column order.
#' @param dropDown List of dropdown options.
#' @keywords internal
create_columns <- function(
  df,
  colNames,
  columnHeaders,
  readOnly,
  hide,
  fixedCols,
  columnOrder,
  dropDown
) {
  # Handle readOnly
  readonly_cols <- rep(FALSE, length(colNames))
  if (!is.null(readOnly)) {
    if (is.logical(readOnly)) {
      if (length(readOnly) == 1) {
        readonly_cols <- rep(readOnly, length(colNames))
      } else {
        stop("If readOnly is logical, it must be a single value")
      }
    } else {
      # Validate types before any operations
      if (length(readOnly) == 0) {
        stop("readOnly cannot be empty")
      }

      # Check for mixed types
      has_numeric <- any(sapply(readOnly, function(x) is.numeric(x) || (is.character(x) && grepl("^[0-9]+$", x))))
      has_character <- any(sapply(readOnly, function(x) is.character(x) && !grepl("^[0-9]+$", x)))

      if (has_numeric && has_character) {
        stop("readOnly must be either all indices or all names, no mixing allowed")
      }

      # Now we can safely get indices
      if (has_numeric) {
        idx <- get_col_indices(as.numeric(readOnly), colNames)
      } else {
        idx <- get_col_indices(readOnly, colNames)
      }
      readonly_cols[idx] <- TRUE
    }
  }

  # Handle hide
  hidden_cols <- get_col_indices(hide, colNames)

  # Handle fixedCols
  fixed_cols <- integer(0)
  if (!is.null(fixedCols)) {
    idx <- get_col_indices(fixedCols, colNames)
    fixed_cols <- seq_len(max(idx))
  }

  # Handle columnOrder
  final_order <- seq_along(colNames)
  if (!is.null(columnOrder)) {
    ordered_idx <- get_col_indices(columnOrder, colNames)
    remaining_idx <- setdiff(final_order, ordered_idx)
    final_order <- c(ordered_idx, remaining_idx)
  }

  columns <- lapply(final_order, function(i) {
    col <- list(
      field = colNames[i],
      title = columnHeaders[i]
    )

    # Handle visibility
    if (i %in% hidden_cols) {
      col$visible <- FALSE
    }

    # Handle frozen columns
    if (i %in% fixed_cols) {
      col$frozen <- TRUE
    } else {
      col$frozen <- FALSE # Explicitly set to FALSE when not frozen
    }

    # Set editor and formatter based on column type
    if (!readonly_cols[i]) {
      if (!is.null(dropDown[[colNames[i]]])) {
        col$editor <- "list"
        col$editorParams <- list(values = dropDown[[colNames[i]]])
      } else if (is.numeric(df[[colNames[i]]])) {
        col$editor <- "number"
      } else if (is.logical(df[[colNames[i]]])) {
        col$editor <- "tickCross"
      } else {
        col$editor <- "input"
      }
    }

    # Set formatter for logical columns
    if (is.logical(df[[colNames[i]]])) {
      col$formatter <- "tickCross"
    }

    col
  })

  return(columns)
}

#' Create a Tabulator widget
#'
#' @param data A data frame or matrix
#' @param options A list of Tabulator.js options
#' @param elementId The ID of the element
#' @param readOnly A boolean for the whole table, or a vector of column ids or names (no mixing)
#' @param columnHeaders Custom column headers
#' @param hide A vector of column ids or names to hide
#' @param fixedCols A vector of column ids or names, columns will be fixed from first to the specified ones
#' @param stretched Stretching mode for columns (default: "all")
#' @param dropDown A list of dropdown options for specific columns
#' @param css Optional path to custom CSS file
#' @param add_selector_bar Boolean to add a selector bar (default: FALSE)
#' @param add_select_column Boolean to add a select column (default: FALSE)
#' @param return_select_column Boolean to include selection status in returned data (default: FALSE)
#' @param return_select_column_name Name for the returned selection column (default: "row_select")
#' @param columnOrder A character vector specifying the desired column order (default: NULL)
#' @param columns Manual columns setting. If set, auto creation is skipped.
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
  columnOrder = NULL,
  columns = NULL) {
  # Prepare data
  df <- as.data.frame(data, stringsAsFactors = FALSE)
  colNames <- colnames(df)

  if (is.null(columnHeaders)) {
    columnHeaders <- colNames
  }

  # Decide on columns
  if (is.null(columns)) {
    # Generate columns using helper function
    columns <- create_columns(
      df = df,
      colNames = colNames,
      columnHeaders = columnHeaders,
      readOnly = readOnly,
      hide = hide,
      fixedCols = fixedCols,
      columnOrder = columnOrder,
      dropDown = dropDown
    )
  }

  # Default options
  default_options <- list(
    # shiny_tabulator options
    add_selector_bar = add_selector_bar,
    add_select_column = add_select_column,
    return_select_column = return_select_column,
    return_select_column_name = return_select_column_name,
    # tabulator options
    columns = NULL,
    index = NULL,
    height = "100%", # 100%=use container size
    data = df,
    tooltips = TRUE,
    addRowPos = "top",
    history = TRUE,
    movableColumns = FALSE,
    resizableRows = FALSE,
    columnDefaults = list(
      resizable = FALSE
    ),
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

  # Add columns to options
  options$columns <- columns

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

#' Additional helper and proxy functions continue here...
