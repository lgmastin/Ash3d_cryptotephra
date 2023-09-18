#Script that generates ESP's for MCMC simulations

import sys
import numpy as np
import datetime
import math

## Set constants
vent_elevation=0.3                              #vent elevation at Cone A, km
bulk_to_DRE   =0.40                             #conversion factor: bulk volume to DRE
nruns = 501                                      #number of simulations
months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

## Name of output file
outfile = "input_table_H10km.txt"

## Input ranges
min_bulk_km3        = 0.50
max_bulk_km3        = 0.50
min_DRE             = min_bulk_km3*bulk_to_DRE  #minimum erupted volume (km3 DRE)
max_DRE             = max_bulk_km3*bulk_to_DRE  #maximum erupted volume (km3 DRE)
StartDate           = datetime.datetime(1948,01,01,00,00,00,00)
EndDate             = datetime.datetime(2014,12,31,00,00,00,00)
sigma_m_fines       = 0.15  #Standard deviation in mass fraction of fines
mean_m_fines        = 0.5  #mean value of m_fines
sigma_mu_agg        = 0.1  #standard deviation of aggregate size, phi units
mean_mu_agg         = 2.4  #Mean aggregate size, phi units
sigma_height_change = 0.01  #std. of random changes in plume height

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

## Calculate the erupted volume
val=np.random.random_sample((nruns,))        #generate a nruns-length vector of random #'s
DRE = min_DRE+(max_DRE-min_DRE)*val
log_DRE = np.log10(DRE)

## Calculate heights using the best-fit relationship between erupted volume
#and plume height
mean_height_km = 25.9+6.64*log_DRE
#The random height adjustment below follows a Gaussian pdf with a mean of
#zero and a standard deviation of sd.
#Height_change = np.random.normal(loc=0, scale=sigma_height_change, size=(nruns,))
#Height_km=vent_elevation+mean_height_km+Height_change
Height_km=10

## Calculate the eruption rate, and the duration from that
rate_m3_per_s = ((Height_km-vent_elevation)/2)**4.15
Duration_hrs = 1.0e09*DRE/(3600*rate_m3_per_s)

## Calculate m_fines
m_fines = np.random.normal(loc=mean_m_fines, scale=sigma_m_fines, size=(nruns,))  #a Gaussian with mean=0.5, std=0.15
for i in range(len(m_fines)):
	#print('m_fines[i]=%5.3f' % (m_fines[i]))
	if m_fines[i]<0:
		#print('Changing %5.3f to 0' % (m_fines[i]))
		m_fines[i]=0
      
## Calculate mu_agg
mu_agg = np.random.normal(loc=2.4, scale=0.1, size=(nruns,))  #a Gaussian with mean=0.5, std=0.15
mu_agg  = np.round(mu_agg,decimals=1)             #round to nearest 0.1phi  

## calculate means and standard deviations to verify
print 'DRE mean=%4.2f, min=%4.2f, max=%4.2f' % (np.mean(DRE), np.min(DRE), np.max(DRE))
#print 'height change, mean=%4.2f, stdev=%4.2f' % (np.mean(Height_change),np.std(Height_change))
print 'm_fines, mean=%5.3f, stdev=%5.3f' % (np.mean(m_fines),np.std(m_fines))
print 'mu_agg, mean=%4.2f, stdev=%4.2f' % (np.mean(mu_agg),np.std(mu_agg))
        
## Write out results
f = open(outfile, "w")
f.write('SUMMARY OF INPUT VALUES USED IN HANFORD RUNS\n')
f.write('run #     start time         plume height  duration   volume   m_fines    mu_agg\n')
f.write('        yyyymmddhh.hh             km          hrs      km3                 phi\n')
for irun in range(0,nruns-1):
    f.write('%5d   %02d-%3s-%04d %02d:%02d:%02d    %06.2f      %06.2f    %06.4f    %6.4f    %4.1f\n' \
           % (irun+1,day[irun],months[month[irun]-1],year[irun],\
           hour[irun],minute[irun],second[irun],\
           #Height_km[irun],Duration_hrs[irun],DRE[irun],\
           Height_km,Duration_hrs[irun],DRE[irun],\
           m_fines[irun],mu_agg[irun]))
    print '%5d   %02d-%3s-%04d %02d:%02d:%02d    %06.2f      %06.2f    %06.4f    %6.4f    %4.1f' \
           % (irun+1,day[irun],months[month[irun]-1],year[irun],\
           hour[irun],minute[irun],second[irun],\
           Height_km,Duration_hrs[irun],DRE[irun],\
           m_fines[irun],mu_agg[irun])
f.close()

