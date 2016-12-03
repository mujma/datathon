library(RPostgreSQL)
library(dplyr)

mimic <- src_postgres(dbname = "mimic", host = "localhost", port = 15432, 
                      user = "mimic", password = "mimic")

query_map <- "SELECT map.hadm_id, map.subject_id, map.value as map, map.charttime as charttime, cvp.value as cvp
FROM mimiciii.chartevents map
LEFT OUTER JOIN mimiciii.chartevents cvp
ON cvp.charttime = map.charttime
WHERE map.itemid = 52 AND cvp.itemid = 113 AND map.value != 'None' 
  AND cvp.value != 'None' AND cvp.hadm_id = map.hadm_id
ORDER BY map.hadm_id, charttime"

map_cvp <- tbl(mimic, sql(query_map))

map_cvp_tbl <- collect(map_cvp, n=Inf)

write.csv(map_cvp_tbl, file = "../datathon_data/map_cvp.csv")
