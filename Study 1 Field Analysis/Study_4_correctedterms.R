# Clear workspace and set options
rm(list = ls()) 
options(download.file.method="libcurl")

# Load necessary libraries
library(readxl)
library(dplyr)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))  # Set working directory to current directory

# Read in the data
analyze_sheet <- function(sheet_name) {
  data <- read_excel("Study_4_correctedterms.xlsx", sheet = sheet_name)
  
  ###############################  NUMBER OF CLICKS ANALYSIS ###############################  

  # Calculate average and standard deviation of "How many clicks?"
  avg_clicks <- mean(data$`How many clicks?`, na.rm = TRUE)
  sd_clicks <- sd(data$`How many clicks?`, na.rm = TRUE)
  
  ###############################  OVERALL SUMMARY STATISTICS ###############################  
  # Function to calculate the frequency and percentage of each type of depiction within each sector
  count_and_percentage <- function(column_name) {
    count_ones <- sum(data[[column_name]] == 1, na.rm = TRUE)
    total_entries <- sum(!is.na(data[[column_name]]))
    percentage_ones <- (count_ones / total_entries) * 100
    return(list(count = count_ones, percentage = percentage_ones))
  }
  
  # Calculate frequency and percentages for each specified depiction
  columns_to_analyze <- c("Baseline", "Image_Annotated", "Adjacent",
                          "Annotation_Only", "Faded", "Curse?", "Other",
                          "Verbal_Cue")
  
  results <- lapply(columns_to_analyze, count_and_percentage)
  names(results) <- columns_to_analyze
  
  # Compile results into a list
  result_list <- list(
    sheet = sheet_name,
    average_clicks = avg_clicks,
    sd_clicks = sd_clicks,
    counts_and_percentages = results
  )
  
  return(result_list)
}

# Analyze each sheet and store the results, including the "Totals" sheet
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical", "Totals")
results <- lapply(sheet_names, analyze_sheet)

# Print results
print(results)

###############################  TABLE OF SUMMARY STATISTICS ###############################  
# Prepare data for table display
table_data <- do.call(rbind, lapply(results, function(result) {
  data.frame(
    Sheet = result$sheet,
    Average_Clicks = result$average_clicks,
    SD_Clicks = result$sd_clicks,
    Baseline_Count = result$counts_and_percentages$Baseline$count,
    Baseline_Percentage = result$counts_and_percentages$Baseline$percentage,
    Image_Annotated_Count = result$counts_and_percentages$`Image_Annotated`$count,
    Image_Annotated_Percentage = result$counts_and_percentages$`Image_Annotated`$percentage,
    Adjacent_Count = result$counts_and_percentages$Adjacent$count,
    Adjacent_Percentage = result$counts_and_percentages$Adjacent$percentage,
    Annotation_Only_Count = result$counts_and_percentages$Annotation_Only$count,
    Annotation_Only_Percentage = result$counts_and_percentages$Annotation_Only$percentage,
    Faded_Count = result$counts_and_percentages$Faded$count,
    Faded_Percentage = result$counts_and_percentages$Faded$percentage,
    Other_Count = result$counts_and_percentages$`Other`$count,
    Other_Percentage = result$counts_and_percentages$`Other`$percentage,
    Curse_Count = result$counts_and_percentages$`Curse?`$count,
    Curse_Percentage = result$counts_and_percentages$`Curse?`$percentage,
    Verbal_Cue_Count = result$counts_and_percentages$`Verbal_Cue`$count,
    Verbal_Cue_Percentage = result$counts_and_percentages$`Verbal_Cue`$percentage
  )
}))

# Calculate standard deviations of percentages across sheets for each category, excluding "Totals"
percentage_columns <- c("Baseline_Percentage", "Image_Annotated_Percentage", "Adjacent_Percentage",
                        "Annotation_Only_Percentage", "Faded_Percentage",
                        "Other_Percentage", "Curse_Percentage", "Verbal_Cue_Percentage")

# Exclude the "Totals" sheet from SD calculation
table_data_no_totals <- table_data[table_data$Sheet != "Totals", ]

sd_percentages <- sapply(percentage_columns, function(col) {
  sd(table_data_no_totals[[col]], na.rm = TRUE)
})

# Add SDs to the table data
sd_table <- data.frame(Category = gsub("_Percentage", "", percentage_columns), SD_Percentage = sd_percentages)
print(sd_table)

###############################  CURSED DEPICTIONS ANALYSIS ###############################  

# Function to calculate percentage of cursed depictions in each sector
calculate_curse_1_percentage <- function(df) {
  total_entries <- sum(!is.na(df$`Curse?`))  # Total non-NA entries
  curse_1_count <- sum(df$`Curse?` == 1, na.rm = TRUE)
  
  curse_1_percentage <- (curse_1_count / total_entries) * 100
  return(curse_1_percentage)
}

# Sheet names (sectors) to analyze (excluding "ReadMe" and "Totals")
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical")

# Calculate percentages for each sheet (sector)
curse_1_percentages <- sapply(sheet_names, function(sheet) {
  df <- read_excel("Study_4_correctedterms.xlsx", sheet = sheet)
  calculate_curse_1_percentage(df)
})

# Convert to data frame for easy viewing
curse_1_percentages_df <- data.frame(Sheet = sheet_names, Curse_Percentage = curse_1_percentages)

# Calculate the standard deviation of the percentage of cursed depictions
curse_1_sd <- sd(curse_1_percentages_df$Curse_Percentage, na.rm = TRUE)

# Print the percentages and the standard deviation
print(curse_1_percentages_df)
print(paste("Standard Deviation of Curse = 1 Percentages:", round(curse_1_sd, 2)))

###############################  DEBIASED DEPICTIONS ANALYSIS ###############################  

# Function to calculate percentage of debiased depictions in each sector
calculate_debiased_percentage <- function(df) {
  # Sum the counts of the relevant columns where values are 1 (indicating a debiased depiction)
  debiased_count <- sum(df$Adjacent == 1, na.rm = TRUE) + 
    sum(df$Faded == 1, na.rm = TRUE) + 
    sum(df$Annotation_Only == 1, na.rm = TRUE) + 
    sum(df$`Verbal_Cue` == 1, na.rm = TRUE)
  
  # The total number of rows (excluding rows where all relevant columns are NA)
  total_rows <- nrow(df) - sum(is.na(df$Adjacent) & is.na(df$Faded) & is.na(df$Annotation_Only) & 
                                 is.na(df$`Verbal_Cue`))
  
  # Calculate the percentage
  debiased_percentage <- (debiased_count / total_rows) * 100
  return(debiased_percentage)
}

# Sheet names to analyze (excluding "ReadMe" and "Totals")
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical")

# Calculate the percentage of debiased depictions for each sector
debiased_percentages <- sapply(sheet_names, function(sheet) {
  df <- read_excel("Study_4_correctedterms.xlsx", sheet = sheet)
  calculate_debiased_percentage(df)
})

# Convert to data frame for easy viewing
debiased_percentages_df <- data.frame(Sheet = sheet_names, Debiased_Percentage = debiased_percentages)

# Calculate the standard deviation of the Debiased percentages (excluding "Totals")
debiased_sd <- sd(debiased_percentages_df$Debiased_Percentage, na.rm = TRUE)

# Print the percentages and the standard deviation
print(debiased_percentages_df)
print(paste("Standard Deviation of Debiased Percentages:", round(debiased_sd, 2)))

############################### VERBAL CUES ANALYSIS ###############################  

# Function to calculate counts and percentages for the different types of verbal cues
calculate_cue_category_counts_and_percentages <- function() {
  # Read the "Totals" sheet
  data <- read_excel("Study_4_correctedterms.xlsx", sheet = "Totals")
  
  # Calculate the counts of "1", "2", and "3" in the "Cue_Category" column
  count_1 <- sum(data$Cue_Category == 1, na.rm = TRUE)
  count_2 <- sum(data$Cue_Category == 2, na.rm = TRUE)
  count_3 <- sum(data$Cue_Category == 3, na.rm = TRUE)
  
  # Calculate the denominator: the number of "1"s in the "Verbal_Cue" column
  denominator <- sum(data$`Verbal_Cue` == 1, na.rm = TRUE)
  
  # Calculate percentages based on the denominator
  percentage_1 <- (count_1 / denominator) * 100
  percentage_2 <- (count_2 / denominator) * 100
  percentage_3 <- (count_3 / denominator) * 100
  
  # Return the counts and percentages as a list
  return(list(
    count_1 = count_1,
    percentage_1 = percentage_1,
    count_2 = count_2,
    percentage_2 = percentage_2,
    count_3 = count_3,
    percentage_3 = percentage_3
  ))
}

# Calculate and print the counts and percentages for "Cue_Category" in the "Totals" sheet
cue_category_counts_and_percentages <- calculate_cue_category_counts_and_percentages()
print(cue_category_counts_and_percentages)

###############################  IMAGE VS NO IMAGE ANALYSIS ###############################  

# Function to calculate percentage of the Image group
calculate_image_percentage <- function(df) {
  # Sum the counts of the relevant columns where values are 1
  image_count <- sum(df$Baseline == 1, na.rm = TRUE) + 
    sum(df$`Image_Annotated` == 1, na.rm = TRUE) + 
    sum(df$Adjacent == 1, na.rm = TRUE) + 
    sum(df$Annotation_Only == 1, na.rm = TRUE) + 
    sum(df$Faded == 1, na.rm = TRUE) + 
    sum(df$`Verbal_Cue` == 1, na.rm = TRUE)
  
  # The total number of rows (excluding rows where all relevant columns are NA)
  total_rows <- nrow(df) - sum(is.na(df$Baseline) & is.na(df$`Image_Annotated`) & 
                                 is.na(df$Adjacent) & is.na(df$Annotation_Only) & is.na(df$Faded) & 
                                 is.na(df$`Verbal_Cue`))
  
  # Calculate the percentage
  image_percentage <- (image_count / total_rows) * 100
  return(image_percentage)
}

# Function to calculate percentage of 1s in the "Other" column
calculate_no_image_percentage <- function(df) {
  # Sum the counts of 1s in the relevant columns
  no_image_count <- sum(df$`Other` == 1, na.rm = TRUE)
  
  # The total number of non-NA rows
  total_entries <- nrow(df) - sum(is.na(df$`Other`))
  
  # Calculate the percentage
  no_image_percentage <- (no_image_count / total_entries) * 100
  return(no_image_percentage)
}


# Sheet names to analyze (excluding "ReadMe" and "Totals")
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical")

# Function to calculate percentage of the Image group
calculate_image_percentage <- function(df) {
  # Sum the counts of the relevant columns where values are 1
  image_count <- sum(df$Baseline == 1, na.rm = TRUE) + 
    sum(df$`Image_Annotated` == 1, na.rm = TRUE) + 
    sum(df$Adjacent == 1, na.rm = TRUE) + 
    sum(df$Annotation_Only == 1, na.rm = TRUE) + 
    sum(df$Faded == 1, na.rm = TRUE) + 
    sum(df$`Verbal_Cue` == 1, na.rm = TRUE)
  
  # The total number of rows
  total_rows <- nrow(df)
  
  # Calculate the percentage
  image_percentage <- (image_count / total_rows) * 100
  return(image_percentage)
}

# Function to calculate percentage of the No Image group
calculate_no_image_percentage <- function(df) {
  # Sum the counts of the relevant columns where values are 1
  no_image_count <- sum(df$`Other` == 1, na.rm = TRUE) + 
  
  # The total number of rows
  total_rows <- nrow(df)
  
  # Calculate the percentage
  no_image_percentage <- (no_image_count / total_rows) * 100
  return(no_image_percentage)
}

# Sheet names to analyze (excluding "ReadMe" and "Totals")
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical")


# Function to calculate percentage of Image and No Image categories
calculate_image_no_image_percentages <- function(df) {
  # Create a boolean mask for Image category
  image_mask <- (df$Baseline == 1 | df$`Image_Annotated` == 1 | df$Adjacent == 1 | 
                   df$Annotation_Only == 1 | df$Faded == 1 | df$`Verbal_Cue` == 1)
  
  # Create a boolean mask for No Image category
  no_image_mask <- (!image_mask & (df$`Other` == 1))
  
  # Calculate total number of rows
  total_rows <- nrow(df)
  
  # Calculate the percentage for Image and No Image
  image_percentage <- sum(image_mask, na.rm = TRUE) / total_rows * 100
  no_image_percentage <- sum(no_image_mask, na.rm = TRUE) / total_rows * 100
  
  return(list(Image_Percentage = image_percentage, No_Image_Percentage = no_image_percentage))
}

# Sheet names to analyze (excluding "ReadMe" and "Totals")
sheet_names <- c("AVs", "Security Cams", "Agriculture", "Retail", "Aerospace and Defense", "Medical")

# Calculate percentages for each sheet
percentages <- lapply(sheet_names, function(sheet) {
  df <- read_excel("Study_4_correctedterms.xlsx", sheet = sheet)
  calculate_image_no_image_percentages(df)
})

# Convert to data frames for easy viewing
image_percentages <- sapply(percentages, `[[`, "Image_Percentage")
no_image_percentages <- sapply(percentages, `[[`, "No_Image_Percentage")

image_percentages_df <- data.frame(Sheet = sheet_names, Image_Percentage = image_percentages)
no_image_percentages_df <- data.frame(Sheet = sheet_names, No_Image_Percentage = no_image_percentages)

# Calculate the standard deviation of the Image and No Image percentages
image_sd <- sd(image_percentages_df$Image_Percentage, na.rm = TRUE)
no_image_sd <- sd(no_image_percentages_df$No_Image_Percentage, na.rm = TRUE)

# Check if Image + No Image adds up to 100% for each sheet
check_totals <- image_percentages_df$Image_Percentage + no_image_percentages_df$No_Image_Percentage

# Print the percentages, the standard deviations, and the totals check
print(image_percentages_df)
print(paste("Standard Deviation of Image Percentages:", round(image_sd, 2)))

print(no_image_percentages_df)
print(paste("Standard Deviation of No Image Percentages:", round(no_image_sd, 2)))

# Print check if they sum to 100%
print(data.frame(Sheet = sheet_names, Total_Percentage = check_totals))


###############################  OVERALL TABLE DATA ###############################  
# Display the table
print(table_data)

