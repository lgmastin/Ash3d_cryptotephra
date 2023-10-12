#Script that generates ESP's for MCMC simulations

import sys
import numpy as np
import datetime
import math
from netCDF4 import Dataset

#Specify the location of the thickness summary file
outfile2 = '/home/lgmastin/temp/RunDirs/temp_output/thickness_summary.txt'

#First, define the 2d interpolation function
def interp2d(gridX,gridY,Z,interpX,interpY):
	#function that interprets values from a 2D grid.
	#a bilinear interpolation is assumed
	#Inputs:
	#  gridX = vector of x values having the same number of columns as Z
	#  gridY = vector of y values having the same number of rows as Z
	#  Z     = z values, a 2D matrix
	#  interpX = column vector of x values of points to be interpolated
	#  interpX = column vector of y values of points to be interpolated
	#Output:
	#  Z2      = column vector of interpolated Z values

	## Begin looping
	Z2 = np.zeros((len(interpX),1), dtype=float)
	dX  = gridX[1]-gridX[0]         #X spacing` (assumed uniform)
	dY  = gridY[1]-gridY[0]         #Y spacing 

	for ipt in range(len(interpX)):

		if interpX[ipt] < 0: interpX[ipt] = interpX[ipt]+360.0

		#Find the x nodes to interpolate between
		iXmax  = len(gridX)-1
		iX     = 0        #looping through tpe x values
		while gridX[iX] < interpX[ipt]:
			iX = iX+1
			if iX > iXmax : break
		iXlast = iX-1
		iXnext = iX

		#Find the x nodes to interpolate between
		iY     = 0
		iYmax  = len(gridY)-1
		while gridY[iY] < interpY[ipt]:
			iY = iY+1
			if iY > iYmax : break
		iYlast = iY-1
		iYnext = iY

                #print '   ipt=%d, lon=%f, lat=%f' % (ipt,interpX[0],interpY[0])
                #print '      iXlast=%d, iXnext=%d' % (iXlast,iXnext)
                #print '      iYlast=%d, iYnext=%d' % (iYlast,iYnext)
		#print '      gridX      interpX    gridX'
                #print '       %f        %f         %f' % (gridX[iXlast],interpX[ipt],gridX[iXnext])
                #print '      gridY=%f'                 % (gridY[iYnext])
                #print '      interpY=%f'               % (interpY[ipt])
                #print '      gridY=%f'                 % (gridY[iYlast])
                #print '      z[iYnext,iXlast]=%e,       z[iYnext,iXnext]=%e' % (Z[iYnext,iXlast],Z[iYnext,iXnext])

		#Find out if we're at an edge or corner of the grid
		if iXlast < 0:
			iXlast = iXnext        #we're at the left edge.
		elif iXnext > iXmax:
			iXnext = iXlast	       #right edge
		if iYlast < 0:
			iYlast = iYnext        #we're at the lower edge.
		elif iYnext > iYmax:
			iYnext = iYlast        #upper edge

		#Start interpolating.  First, in y, along each of the x nodes
		if iYnext > iYlast:
			Z_at_xlast = Z[iYlast,iXlast] + (Z[iYnext,iXlast]-Z[iYlast,iXlast]) * \
                                     (interpY[ipt]-gridY[iYlast])/dY
		else:
			Z_at_xlast = Z[iYlast,iXlast]
		if iXnext > iXlast:
			Z_at_xnext = Z[iYlast,iXnext] + (Z[iYnext,iXnext]-Z[iYlast,iXnext]) * \
                                     (interpY[ipt]-gridY[iYlast])/dY
		else:
			Z_at_xnext = Z_at_xlast
		#print '      Z_at_xlast=%e,             Z_at_xnext=%e'       % (Z_at_xlast,Z_at_xnext)
                #print '      z[iYlast,iXlast]=%e,       z[iYlast,iXnext]=%e' % (Z[iYlast,iXlast],Z[iYlast,iXnext])
		Z2[ipt] = Z_at_xlast + (Z_at_xnext-Z_at_xlast)*(interpX[ipt]-gridX[iXlast])/dX
                #print '                       Z2[ipt]=%e' % (Z2[ipt])
		#x = str(input('Okay (y/n)?:'))
		#if x=='n' : sys.exit()
	return Z2
		
## Set run number from command-line argument
RN = sys.argv[1]
RunNumber = int(RN)

## Set station values
outfile='ice_core_thicknesses.txt'
station_names = ['NGRIP2','GISP2','RECAP','Tunu2022','H. Tausen', \
                  'NEEM','DYE3','Ak Nauk','Mt. Logan']
station_lat   = [75.1,72.6,71.3,78,0,82.5,77.5,65.2,80.6,60.6]
station_lon   = [-42.3,-38.5,-26.7,-33.9,-38.0,-51.1,-43.8,94.8,-140.5]

##Initalize thickness variable
#grid_thickness   = np.zeros((360,160), dtype=float)

## Read netcdf file
ncfile = '3d_tephra_fall.nc'
ncdata = Dataset(ncfile)
time           = ncdata['t']
lon            = ncdata['lon']
lat            = ncdata['lat']
grid_thickness = ncdata['depothick'][len(time)-1,:,:]

## get eruption start time
StartTime = ncdata.getncattr('NWPStartTime')

## Interpolate
X, Y = np.meshgrid(lon,lat)            #create a meshgrid
x2   = -105.0
y2   = 65.0
f=interp2d(lon,lat,grid_thickness,station_lon,station_lat)
thickness_here=1000*f

## Write out results to "ice_core_thickness.txt"
f = open(outfile, "w")
#print ("{0:<10}{1:>14}{2:>14}{3:>14}".format('Name','latitude','longitude','g/m2'))
f.write ("{0:<10}{1:>14}{2:>14}{3:>14}\n".format('Name','latitude','longitude','g/m2'))
for istat in range(len(station_names)):
        #print ("{0:10}{1:14.4f}{2:14.4f}{3:14.5e}".format(station_names[istat],station_lon[istat], \
        #                                     station_lat[istat],float(thickness_here[istat])))
        f.write("{0:10}{1:14.4f}{2:14.4f}{3:14.5e}\n".format(station_names[istat],station_lon[istat], \
                                             station_lat[istat],float(thickness_here[istat])))
f.close()

## Write out results to "thickness_summary.txt"
f = open(outfile2,"a+")
f.write("%05d    %20s%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f%12.5f\n" % \
                   (RunNumber,StartTime,float(thickness_here[0]),float(thickness_here[1]),float(thickness_here[2]),float(thickness_here[3]),\
                                        float(thickness_here[4]),float(thickness_here[5]),float(thickness_here[6]),float(thickness_here[7]),\
                                        float(thickness_here[8])))
f.close()
