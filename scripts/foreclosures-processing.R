library(dplyr)
library(datapkg)

##################################################################
#
# Processing Script for Foreclosures
# Created by Jenna Daly
# On 09/18/2017
#
##################################################################

#Setup environment
sub_folders <- list.files()
raw_location <- grep("raw", sub_folders, value=T)
path_to_raw_data <- (paste0(getwd(), "/", raw_location))
foreclosure_data <- dir(path_to_raw_data, recursive=T, pattern = "xlsx") 

#read in entire xls file (all sheets)
read_excel_allsheets <- function(filename) {
  sheets <- readxl::excel_sheets(filename)
  x <- lapply(sheets, function(X) readxl::read_excel(filename, sheet = X))
  names(x) <- sheets
  x
}

for (i in 1:length(foreclosure_data)) {
  mysheets <- read_excel_allsheets(paste0(path_to_raw_data, "/", foreclosure_data[i]))
  for (j in 1:length(mysheets)) {
    current_sheet_name <- colnames(mysheets[[j]])[1]
    current_sheet_file <- mysheets[[j]] 
    get_year <- unlist(gsub("[^0-9]", "", unlist(foreclosure_data[i])), "")
    assign(paste0(current_sheet_name, "_", get_year), current_sheet_file)
  }
}

rm(current_sheet_file)

#Concatenate all DFs
dfs <- ls()[sapply(mget(ls(), .GlobalEnv), is.data.frame)]

#Combine all years DFs into one data frame
all_years <- data.frame(stringsAsFactors = F)
#Process each year/foreclosure type file
for (i in 1:length(dfs)) {
  #grab first file
  current_file <- get(dfs[i])
  #select town and total columns
  last_col <- ncol(current_file)
  current_file <- current_file[,c(1,last_col)]
  #assign colnames
  colnames(current_file) <- c("Town", "Value")
  current_file <- current_file[-1,]
  #Assign foreclosure type and year based on DF name
  #takes the 2nd and 3rd word from df name i.e "Lis Penden" or "Foreclosure Deed"
  type <- paste(sapply(strsplit(dfs[i], " "), "[", 2), sapply(strsplit(dfs[i], " "), "[", 3), sep = " ")
  current_file$Foreclosure <- type
  year <- sapply(strsplit(dfs[i], "_"), "[", 2)  
  current_file$Year <- year
  #bind all year/foreclosure type together
  all_years <- rbind(all_years, current_file)  
}

#Reassign Total to Connecticut in town column
all_years$Town[grepl("Total", all_years$Town)] <- "Connecticut"

#Merge in FIPS
town_fips_dp_URL <- 'https://raw.githubusercontent.com/CT-Data-Collaborative/ct-town-list/master/datapackage.json'
town_fips_dp <- datapkg_read(path = town_fips_dp_URL)
fips <- (town_fips_dp$data[[1]])

all_years_fips <- merge(all_years, fips, all=T)

#Reassign Foreclosure column
all_years_fips$Foreclosure[grepl("Lis Penden", all_years_fips$Foreclosure)] <- "Lis Penden Filings"
all_years_fips$Foreclosure[grepl("Foreclosure Deed", all_years_fips$Foreclosure)] <- "Total Foreclosures"

#Assign Measure Type and Variable columns
all_years_fips$`Measure Type` <- "Number"
all_years_fips$Variable <- "Foreclosures"

#Order and sort columns
all_years_fips <- all_years_fips %>% 
  select(Town, FIPS, Year, Foreclosure, `Measure Type`, Variable, Value) %>% 
  arrange(Town, Year, Foreclosure)

# Write data to file.
write.table(
  all_years_fips,
  file.path(getwd(), "data", "foreclosures_2016.csv"),
  sep = ",",
  row.names = F
)

