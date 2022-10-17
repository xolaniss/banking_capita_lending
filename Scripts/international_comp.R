# Description
# Fengeta et al graph replication by Xolani Sibande 28 Septmber 2022

# Preliminaries -----------------------------------------------------------
# core
library(tidyverse)
library(readr)
library(readxl)
library(here)
library(lubridate)
library(xts)
library(broom)
library(glue)
library(scales)
library(kableExtra)
library(pins)
library(timetk)
library(uniqtag)

# graphs
library(PNWColors)
library(patchwork)

# eda
library(psych)
library(DataExplorer)
library(skimr)

# econometrics
library(tseries)
library(strucchange)
library(fDMA)
library(vars)
library(urca)
library(mFilter)
library(car)

# Functions ---------------------------------------------------------------
source(here("Functions", "fx_plot.R"))

# Import -------------------------------------------------------------
int_comp <- read_excel(here("Data", "International_com.xlsx"))

# Cleaning -----------------------------------------------------------------
int_comp_tbl <- int_comp %>% 
  mutate( Date = parse_date_time(Year, order = "Y")) %>% 
  relocate(Date, .before = Country) %>% 
  dplyr::select(-Year)

# EDA ---------------------------------------------------------------
int_comp_tbl %>% skim()

# General Graphing ---------------------------------------------------------------
country_graph <- function(data =int_comp_tbl,  country_name = "Brazil") {
  data %>% 
    filter(Country == country_name) %>% 
    dplyr::select(-Country) %>%  
    fx_plot()
}

country_graph(country_name = "Kenya")
country_graph(country_name = "China")
country_graph(country_name = "South Africa")
country_graph(country_name = "Peru")
list_names <- as_vector(sort(unique(int_comp_tbl$Country)))


# Fangeta Graph 2010-2020 -------------------------------------------------
# list_names <- 
#   c("Brazil","China" ,"Hungary" ,"India" ,"Mexico" ,"Peru"   ,"South Africa", "Spain" ,"Turkey")
int_comp_average_tbl <- 
  int_comp_tbl %>% 
  group_split(Country) %>% 
  set_names(list_names) %>% 
  map(~ filter(.x, Date > "2010-01-01" & Date < "2021-01-01" )) %>% 
  map(~summarise_at(.x, vars(3:ncol(.x)), .funs = list(mean = ~mean(., na.rm = TRUE)))) %>% 
  bind_rows(.id = "Country")

average_tbl <- int_comp_average_tbl %>% 
 mutate(across(.cols = 2:ncol(.), .fns = ~mean(., na.rm = TRUE))) %>% 
  filter(Country == "Brazil") %>% 
  pivot_longer(-Country)  %>% 
  mutate(Country = "") %>% 
  mutate(name = str_remove(name, "_mean"))

highlighted_tbl <- 
  int_comp_average_tbl %>% 
  filter(Country == "South Africa") %>% 
  pivot_longer(-Country) %>% 
  mutate(Country = "") %>% 
  mutate(name = str_remove(name, "_mean"))
  

int_comp_average_graph_tbl <- 
  int_comp_average_tbl %>% 
  pivot_longer(-Country) %>% 
  mutate(Country = "") %>% 
  mutate(name = str_remove(name, "_mean"))
 
int_comp_average_gg <- 
  int_comp_average_graph_tbl %>% 
  ggplot(aes(x = Country, y = value)) +
  geom_point(alpha = 0.3) +
  geom_point(data = highlighted_tbl, 
             aes(Country, y = value), col ="#e2e260",
             size = 3) +
  facet_wrap(. ~ name, scales = "free_y", nrow = 1, labeller = labeller(name = label_wrap_gen(20))) +
  geom_hline(aes(yintercept = value), col = "#dec000", data = average_tbl) +
  labs( x = "", y = "") + 
  theme_bw() +
  theme(
    legend.position = "top",
    legend.title = element_blank(),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(colour = "black"),
    panel.border = element_blank(),
    text = element_text(size = 8),
    strip.text.x = element_text(size =6),
    strip.background = element_rect(colour = "white", fill = "white"),
    axis.text.x = element_text(angle = 90),
    axis.title = element_text(size = 7),
    plot.tag = element_text(size = 8),
    axis.ticks.x = element_blank()
  )


# Export ---------------------------------------------------------------
artifacts_int_comp <- list (
  data = list(
    int_comp_tbl = int_comp_tbl,
    int_comp_average_tbl = int_comp_average_tbl
  ),
  graph = list(
    int_comp_average_gg = int_comp_average_gg
  )
)

write_rds(artifacts_int_comp, file = here("Outputs", "artifacts_int_comp.rds"))


