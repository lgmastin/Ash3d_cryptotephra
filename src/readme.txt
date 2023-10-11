
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
    2)  Go into each directory and:
         a) Add soft links and dependent files
         b) run MakeInput to create an input file (line 184)
         c) run Ash3d (lines 188-189)
    3)  After simulations are complete, go into each directory and:
         b) make gif map of output (line 231)
         c) reformat and/or rename other output files, and copy them to the directory OUTPUTDIR
            (lines 233-270)

*****************************************************************************
HOW TO RUN THE SIMULATIONS

1)  Make shell scripts executable
    chmod u+x  make_utils.sh map_crypto_deposit.sh run_crypto_sims.sh

2)  
