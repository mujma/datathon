require(utils)
library(data.table)
library(dplyr)

data = fread("/Users/ujma/Desktop/repos/datathon/map_cvp.csv", sep=";")
data$cvp = as.numeric(data$cvp)
data$map = as.numeric(data$map)
data$charttime = as.POSIXct(data$charttime, format="%Y-%m-%d  %H:%M:%S")

data[, pp:=map-cvp]
p = data[subject_id == 6892]

by_patient = data[,list(mean(pp), n=length(pp)), by=list(hadm_id, subject_id)]

//how many times for the first 24h, number of times pp<55

patients = unique(data$subject_id)
data_first_24h = data[0:0]

for(i in 1:length(patients)) {
  print(i)
  patient_data = data[subject_id==patients[i]]
  start = min(patient_data$charttime)
  start_24h = start + 3600*24
  patient_data = patient_data[charttime<start_24h]
  data_first_24h = rbind(data_first_24h, patient_data)
}

threshold = 55

patients = unique(data_first_24h$subject_id)

patients_pp = data.table(hadm_id=1:1, subject_id=1:1, bt=1:1, at=1:1)[0:0]

for(i in 1:length(patients)) {
  print(i)
  patient_data = data_first_24h[subject_id==patients[i]][order(charttime)]
  patient_data[, td:=c(0, diff(patient_data$charttime))]
  hadm_ids = unique(patient_data$hadm_id)
  for(j in 1:length(hadm_ids)) {
    hadm_id = hadm_ids[j]
    subject_id = patients[i]
    bt = sum(patient_data[pp<=threshold]$td)
    at = sum(patient_data[pp>threshold]$td)
    if(bt + at != sum(patient_data$td)) {
      print("Times don't add up")
      print(bt)
      print(at)
    }
    if((bt + at)/60 > 24) {
      print("Times above 24h")
    }
    patients_pp = rbind(patients_pp, list(hadm_id, subject_id, bt, at))
  }
}

patients_pp[(bt+at)/60>23]








