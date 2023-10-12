
*******************************************************************************
EXPLANATION OF SOURCE FILES

ESP_generatory.py 
   --creates a table of input parameters, one row for each simulation
     Input table is typically stored in ../input_files/input_table.txt

MakeInput.f90   
  --Fortran code that creates an Ash3d input file before each simulation
    The compiled program is typically stored in ../bin/MakeInput

make_utils.sh
  --shell script that compiles MakeInput.f90 and reformatter.f90, and places
    the executables in ../bin

map_crypto_deposit.sh
  --shell script that uses GMT (Generic Mapping Tools) to create a deposit
    map following a simulation.

read_thickness.py
  --python script that reads output deposit file, extracts the deposit thickness
    at a series of ice-core locations, and writes those thicknesses to the
    file "ice_core_thicknesses.txt".  Currently, the ice core locations are
    specified within this file on lines 94-97.  They include NGRIP2, GISP2,
    RECAP, Tunu2022, H. Tausen, NEEM, DYE3, Ak Nauk, and Mt. Logan.

reformatter.f90
  --fortran program that reads an ESRI_ASCII deposit file and writes to a file
    of ASCII gridded output that contains one row in the file for each row
    in the model.  This format is easily readable by Matlab using the "load" command.

run_crypto_sims.sh
  --shell script that runs all the simulations.  It's workflow is as follows:
    1)  Create or clean a directory (OUTPUTDIR) that will contain model output (lines 73-92)
    2)  Create header lines for tables of output that will be populated (lines 95-110, 149-151)
    3)  Create or clean a set of directories (RUNDIRS) in which simulations are run  (lines 121-143)
    4)  Go into each directory and:
         a) Add soft links and dependent files
         b) run MakeInput to create an input file (line 184)
         c) run Ash3d (lines 188-189)
    5)  After simulations are complete, go into each directory and:
         a) make gif map of output (line 231)
         b) reformat and/or rename other output files, and copy them to the directory OUTPUTDIR
            (lines 233-270)

*****************************************************************************
HOW TO RUN THE SIMULATIONS

1)  Clone this repository.  It will create the directory Ash3d_cryptotephra

2)  Create directories.  Let's say you decide to create a directory called /home/username/$volcanoname
       cd /home/username                    #move to /home/username
       mkdir $volcanoname                   #create the directory
       cd $volcanoname                      #move into that directory
       mkdir RunDirs run_output             #create subdirectories
       mkdir RunDirs/temp_output            #create directory for temporary output
       mv [path]/Ash3d_cryptotephra .       #move working directory to /home/username/$volcanoname
       cd Ash3d_cryptotephra                #move to Ash3d_cryptotephra directory
       mkdir bin                            #make bin directory within Ash3d_cryptotephra

3)  Make shell scripts executable
       cd Ash3d_cryptotephra/src
       chmod u+x  make_utils.sh map_crypto_deposit.sh run_crypto_sims.sh

4)  Open ESP_generator.py and review the source parameters (lines 10-17)
       Note that, Ash3d simulations as currently set up for cryptotephras only model
       the transport of fine, distal ash at great distance.  Past studies (e.g., Webster
       et al., 2012, ) have found that the fraction of erupted mass that  makes it into
       the distal cloud is on the order of 5%.  Thus, we use this value as the actual mass
       modeled.  We also find that runtimes are shortest if we calculate transport of a 
       single grain size.  That grain size is specified in the input table.
         Height_km_asl  = plume height km asl (line 10)
         DRE            = erupted volume, km3 dense rock (line 11)
         Duration_hrs   = eruption duration in hours (line 12)
         grainsize_mm   = erupted grain size in mm (line 13)
         density_kgm3   = density of erupted grains, in kg/m3 (line 14)
         distal_fraction= fraction of erupted mass that remains in the cloud beyond ~1,000 km
         nruns          = number of runs listed in input table (line 16)
         $outfile       = file name of input table to be written (line 17)
              --this should be the same as the name to be read in MakeInput.f90, line 47
              --current default is "input_table.txt"

5)   Run ESP_generatory.py to generate the new input table
       python ESP_generator.py
       vi input_table.txt                   #open newly generated table and make sure it looks okay
       mv input_table.txt ../input_files    #move new table to ../input_files directory

6)   Modify MakeInput.f90 to make sure input and output file paths are appropriate
       vi MakeInput.f90
       check the following:
           --Name and path of input table (line 32)
                something like /home/username/$volcanoname/Ash3d_cryptotephra/input_files/input_table.txt
           --path of directory where input summary is written  (line 33)
                should be /home/username/%volcanoname/RunDirs/temp_output
           --model nodal spacing, degrees (line 31)
                   For these global simulations, I've used 1.0 degree for both
                   DX and DY.  If you are running a test and don't want to wait
                   long however, you can set it to a coarser value, e.g., 5.0.
                   However the model is more likely to stop prematurely with a
                   mass conservation error if you do this.
           --Volcano name (line 34)
           --Volcano latitude & longitude (lines 35 & 36)

7)    Compile MakeInput.f90 and test it
        gfortran -o MakeInput MakeInput.f90     #compiles it
        ./MakeInput 00001                       #Runs it, reading inputs for run #1
        --You should see a line of numbers written out.  And you should see a new file,
          ash3d_input.inp, in the current directory.
        --If the file was written out okay, delete it, and recompile the executable in the bin directory
          rm ash3d_input.inp
          ./make_utils.sh              #compiles MakeInput & reformatter, and puts the executables in ../bin

8)      Check map_crypto_deposit.sh
         This shell script runs Generic Mapping Tools (GMT) to create a gif map of the deposit
         mass per unit area.  It uses other input files that are contained in 
         Ash3d_cryptotephra/input_files.  The location of this directory is specified on line 29
         as the variable GRAPHICSDIR.  It should be something like:
            "/home/username/volcanoes/$volcanoname/Ash3d_cryptotephra/input_files"
         Make sure that it points to the current location of this directory.

9)      This python script interpolates model output to find the deposit thickness at ice core
         locations, and writes the results.  On line 10, the variable "outfile2" gives the
         name and location of the thickness summary file where results are written.  It should
         be something like:
            "/home/username/volcanoes/$volcanoname/RunDirs/temp_output/thickness summary.txt"
         Please check and make sure that the name and path are correct.

8)     Set up run_crypto_sims.sh
        FIRST:  Make sure the names and paths of files and directories are appropriate
               ASH3DDIR (line 66) is the location of the Ash3d program
               WINDDIR  (line 67) is the location of the wind files
               UTILDIR  (line 68) is the location of utility files 
                               (something like /home/username/$volcanoname/Ash3d_cryptotephra)
               RUNDIRS  (line 72) is the name of the run directories
                               (something like /home/username/$volcanoname/RunDirs)
               OUTPUTDIR  (line 72) is the name of the output directory
                               (something like /home/username/$volcanoname/run_output)
        NEXT:  Test the script.  Because this script can set up thousands of simulations as a batch
               job, you want to make sure that it is running correctly before starting.  I typically
               test it by running a single simulation at low resolution (which runs fast), and 
               checking the outputs to make sure they've been written out correctly.
               PROCEDURE FOR TESTING              
                  1)  Set a low model resolution
                         a) in MakeInput.f90, set "nodal_spacing" (line 31) to 5.0
                         b) compile MakeInput ("./make_utils.sh")
                  2)  In run_crypto_sims.sh, 
                         a) set dirmax to 1 (line 60).  This is the number of simulations 
                                run simultaneously
                         b) set cyclemax to 0 (line 61).  This is the number of 
                                cycles (minus 1) in which dirmax simulations are run.
                         c) un-comment line 205 by removing the hashtag from the front of:
                                #${ASH3DDIR}/bin/Ash3d ash3d_input.inp
                         d) comment out line 206 by adding a hashtag in front of:
                                ${ASH3DDIR}/bin/Ash3d ash3d_input.inp > logfile.txt 2>&1 &
                            --these last two changes direct Ash3d run output to the screen,
                              so we can see if there are error messages.
                  3) run run_crypto_sims.sh
                       ./run_crypto_sims.sh
                  4) Check your result
                        a) watch the progress Ash3d progress on the screen, make sure there
                            are no error messages
                        b) Check the results.  In run_output, there should be a new folder
                            with a name equal to the current date.  Within that folder should
                            be the following sub-folders and files:
                               Folder        subfolder     file           Explanation
                               DepositFiles/
                                             ESRI_ASCII/   Run00001.txt   Gridded ASCII deposit file
                                             Matlab/       Run00001.txt   Gridded ASCII deposit file
                               input_files                 Run00001.txt   Ash3d input file
                               MapFiles/                   Run00001.gif   gif map of deposit
                               sample_thickness/           Run00001.txt   Deposit thickness at ice core locations
                               summary/               input_summary.txt   summary table of inputs for each run
                                                  thickness_summary.txt   summary table of thicknesses for each
                               zip_files/                  Run00001.zip   zip file containing all inputs & outputs
                           Verify that all these output files are present.  Open each file
                           and make sure it looks okay.
            FINALLY:  Set up for batch run
              PROCEDURE FOR FINAL BATCH RUN SETUP
                  1)  Reset model resolution
                         a) in MakeInput.f90, set "nodal_spacing" (line 31) to 1.0
                         b) compile MakeInput ("./make_utils.sh")
                  2)  In run_crypto_sims.sh, 
                         a) set dirmax to 50 (line 60).  This sets 50 simulations  to
                                run simultaneously
                         b) set cyclemax to 19 (line 61), or whatever you want.  This is the number of 
                                cycles (minus 1) in which dirmax simulations are run.  The
                                product dirmax*(cyclemax+1) gives the total number of simulations
                                that will be run.  Make sure this is less than or equal to the 
                                number of runs listed in ../input_files/input_table.txt
                         c) comment line 205 by removing the hashtag from the front of:
                                #${ASH3DDIR}/bin/Ash3d ash3d_input.inp
                         d) un-comment out line 206 by adding a hashtag in front of:
                                ${ASH3DDIR}/bin/Ash3d ash3d_input.inp > logfile.txt 2>&1 &
                            --these last two changes re-direct Ash3d run output to logfile.txt
                  3) run run_crypto_sims.sh
                       sbatch run_crypto_sims.sh
                                  

	
