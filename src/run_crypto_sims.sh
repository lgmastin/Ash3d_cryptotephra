#!/bin/bash

#MCMC driver: a script that drives a series of Ash3d simulations for Monte Carlo analysis

#This script runs jobs in parallel on up to 8 processors and then combines the results afterwards.

###THINGS TO CHECK BEFORE STARTING A RUN
#1)  RunStartNumber is okay
#2)  dirmax and cyclemax are all okay
#3)  Make sure "run" command is set to output log file (around line 190)
#       if testing, use the command:
           # ${ASH3DDIR}/bin/Ash3d ash3d_input.inp
#       otherwise, use the command:
           # ${ASH3DDIR}/bin/Ash3d ash3d_input.inp > logfile.txt 2>&1 &
#4)  Model resolution is set properly in MakeInput.f90
#5)  Output directory name is set properly in MakeInput.90, line 96
#6)  MakeInput.f90 is reading from correct input table (line 47)
#7)  MakeInput and other utilities are compiled and in ../bin directory
           #type the commane "./make_utils.sh" to do this
#8)  readme.txt comments are up to date below (around line 105 of this script)
#9)  Name of volcano is appropriate throughout this script
#10) Output is okay:
       #a)  ArrivalTimes
               #1)  ArrivalTimes/reformatted
       #b)  DepositFiles
               #1)  DepositFiles/reformatted
       #c)  input_files
       #d)  MapFiles
       #e)  input_summary.txt
       #f)  ice_core_thickness
       #g)  zip_files  (check all files)

#####PARAMETERS THAT CONTROL HOW MANY RUNS ARE PERFORMED
#These parameters determine 
#     1) the start number of the first run
#     2) the number of simulations to run in parallel (dirmax), and
#     3) The number of cycles of paralle simulations (cyclemax)
#The total number of runs performed = dirmax*(cyclemax+1)
#Runs are numbered from RunStartNumber to (RunStartNumber + dirmax*(cyclemax+1))
RunStartNumber=1     #Run number for first run in the series
dirmax=2             #Number of simultaneous runs (1 to 50)
cyclemax=0           #Number of cycles (0 to ????)
totruns=$(( $dirmax * ($cyclemax + 1) ))
echo "totruns=$totruns"

#####NAMES OF DIRECTORIES THAT CONTAIN PROGRAMS AND UTILITIES
ASH3DDIR=/home/lgmastin/Ash3d/git/temp/Ash3d
WINDDIR=/data2/WindFiles                               #location of wind files
UTILDIR=/home/lgmastin/volcanoes/Okmok/scripts           #location of programs reading thickness

#####NAMES OF DIRECTORIES WHERE RUNS ARE PERFORMED, AND WHERE OUTPUT IS WRITTEN
FileDate=`date "+%Y%b%d"`                               #date, to be appended to file names
RUNDIRS=/home/lgmastin/volcanoes/Okmok/RunDirs          #directory where runs are performed
OUTPUTDIR=/home/lgmastin/volcanoes/Okmok/scripts/test_output  #directory containing output

####Output subdirectories.
##If the runs are done in a group of 1,000 or so at a time, each group of 1,000 will
#be stored in a directory named according to the run date.
ZIPFILEDIR=${OUTPUTDIR}/zip_files                          #location of zip files
DEPOSITDIR_ESRI=${OUTPUTDIR}/DepositFiles/ESRI_ASCII            #location of DepositFiles
DEPOSITDIR_MATLAB=${OUTPUTDIR}/DepositFiles/Matlab               #location of reformatted deposit files
INFILEDIR=${OUTPUTDIR}/input_files                         #location of reformatted deposit files
THICKNESSDIR=${OUTPUTDIR}/sample_thickness                 #location of files of thickness at ice core locations
MAPDIR=${OUTPUTDIR}/MapFiles                               #location of gif maps

#location of summary tables.  Note that this is not in OUTPUTDIR, because OUTPUTDIR has the current
#date and time stamp.  Fortran codes like read_thickness.f90 have the location of the summary tables
#hard-coded and can't modify those addresses for the dates.  So the summary tables will have to be
#moved to ${OUTPUTDIR}/summary at the end of the simulations
SUMMARYTABLEDIR=/home/lgmastin/volcanoes/Okmok/RunDirs/temp_output      #location of summary table

#See if the output directory exists.  If so, clean it out.  If not, create it.
if test -r ${OUTPUTDIR}; then                                                        #See if this directory exists
       echo "${OUTPUTDIR} exists.  Cleaning it."                                         #If so, clean it out.
       rm -f ${ZIPFILEDIR}/*  
       rm -f ${DEPOSITDIR_ESRI}/Run*
       rm -f ${INFILEDIR}/*
       rm -f ${DEPOSITDIR_MATLAB}/*
       rm -f ${THICKNESSDIR}/*
       rm -f ${MAPDIR}/*
    else
       echo "creating directory ${OUTPUTDIR} and its subdirectories"                      #If not, make it . . .
       mkdir ${OUTPUTDIR}
       mkdir ${OUTPUTDIR}/DepositFiles
       mkdir ${DEPOSITDIR_ESRI}
       mkdir ${DEPOSITDIR_MATLAB}
       mkdir ${INFILEDIR}
       mkdir ${THICKNESSDIR}
       mkdir ${MAPDIR}
       mkdir ${ZIPFILEDIR}
fi
rm -f ${SUMMARYTABLEDIR}/*                                                     #remove all summary tables

#####################   Create new summary files  ################################
echo "creating new summary files"
#create summary log file
echo "SUMMARY OF INPUT VALUES USED IN HANFORD RUNS ON ${FileDate}" > ${SUMMARYTABLEDIR}/input_summary.txt
echo "run #     start time                       plume height  duration   volume   m_fines    mu_agg" >> ${SUMMARYTABLEDIR}/input_summary.txt
echo "          yyyymmddhh.hh  hrs_since_1900         km          hrs      km3                 phi" >> ${SUMMARYTABLEDIR}/input_summary.txt

#     0       10        20        30        40        50        60        70        80        90        100       110       120       130
#     123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901
echo "                                                                       Ice core locations" > ${SUMMARYTABLEDIR}/thickness_summary.txt
echo "                                  NGRIP2      GISP2       RECAP       Tunu2022    H. Tausen   NEEM        DYE3        Ak Nauk     Mt. Logan" >> ${SUMMARYTABLEDIR}/thickness_summary.txt
echo "         longitude                317.7       321.3       333.3       326.1       322.0       308.9       316.2       94.8        219.5"     >> ${SUMMARYTABLEDIR}/thickness_summary.txt
echo "         latitude                 75.1        72.6        71.3        78.0        82.5        77.5        65.2        80.6        60.6"      >> ${SUMMARYTABLEDIR}/thickness_summary.txt
echo "Run #    Start date                                                      thicknesses, g/m2"                                      >> ${SUMMARYTABLEDIR}/thickness_summary.txt

####################   Create new readme.txt file #################################
echo "This folder contains example output from runs using this script" > ${OUTPUTDIR}/readme.txt
#Check to see whether any files are missing

SECONDS=0                        #start time counter
t0=`date`                        #date, printed at end of run
date

#####################   Make the directories  ####################################
echo "making run directories"
for (( idir=1;idir<=$dirmax;idir++ ))
do
   if [[ ${idir} -lt 10 ]]; then
      DirNumber="0${idir}"
    else
      DirNumber="${idir}"
   fi
   if test -r  ${RUNDIRS}/Dir${DirNumber}; then
         #echo "${RUNDIRS}/Dir${DirNumber} exists.  Cleaning"
         rm -f ${RUNDIRS}/Dir${DirNumber}/*
         cd    ${RUNDIRS}/Dir${DirNumber}
         ln -s ${UTILDIR}/input_files/ice_core_locations.txt .
         ln -s ${UTILDIR}/input_files/ice_core_locations.xy  .
         ln -s ${UTILDIR}/input_files/thickness_scale.png  .
         ln -s ${WINDDIR} Wind_nc
      else
         #echo "creating ${RUNDIRS}/Dir${DirNumber}"
         mkdir ${RUNDIRS}/Dir${DirNumber}
         cd    ${RUNDIRS}/Dir${DirNumber}
         ln -s ${UTILDIR}/input_files/ice_core_locations.txt .
         ln -s ${UTILDIR}/input_files/ice_core_locations.xy  .
         ln -s ${UTILDIR}/input_files/thickness_scale.png  .
         ln -s ${WINDDIR} Wind_nc
   fi
done

#####################   Set up and run models  ####################################
for (( icycle=0;icycle<=$cyclemax;icycle++ )); do

   #write table headers for input values
   echo "setting up and running models"
   echo "run #     start time                       plume height  duration   volume   m_fines   mu_agg"
   echo "          yyyymmddhh.hh  hrs_since_1900         km          hrs      km3"

   #Start looping through directories
   for (( idir=1;idir<=$dirmax;idir++ )); do
         irun=`echo "$RunStartNumber - 1 + $icycle * $dirmax + $idir" | bc -l`
         #Make run numbers into five-digit numbers
         if [[ $irun -lt 10 ]]; then
            RunNumber="0000${irun}"
          elif [[ $irun -lt 100 ]]; then
            RunNumber="000${irun}"
          elif [[ $irun -lt 1000 ]]; then
            RunNumber="00${irun}"
          elif [[ $irun -lt 10000 ]]; then
            RunNumber="0${irun}"
          else
            RunNumber=${irun}
         fi
         #make dir names into three-digit numbers
         if [[ ${idir} -lt 10 ]]; then
            DirNumber="0${idir}"
          else
            DirNumber="${idir}"
         fi

         #move to the new directory
         cd ${RUNDIRS}/Dir${DirNumber}

         #remove old output files
         rm -f *.dat *.kmz ash3d_input.txt ash_arrivaltimes_airports.txt \
                 logfile.txt Ash3d_logfile.txt DepositFile_ESRI_ASCII.dat \
                 *.zip vertical_profile.txt vprofile01.txt

         #make the new input file
         ${UTILDIR}/bin/MakeInput ${RunNumber}        

         #run the model
         #echo "running ${ASH3DDIR}/bin/Ash3d_cc"
         #${ASH3DDIR}/bin/Ash3d ash3d_input.inp                             #used for testing
         ${ASH3DDIR}/bin/Ash3d ash3d_input.inp > logfile.txt 2>&1 &

   done
   echo "All done setting up and starting jobs. Waiting . . ."
   wait            #wait until background jobs have completed
   echo "Done waiting. Zipping and cleaning output"
   #####################  Wrap up results and post them  ############################
   for (( idir=1;idir<=$dirmax;idir++ )); do
         irun=`echo "$RunStartNumber - 1 + $icycle * $dirmax + $idir" | bc -l`
         #Make run numbers into five-digit numbers
         if [[ $irun -lt 10 ]]; then
            RunNumber="0000${irun}"
          elif [[ $irun -lt 100 ]]; then
            RunNumber="000${irun}"
          elif [[ $irun -lt 1000 ]]; then
            RunNumber="00${irun}"
          elif [[ $irun -lt 10000 ]]; then
            RunNumber="0${irun}"
          else
            RunNumber=${irun}
         fi
         #make dir names into three-digit numbers
         if [[ ${idir} -lt 10 ]]; then
            DirNumber="0${idir}"
          else
            DirNumber="${idir}"
         fi
         #move to the new directory
         #echo "     moving to ${RUNDIRS}/Dir${DirNumber}"
         cd ${RUNDIRS}/Dir${DirNumber}

         #flip and rename log files
         mv Ash3d.lst              Ash3d_logfile.txt              #logfile written by Ash3d

         #zip up the kml files
         #echo "        zipping up kmz files"
         zip -r -q deposit_thickness_mm.kmz deposit_thickness_mm.kml 
         zip -r -q ash_arrivaltimes_airports.kmz ash_arrivaltimes_airports.kml depTS*png
         #rm *.kml

         #make output gif map
         echo "        making output gif map"
         ${UTILDIR}/src/map_crypto_deposit.sh >> logfile.txt 2>&1

         #reformat the deposit file
         echo "        reformatting and copying deposit file"
         ${UTILDIR}/bin/reformatter DepositFile_____final.dat \
                                 DepositFile_Matlab.txt
         cp DepositFile_Matlab.txt ${DEPOSITDIR_MATLAB}/Run${RunNumber}.txt

         #flip and rename deposit file
         echo "        renaming deposit file"
         sed 's/$/\r/' DepositFile_____final.dat > DepositFile_ESRI_ASCII.txt
         rm DepositFile_____final.dat
         cp DepositFile_ESRI_ASCII.txt ${DEPOSITDIR_ESRI}/Run${RunNumber}.txt

         #flip and rename input file
         echo "        flipping and renaming input file"
         cp ash3d_input.inp ${INFILEDIR}/Run${RunNumber}.inp

         #create sample location thickness file
         echo "        creating ice core thickness file"
         python ${UTILDIR}/src/read_thickness.py ${RunNumber}
         cp ice_core_thicknesses.txt ${THICKNESSDIR}/Run${RunNumber}.txt

         #copy gif map to map directory
         echo "        copying gif map"
         cp deposit_thickness_gcm2.gif ${MAPDIR}/Run${RunNumber}.gif
         #echo  "        copying kmz deposit file"
         #cp Deposit.kmz ${MAPDIR}/Run${RunNumber}.kmz

         #zip up the results and copy them to the zip directory
         echo "        zipping up results"
         zip -q Run${RunNumber}.zip 3d_tephra_fall.nc \
                *.kmz ice_core_thickness.txt \
                Ash3d_logfile.txt logfile.txt \
                ash3d_input.inp \
                DepositFile_ESRI_ASCII.txt DepositFile_Matlab.txt \
                deposit_thickness_gcm2.gif
         mv Run${RunNumber}.zip ${ZIPFILEDIR}

         echo "     all done with Glacier run ${RunNumber}"
   done
   t1=`date`
   echo "MCMC driver start time: $t0"
   echo "End time at this loop: $t1"
   duration=$SECONDS
   hours=$(($duration / 3600))
   minutes=$(($duration / 60 - 60 * $hours))
   minutes2=$(($duration / 60))
   seconds=$(($duration - 60 * minutes2))
   echo "total seconds = $SECONDS"
   echo "$hours hours, $minutes minutes and $seconds seconds elapsed."
done

#flip the output files
echo "         flipping input_summary.txt"
sed 's/$/\r/' ${SUMMARYTABLEDIR}/input_summary.txt > ${SUMMARYTABLEDIR}/input_summary2.txt
mv ${SUMMARYTABLEDIR}/input_summary2.txt ${SUMMARYTABLEDIR}/input_summary.txt

#Move all the output tables to ${OUTPUTDIR}/summary
echo "Checking for existence of summary directory"
if test -r  ${OUTPUTDIR}/summary; then                        #see if this directory exists
     echo "moving files into summary directory"
     mv ${SUMMARYTABLEDIR}/* ${OUTPUTDIR}/summary                  #if so, move files into it
  else
     echo "creating summary directory"
     mkdir ${OUTPUTDIR}/summary                                    #if not, make the directory,
     echo "   moving files into summary directory"
     mv ${SUMMARYTABLEDIR}/* ${OUTPUTDIR}/summary                   #then move fiels into it
fi

t1=`date`
echo "MCMC driver start time: $t0"
echo "MCMC driver   end time: $t1"
duration=$SECONDS
hours=$(($duration / 3600))
minutes=$(($duration / 60 - 60 * $hours))
minutes2=$(($duration / 60))
seconds=$(($duration - 60 * minutes2))
echo "total seconds = $SECONDS"
echo "$hours hours, $minutes minutes and $seconds seconds elapsed."
echo "all done with MCMC simulations"
