# load required packages ----
library(tidyverse)
library(feather)

# the directory of data ----
data_base <- file.path(getwd(), "DATA_RES")
config_dir <- file.path(getwd(), "config")

# load settings ----
configs <- read_csv(file.path(config_dir, 'config.csv'))

# function used to get all the data file names ----
file_name_get <- function(tag, task){
  # note the value will be assigned to global environment
  data_dir <- file.path(data_base, tag, "data")

  # choose a directory for the data directory
  if (!dir.exists(data_dir)){
    warning("Default tag: '", tag, "' directory '", data_dir, "' not exist!",
            immediate. = TRUE)
    resp <- winDialog(type = "yesno", "Will you still continue?")
    if (resp == "YES")
      data_dir <- choose.dir(default = data_base)
    else
      return()
  }

  # change data_base to the new directory
  data_base <<- data_dir

  # if task name is empty, set to match all
  if (nchar(task) == 0)
    task = '*'
  # get the task file names
  data_files <- list.files(paste0(task, ".csv"), path = data_dir)
}

process <- function(file){
  # load functions for processing data
  source('utils.R', local = TRUE)

  # load dataset
  rec <- read_csv(file.path(data_base, file))

  # get the task ID and settings
  task_id <- parse_number(file, "\\d+")
  task_config <- filter(configs, taskID == task_id)

  # get the analysis function and task_id_name
  analysis <- get(task_config$anafun)
  task_id_name <- task_config$taskIDName

  # do some pre analysis work
  rec <- prepare(rec, task_id_name)

  # process user by user
  indices <- rec %>%
    group_by(userId, createTime) %>%
    do(analysis(.))
}

# prepare data for analysis
prepare <- function(rec, task_id_name){
  switch(
    task_id_name,
    Flanker = {
      # Need comfirmation: congruent=1,4; incongruent=2,3
      condtypes <- factor(c("con", "incon", "incon", "con"),
                          levels = c("con", "incon"))
      rec <- rec %>%
        mutate(SCat = condtypes[STIM])
    })
  rec
}

# main script
tag <- readline("Please specify data tag: ")
task <- readline("Please specify task id (leave empty if all): ")
file_names <- file_name_get(tag, task)
if (is.null(file_names))
  stop("User canceled!")

for (file_name in file_names){
  indices <- process(file_name)
  write_feather(indices, paste0(tag, parse_number(file_name, "\\d+"), '.feather'))
}
