# amtabulator



[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/fxi/amtabulator/graph/badge.svg?token=C17WBKIA84)](https://codecov.io/gh/fxi/amtabulator)
[![Build Status](https://github.com/fxi/amtabulator/actions/workflows/js_test_coverage.yaml/badge.svg?branch=main)](https://github.com/fxi/amtabulator/)
[![Build Status](https://github.com/fxi/amtabulator/actions/workflows/r_check.yaml/badge.svg?branch=main)](https://github.com/fxi/amtabulator/)
[![Build Status](https://github.com/fxi/amtabulator/actions/workflows/r_pkgdown.yaml/badge.svg?branch=main)](https://github.com/fxi/amtabulator/)
[![Build Status](https://github.com/fxi/amtabulator/actions/workflows/r_test_coverage.yaml/badge.svg?branch=main)](https://github.com/fxi/amtabulator/)


> ⚠️ Early version. Focused on [AccessMod](https://github.com/unige-geohealth/accessmod) requirements. 

A lightweight [Tabulator.js](http://tabulator.info/) integration for R/Shiny. This package provides an HTMLWidget wrapper around Tabulator.js with enhanced selection capabilities and modern JavaScript tooling.

## Features

- 📊 Basic Tabulator.js integration
- ✨ Modern JavaScript build system (Vite)
- 🧪 Comprehensive testing (Vitest)
- 📱 Responsive layouts
- 🔄 Efficient data updates with chunking

## Installation

```r
# Install from GitHub
pak::pkg_install("fxi/amtabulator")
```

## Usage

### Basic Example

```r
library(shiny)
library(amtabulator)

ui <- fluidPage(
  tabulator_output("table")
)

server <- function(input, output) {
  output$table <- render_tabulator({
    tabulator(mtcars)
  })
}

shinyApp(ui, server)
```


### Row Management

```r
# Get proxy object
proxy <- tabulator_proxy("table")

# Add rows
tabulator_add_rows(proxy, data = new_rows, position = "top")

# Remove specific rows
tabulator_remove_rows(proxy, row_ids = c(1, 3, 5))

# Remove first/last row
tabulator_remove_first_row(proxy)
tabulator_remove_last_row(proxy)
```

### Data Updates

```r
# Update all data
tabulator_update_data(proxy, new_data, chunk_size = 1000)

# Conditional updates
tabulator_update_where(
  proxy,
  col = "mpg",
  value = 20,
  whereCol = "cyl",
  whereValue = 6,
  operator = "=="
)
```

## Demo Apps

The package includes several demo Shiny apps showcasing different features:

```r
# Run demo apps
shiny::runApp("demo/minimal.R")        # Minimal example
shiny::runApp("demo/simple_app.R")     # Basic usage example
shiny::runApp("demo/salary_table.R")   # Complex table with sorting and filtering
shiny::runApp("demo/performance.R")    # Large dataset handling
shiny::runApp("demo/rows_manipulation.R") # Row operations and selection
```

## Project Structure

```
amtabulator/
├── R/                  # R package code
├── src/               # JavaScript source files + tests
├── demo/              # Example Shiny apps
├── inst/htmlwidgets/  # Compiled widget files
├── tests/             # R  tests
└── vite.config.js     # Build configuration
```

## Development

```bash
# Install dependencies
npm ci

# Development
npm run dev      # Watch mode
npm run test     # Run all tests
npm run build    # Production build

# Committing Changes
npm run commit   # Use commitizen for conventional commits

# R commands
make all         # Run all R package tasks
make document    # Update documentation
make test       # Run tests
make build      # Build package

# Release Process
# -> once ready, tested
npm run release  # Create a new release and update versions, both JS (package.json) and R (DESCRIPTION)
git push # Main branch. If pushed from the main branch, a version will be tested and built by a github workflow
```

### Contributing Guidelines

1. Fork the repository and create your feature branch
2. Install dependencies with `npm ci`
3. Make your changes
4. Run tests with `npm test` and ensure they pass
5. Commit your changes using `npm run commit`
   - This uses commitizen to ensure conventional commit messages
   - Pre-commit hooks will run tests and build
6. Push to your branch and create a Pull Request

### Version Management

The package uses [standard-version](https://github.com/conventional-changelog/standard-version) for version management, following semantic versioning:

- Commit messages following conventional commits automatically determine version bumps
- The release process synchronizes versions between package.json and DESCRIPTION
- Pre-commit hooks ensure code quality before commits

## License

MIT License - see [LICENSE](LICENSE) file

## See Also

This package focuses on AccessMod requirements with emphasis on selection functionality. For a more complete Tabulator.js integration, see [rtabulator](https://github.com/eoda-dev/rtabulator).


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.
