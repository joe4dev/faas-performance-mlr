# CRAN mirror
repos <- "https://cran.rstudio.com/"

# Workaround for a bug appearing around 2020-06: https://community.rstudio.com/t/error-is-not-empty/71089
# Error message:
# Error: `...` is not empty.

# We detected these problematic arguments:
# * `relax`

install.packages('devtools', repos = repos)

# Requires configured compile dependencies (see https://ryanhomer.github.io/posts/build-openmp-macos-catalina-complete)
devtools::install_github("r-lib/vctrs")
devtools::install_github("tidyverse/dplyr")
devtools::install_github("tidyverse/tidyr")

# Dependencies
# "dplyr", "tidyr"
install.packages(c("forcats", "scales", "ggplot2", "ggthemes", "gridExtra", "cowplot", "parsedate", "lubridate"), repos = repos)
