setwd("~/Documents/Master Thesis Interviews/getIETFinfo")
library(tidyverse)
library(reshape2)
library(data.table)
library(showtext)
library(lfe)
library(broom)
library(corrplot)
library(did)
library(dplyr)
library(ggstream)
library(readxl)


getwd()

# Set the file path of the Excel file
file_path <- "rawData/IETFAttendence2.xlsx"

# Get the sheet names
sheet_names <- excel_sheets(file_path)

# Loop through each sheet and save it as a separate data frame
for (sheet in sheet_names) {
  # Read the sheet into a data frame
  sheet_data <- read_excel(file_path, sheet = sheet)
  
  # Save the data frame with the same name as the sheet
  assign(sheet, sheet_data)
}

# Define a list of data frames
my_dfs <- mget(as.character(47:71))

# Loop through each data frame in the list and print the column names
# Combine all column names into a single vector and print the unique names
cat("Unique column names across all data frames:\n")
print(unique(unlist(lapply(my_dfs, colnames))))
cat("\n")

keep_cols <- c('ISO Country', 'ISO Country Code', 'ISO Code', 'ISO 3166 Code')

# Loop through each data frame in the list and print selected columns to a CSV file in the "output" folder
for (i in seq_along(my_dfs)) {
  file_name <- paste0("output/", names(my_dfs)[i], ".csv") # Define the file name with the "output" folder
  
  # Subset the data frame to keep only selected columns (if they exist)
  if (all(keep_cols %in% names(my_dfs[[i]]))) {
    df_subset <- my_dfs[[i]][keep_cols]
  } else {
    df_subset <- my_dfs[[i]][names(my_dfs[[i]]) %in% keep_cols]
  }
  
  write.csv(df_subset, file_name, row.names = FALSE) # Print the selected columns to a CSV file in the "output" folder
}
