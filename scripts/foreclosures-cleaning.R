library(dplyr)
library(datapkg)

##################################################################
#
# Processing Script for Cleaning Up Foreclosure csv files generated from tabula
# Created by Jenna Daly
# On 09/18/2017
#
##################################################################


#Setup environment
sub_folders <- list.files()
raw_location <- grep("raw", sub_folders, value=T)
path_to_raw_data <- (paste0(getwd(), "/", raw_location))

all_csvs <- dir(path_to_raw_data, recursive=T, pattern = "csv") 

for (i in 1:length(all_csvs)) {
  foreclosures <- read.csv(paste0(path_to_raw_data, "/", all_csvs[1]), stringsAsFactors = FALSE, header=T, check.names = F, na.strings=c("","NA")) 
  january <- foreclosures[,1:3]
  colnames(january) <- c("Lis Penden Filings", "January", "c")
  january$c <- as.numeric(january$c)
  january$January <- as.numeric(january$January)
  january <- cbind.data.frame(`Lis Penden Filings`=january$`Lis Penden Filings`, January = rowSums(january[, -1], na.rm = TRUE))
  
  february <- foreclosures[, c(1, 4:5)]
  
  
  
  
  
  
  
  
  
}
  

