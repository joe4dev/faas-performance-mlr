# Configuration ---------------------------
download <- FALSE
filename.csv <- "../data/faas_mlr_raw.csv"
filename.xlsx <- "../data/faas_mlr_raw.xlsx"
# Data source: Google Sheet "FaaS Benchmarking – Multivocal Literature Review (MLR)" from tab "faas_mlr" exported as CSV
url.csv <- "https://docs.google.com/spreadsheets/d/1EK9yg9fMZIDybnbi7thsnBx1NdqDmkW86sMygH9r8q8/gviz/tq?tqx=out:csv&sheet=faas_mlr"
url.xlsx <- "https://docs.google.com/spreadsheets/d/1EK9yg9fMZIDybnbi7thsnBx1NdqDmkW86sMygH9r8q8/export?format=xlsx" # &gid=354468474

# Load data ---------------------------
if (download) {
  download.file(url.csv, filename.csv, method = "auto")
  # NOTE: Comments will only be included for manual authenticated download
  #       => Need to manually download the xlsx file!
  #download.file(url.xlsx, filename.xlsx, method = "auto")
}
mlr <- read.csv(filename.csv, header = TRUE)
