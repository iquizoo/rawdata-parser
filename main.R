# load required packages ----
library(tidyverse)

# the directory of data ----
data_dir <- file.path(getwd(), "DATA_RES")
config_dir <- file.path(getwd(), "config")

# function used to get all the data file names ----
file_name_get <- function(tag){
  # note the value will be assigned to global environment
  data_dir <<- file.path(data_dir, tag, "data")
  if (!dir.exists(data_dir)){
    warning("Specified tag data directory ", data_dir, " does not exist!",
            immediate. = TRUE)
    resp <- tolower(readline("Will you continue? [y]/n:"))
    if (nchar(resp) == 0)
      resp <- "y"
    if (resp == "y")
      data_dir <<- choose.dir(default = data_dir)
    else
      return()
  }
  data_files <- list.files("*.csv", path = data_dir)
}

process <- function(file){
  source("utils.R", local = TRUE)
  # load dataset
  records <- read_csv(file.path(data_dir, file))
  # load names settings
  tasknames <- read_csv(file.path(config_dir))
  # get the task ID
  task_id <- parse_number(file, "\\d+")
  # get the analysis function name
  analysis <- get(anafun)
  # process
  indices <- records %>%
    group_by(userId, createTime) %>%
    do(analysis(.))
}

# main script
tag <- readline("Please specify data tag: ")
file_names <- file_name_get(tag)
if (is.null(file_names))
  stop("User canceled!")
lst <- lapply(file_names, process)
