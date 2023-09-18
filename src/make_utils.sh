#!/bin/bash

#Script that makes the utilities and places the executables in the bin directory
echo "gfortran -o ../bin/reformatter    reformatter.f90"
gfortran -o ../bin/reformatter    reformatter.f90
echo "gfortran -o ../bin/MakeInput MakeInput.f90"
#gfortran -o ../bin/MakeInput      MakeInput.f90
gfortran -o ../bin/MakeInput      MakeInput.f90
echo "all done"
