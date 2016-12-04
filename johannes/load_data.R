library(dplyr)
library(ggplot2)

if(!exists('map_cvp_tbl')){
map_cvp_tbl <-  readRDS("../datathon_data/map_cvp.RDS")

map_cvp_tbl_2 <- mutate(map_cvp_tbl, hadm_id = factor(hadm_id)) %>% 
  group_by(hadm_id) %>% 
  mutate(charttime_first = min(charttime), rel_charttime_hours = as.numeric(charttime - charttime_first)/(60*60),
         map = as.numeric(map), cvp = as.numeric(cvp), p_perfusion = map - cvp)
}
sum_map_tbl_2 <- summarise(map_cvp_tbl_2, n_measurements = n(), measurement_time_days = max(rel_charttime_hours)/24,
                           charttime_first = min(charttime_first))

if(!exists('creatinine_tbl')){
  creatinine_tbl <- readRDS("../datathon_data/creatinine.RDS")
  
  creatinine_tbl_2 <- mutate(creatinine_tbl, hadm_id = factor(hadm_id)) %>% 
    left_join(select(sum_map_tbl_2, hadm_id, charttime_first_map = charttime_first), by = 'hadm_id') %>% #add time for first map_cvp
    mutate(rel_charttime_hours = as.numeric(charttime - charttime_first_map)/(60*60))
}

# hadm Demographics
adms_demo_tbl <- readRDS("../datathon_data/adms_demo.RDS")

# Exclusion
# List patients with first creatinin > 1.2
creatinine_excl_adm <- creatinine_tbl_2 %>% group_by(hadm_id) %>% 
  summarise(first_val = first(valuenum), max_rel_charttime_hours = max(rel_charttime_hours)) %>% 
  filter(first_val > 1.2 | max_rel_charttime_hours < 24)

creatinine_tbl_incl <- filter(creatinine_tbl_2, !(hadm_id %in% creatinine_excl$hadm_id)) %>% 
  filter(!is.na(valuenum) | valuenum > 0) #Excludes missing values

# Exclusion by demographics

sum_creatinine_tbl_incl <- group_by(creatinine_tbl_incl, hadm_id) %>% 
  summarise(n_measurements = n(), measurement_time_days = max(rel_charttime_hours)/24)

summarise(map_cvp_tbl_2, min = min(charttime), max = max(charttime), measurement_time_days = max(rel_charttime_hours)/24)

plot_map <- ggplot(map_cvp_tbl_2 %>% head(1000), aes(rel_charttime_hours, p_perfusion, group = hadm_id, col = hadm_id)) +
  geom_line(alpha = 0.5, show.legend = FALSE) +
  geom_hline(yintercept = 55) +
  coord_cartesian(xlim = c(0, 24)) 
plot_map

#Function to test if patient has dysfunction
has_AKI <- function(df){
  if(max(df$rel_charttime_hours)>24){
    max_val_day2 <- max(filter(df, rel_charttime_hours > 24)$valuenum)
    first_val <- df$valuenum[1]
    has_AKI = max_val_day2/first_val >= 1.5 | max_val_day2 - first_val > 0.3
  } else has_AKI = FALSE
  data.frame(hadm_id = df$hadm_id[1], has_AKI)
}
  
aki_df<- split(creatinine_tbl_incl, creatinine_tbl_incl$hadm_id) %>% 
  lapply(has_AKI) %>% 
  do.call(rbind, .) %>% 
  tbl_df()

plot_creatinine <- ggplot(creatinine_tbl_incl %>% 
                            filter(hadm_id %in% aki_list), aes(rel_charttime_hours, valuenum, group = hadm_id, col = hadm_id)) +
  geom_line(alpha = 0.5, show.legend = FALSE) +
  coord_cartesian(xlim = c(0, 24*2)) 
plot_creatinine

plot_map <- ggplot(map_cvp_tbl_2 %>% filter(hadm_id %in% aki_list), aes(rel_charttime_hours, p_perfusion, group = hadm_id, col = hadm_id)) +
  geom_line(alpha = 0.5, show.legend = FALSE) +
  geom_hline(yintercept = 55) +
  coord_cartesian(xlim = c(0, 24)) 
plot_map
