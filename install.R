install.packages("pak", repos = "https://cloud.r-project.org")

pak::local_install_dev_deps(
  root = ".",
  lib = .libPaths()[1],
  upgrade = TRUE,
  ask = interactive(),
  dependencies = TRUE
)
