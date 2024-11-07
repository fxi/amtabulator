
# Clean old documentation
unlink("man", recursive = TRUE)

# Generate documentation
roxygen2::roxygenise(clean = TRUE)

# Check for problems
devtools::check(document = FALSE)

# update website 
pkgdown::build_site()
