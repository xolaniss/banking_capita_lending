# Packages ----------------------------------------------------------------
library(tidyverse)
library(readr)
library(readxl)
library(here)
library(lubridate)
library(xts)
library(tseries)
library(broom)
library(glue)
library(vars)
library(PNWColors)
library(patchwork)
library(psych)
library(kableExtra)
library(strucchange)
library(timetk)
library(purrr)
library(pins)
library(fDMA)
library(uniqtag)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))
source(here("Functions", "Sheets_import.R"))
source(here("Functions", "excel_import_sheet.R"))
source(here("Functions", "cleanup.R"))
source(here("Functions", "filter_and_stings.R"))

# Import ------------------------------------------------------------------
path = here("Data", "BA900_Line_items_103_to_277.xlsx")
sheet_list = list(
  "Total Banks" = "Sheet1", 
  "Absa Bank"  = "Sheet2",
  "FNB" = "Sheet3",
  "Nedbank" = "Sheet5",
  "Standard Bank" = "Sheet6",
  "Capitec" = "Sheet12")
col_types = c("text", rep(x = "numeric", 148))

ba900_assets <- 
  excel_import_sheet(
  path = path,
  sheet_list = sheet_list,
  skip = 5,
  col_types = col_types 
    ) 

# Cleaning ----------------------------------------------------------

total_tbl <- cleanup(ba900_assets$`Total Banks`, date_size = 176) 
absa_tbl <- cleanup(ba900_assets$`Absa Bank`)
fnb_tbl <- cleanup(ba900_assets$FNB)
nedbank_tbl <- cleanup(ba900_assets$Nedbank)
standard_tbl <- cleanup(ba900_assets$`Standard Bank`)
capitec_tbl <- cleanup(ba900_assets$Capitec)

# Filtering loans and advances --------------------------------------------
filter_vec <- 
  c(  "DEPOSITS, LOANS AND ADVANCES (total of items 111, 117, 118, 126, 135, 139, 150, 166, 171 and 180, less item 194)"                                            
     , "SA banksb (total of items 112 and 116)"                                                                                                                      
     , "NCDs/PNsc issued by banks, with an unexpired maturity of: (total of items 113 to 115)"                                                                       
     , "Up to 1 month"                                                                                                                                               
     , "More than 1 month to 6 months"                                                                                                                               
     , "More than 6 months"                                                                                                                                          
     , "Other deposits with and loans and advances to SA banksb"                                                                                                     
     , "Deposits with and loans and advances to foreign banks, denominated in rand"                                                                                  
     , "Loans granted under resale agreements to:  (total of items 119 to 125)"                                                                                      
     , "SA Reserve Bank"                                                                                                                                             
     , "Banksd"                                                                                                                                                      
     , "Insurers"                                                                                                                                                    
     , "Pension funds"                                                                                                                                               
     , "Other financial corporate sectorb"                                                                                                                           
     , "Non-financial corporate sector"                                                                                                                              
     , "Other"                                                                                                                                                       
     , "Foreign currency loans and advances (total of items 127 to 130, 133 and 134)"                                                                                
     , "Foreign currency notes and coin"                                                                                                                             
     , "Deposits with and advances to SA Reserve Bank"                                                                                                               
     , "Deposits with and advances to SA banksd"                                                                                                                     
     , "Other advances to: (total of items 131 and 132)"                                                                                                             
     , "SA Financial corporate sectorc"                                                                                                                              
     , "SA Non-financial corporate sector and other"                                                                                                                 
     , "Deposits with and advances to foreign banks"                                                                                                                 
     , "Other advances to foreign sector"                                                                                                                            
     , "Redeemable preference shares issued by: (total items 136 to 138)"                                                                                            
     , "Banksd-1"                                                                                                                                                    
     , "Financial corporate sectorc"                                                                                                                                 
     , "Non-financial corporate sector and other"                                                                                                                    
     , "Instalment debtors, suspensive sales and leases (total of items 140 and 145)"                                                                                
     , "Instalment sales (total of items 141 to 144)"                                                                                                                
     , "Financial corporate sector"                                                                                                                                  
     , "Non-financial corporate sector-1"                                                                                                                            
     , "Household sector"                                                                                                                                            
     , "Otherb"                                                                                                                                                      
     , "Leasing transactions (total of items 146 to 149)"                                                                                                            
     , "Financial corporate sector-1"                                                                                                                                
     , "Non-financial corporate sector-2"                                                                                                                            
     , "Household sector-1"                                                                                                                                          
     , "Otherb-1"                                                                                                                                                    
     , "Mortgage advances (total of items 151, 155 and 159)"                                                                                                         
     , "Farm mortgages: (total of items 152 to 154)"                                                                                                                 
     , "Corporate sector"                                                                                                                                            
     , "Household sector-2"                                                                                                                                          
     , "Otherb-2"                                                                                                                                                    
     , "Residential mortgages: (total of items 156 to 158)"                                                                                                          
     , "Corporate sector-1"                                                                                                                                          
     , "Household sector-3"                                                                                                                                          
     , "Otherb-3"                                                                                                                                                    
     , "Commercial and other mortgage advances: (total of items 160 to 165)"                                                                                         
     , "Public financial corporate sector"                                                                                                                           
     , "Public non-financial corporate sector"                                                                                                                       
     , "Private financial corporate sector"                                                                                                                          
     , "Private non-financial corporate sector"                                                                                                                      
     , "Household sector-4"                                                                                                                                          
     , "Otherb-4"                                                                                                                                                    
     , "Credit-card debtors (total of items 167 to 170)"                                                                                                             
     , "Financial corporate sector-2"                                                                                                                                
     , "Non-financial corporate sector-3"                                                                                                                            
     , "Household sector-5"                                                                                                                                          
     , "Otherb-5"                                                                                                                                                    
     , "Overdrafts, loans and advances: public sector (total of items 172 to 179)"                                                                                   
     , "Central government of the Republic (excluding social security funds)"                                                                                        
     , "Social security funds"                                                                                                                                       
     , "Provincial governments"                                                                                                                                      
     , "Local government"                                                                                                                                            
     , "Land Bank"                                                                                                                                                   
     , "Other public financial corporate sector (such as IDC)c"                                                                                                      
     , "Public non-financial corporate sector (such as Transnet, Eskom and Telkom)"                                                                                  
     , "Foreign public sector"                                                                                                                                       
     , "Overdrafts, loans and advances: private sector (total of items 181, 187 and 188)"                                                                            
     , "Overdrafts, including overdrafts under cash-management schemes: (total of items 182 to 186)"                                                                 
     , "Financial corporate sector-3"                                                                                                                                
     , "Non-financial corporate sector-4"                                                                                                                            
     , "Unincorporated business enterprises of households"                                                                                                           
     , "Households"                                                                                                                                                  
     , "Non-profit organisations serving households"                                                                                                                 
     , "Factoring debtors"                                                                                                                                           
     , "Other loans and advances: (total of items 189 to 193)"                                                                                                       
     , "Financial corporate sector-4"                                                                                                                                
     , "Non-financial corporate sector-5"                                                                                                                            
     , "Unincorporated business enterprises of households-1"                                                                                                         
     , "Households-1"                                                                                                                                                
     , "Non-profit organisations serving households-1"                                                                                                               
     , "Less: credit impairments in respect of loans and advances" 
)


filter_vec <- filter_vec
total_filtered_tbl <- filter_and_strings(total_tbl, filter_vec)
total_filtered_tbl 
absa_filtered_tbl <- filter_and_strings(absa_tbl, filter_vec)
absa_filtered_tbl
fnb_filtered_tbl <- filter_and_strings(fnb_tbl, filter_vec)
fnb_filtered_tbl
nedbank_filtered_tbl <- filter_and_strings(nedbank_tbl, filter_vec)
nedbank_filtered_tbl
standard_filtered_tbl <- filter_and_strings(standard_tbl, filter_vec)
standard_filtered_tbl
capitec_filtered_tbl <- filter_and_strings(capitec_tbl, filter_vec)
capitec_filtered_tbl


# Graphing ----------------------------------------------------------------



# Export ------------------------------------------------------------------
artifacts_ba900 <- 
  list(
    keys = list(
      filter_vec
    ),
    data = list(
      total_filtered_tbl = total_filtered_tbl,
      absa_filtered_tbl = absa_filtered_tbl, 
      fnb_filtered_tbl = fnb_filtered_tbl,
      nedbank_filtered_tbl = nedbank_filtered_tbl,
      standard_filtered_tbl = standard_filtered_tbl,
      capitec_filtered_tbl = capitec_filtered_tbl
    )
    
  )

write_rds(artifacts_ba900, file = here("Outputs", "artifacts_ba900.rds"))

