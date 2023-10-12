#Script that generates ESP's for MCMC simulations

import sys
import numpy as np
import datetime
import math

####################################################################
## KEY INPUTS TO CHECK
Height_km_asl   = 22    #plume height, km asl
DRE             = 1.36  #erupted volume, km3 dense-rock equivalent
Duration_hrs    = 3.0   #eruption duration in hours
grainsize_mm    = 0.03  #grain size, mm
density_kgm3    = 2000. #grain density, kg/m3
distal_fraction = 0.05  #fraction of the erupted mass that is transported beyond ~1,000 km
nruns           = 1001  #number of simulations (should be 1 greater than the actual number)
outfile = "input_table.txt"  #name of table to be written out
####################################################################

## Set constants
bulk_to_DRE   =0.40                             #conversion factor: bulk volume to DRE
months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

## Input ranges
StartDate           = datetime.datetime(1948,01,01,00,00,00,00)
EndDate             = datetime.datetime(2014,12,31,00,00,00,00)
sigma_m_fines       = 0.15  #Standard deviation in mass fraction of fines
mean_m_fines        = 0.5  #mean value of m_fines
sigma_mu_agg        = 0.1  #standard deviation of aggregate size, phi units
mean_mu_agg         = 2.4  #Mean aggregate size, phi units

##Initalize variables
year   = np.zeros((nruns,), dtype=int)
month  = np.zeros((nruns,), dtype=int) #np.zeros((5,), dtype=int)
day    = np.zeros((nruns,), dtype=int)
hour   = np.zeros((nruns,), dtype=int)
minute = np.zeros((nruns,), dtype=int)
second = np.zeros((nruns,), dtype=int)

## Calculate the eruption start time
dateval = np.random.random_sample((nruns,))  #generate nruns of random numbers
MidDate = StartDate + datetime.timedelta(0.5*24472)
TimeDif = EndDate - StartDate
TimeDif_days = TimeDif.days
for irun in range(0,nruns-1):
    Eday         = StartDate + datetime.timedelta(dateval[irun]*TimeDif_days)
    year[irun]   = Eday.year
    month[irun]  = int(Eday.month)
    day[irun]    = Eday.day
    hour[irun]   = Eday.hour
    minute[irun] = Eday.minute
    second[irun] = Eday.second

## Write out results
f = open(outfile, "w")
f.write('SUMMARY OF INPUT VALUES USED IN HANFORD RUNS\n')
f.write('run #     start time         plume height  duration   volume   grainsize  density    distal\n')
f.write('        yyyymmddhh.hh             km          hrs      km3        mm       kg/m3    fraction\n')
for irun in range(0,nruns-1):
    f.write('%5d   %02d-%3s-%04d %02d:%02d:%02d    %06.2f      %06.2f    %06.4f    %6.4f    %4.1f   %6.3f\n' \
           % (irun+1,day[irun],months[month[irun]-1],year[irun],\
           hour[irun],minute[irun],second[irun],\
           Height_km_asl,Duration_hrs,DRE,\
           grainsize_mm,density_kgm3,distal_fraction))
    print '%5d   %02d-%3s-%04d %02d:%02d:%02d    %06.2f      %06.2f    %06.4f    %6.4f    %4.1f   %6.3f' \
           % (irun+1,day[irun],months[month[irun]-1],year[irun],\
           hour[irun],minute[irun],second[irun],\
           Height_km_asl,Duration_hrs,DRE,\
           grainsize_mm,density_kgm3,distal_fraction)
f.close()

