# Ash3d_cryptotephra
This software sets up and runs a large number of simulations using the tephra dispersal software Ash3d.  It was written to track the dispersal of distal volcanic ash throughout the northern hemisphere for comparison with cryptotephra deposits, particularly in Greenland.  

This software requires **[Ash3d](https://github.com/hshwaiger-usgs/Ash3d)**, **[Generic Mapping Tools (GMT)](https://www.generic-mapping-tools.org/)**, **[ImageMagick](https://imagemagick.org/index.php)**, a Fortran compiler such as **[GNU gfortran](https://gcc.gnu.org/fortran/)** and a python interpreter.  It is intended for use on a linux system.  Full instructions on how to download and use this software is in the readme.txt file in the src directory.

By Larry Mastin, U.S. Geological Survey <lgmastin@usgs.gov>

# How these scripts work

The scripts in this repository perform the following tasks:  

1. Creates a table of inputs to be used by all simulations
2. Creates a series of directories, each of which will contain inputs and outputs for one simulation.
3. Goes sequentially through each directory, performing the following tasks
    - Add soft links to various input files, wind files
    - Run a fortran program (MakeInput.f90) that reads from the input table and creates an Ash3d input file
    - Run the model in background
4. Waits for all runs to finish.
5. Goes through each directory sequentially, performing the following post-processing tasks:
   - Create a gif map using GMT
   - Zip kml files into kmz files
   - Rename files
   - Write tephra thicknesses at specific locations to a summary file
   - Copy output files to a "run_output" directory with subdirectories for each file type

The files that perform these tasks are in the src directory.  Input files used by Ash3d or GMT are in the input_files directory.  Readme files in those directories explain each file and how it is used.  

