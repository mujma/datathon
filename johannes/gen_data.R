library(RPostgreSQL)
library(dplyr)

mimic <- src_postgres(dbname = "mimic", host = "localhost", port = 15432, 
                      user = "mimic", password = "mimic")

# MAP and CVP ------------------

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
saveRDS(map_cvp_tbl, file = "../datathon_data/map_cvp.RDS")

# Creatinine ------------------

query_creatinine <- "select lab.subject_id, lab.hadm_id,
  lab.itemid, lab.charttime, lab.valuenum
  from mimiciii.labevents lab
    inner join (SELECT map.hadm_id, min(map.charttime) as first_charttime, max(map.charttime) as last_charttime
      FROM mimiciii.chartevents map
      LEFT OUTER JOIN mimiciii.chartevents cvp
      ON cvp.charttime = map.charttime
      WHERE map.itemid = 52 AND cvp.itemid = 113 AND map.value != 'None' 
      AND cvp.value != 'None' AND cvp.hadm_id = map.hadm_id
      GROUP BY map.hadm_id
      ORDER BY map.hadm_id) map_cvp_interval
    ON lab.hadm_id = map_cvp_interval.hadm_id
  where itemid = 50912 AND
    lab.charttime >= map_cvp_interval.first_charttime 
    AND lab.charttime <= map_cvp_interval.first_charttime + interval '2 days'
  ORDER BY lab.hadm_id, lab.charttime"
 
creatinine <- tbl(mimic, sql(query_creatinine))
creatinine_tbl <- collect(creatinine)

write.csv(creatinine_tbl, file = "../datathon_data/creatinine.csv")
saveRDS(creatinine_tbl, file = "../datathon_data/creatinine.RDS")


# Patient demographics ----------

query_adms <- "SELECT adm.hadm_id, adm.subject_id, adm.ethnicity, adm.diagnosis, adm.admittime,
  extract(epoch from adm.admittime - pt.dob)/(60*60*24*365.25) AS age_admit_years, 
  pt.gender
FROM mimiciii.admissions adm
left outer join mimiciii.patients pt
ON adm.subject_id = pt.subject_id
WHERE adm.hadm_id IN (SELECT distinct map.hadm_id
	FROM mimiciii.chartevents map
	LEFT OUTER JOIN mimiciii.chartevents cvp
	ON cvp.charttime = map.charttime
	WHERE map.itemid = 52 AND cvp.itemid = 113 AND map.value != 'None' 
		AND cvp.value != 'None' AND cvp.hadm_id = map.hadm_id)
ORDER BY adm.hadm_id"

adms_demo <- tbl(mimic, sql(query_adms))

adms_demo_tbl <- collect(adms_demo, n=Inf)

write.csv(adms_demo_tbl, file = "../datathon_data/adms_demo.csv")
saveRDS(adms_demo_tbl, file = "../datathon_data/adms_demo.RDS")
