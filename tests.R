#devtools::test()
# run-tests.R
if (!require("devtools")) install.packages("devtools")
if (!require("pkgbuild")) install.packages("pkgbuild")

# Let R handle platform detection and configuration
withr::with_makevars(list(PKG_LIBS = ""), {
})
