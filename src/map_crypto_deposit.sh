#!/bin/bash

#      This file is a component of the volcanic ash transport and dispersion model Ash3d,
#      written at the U.S. Geological Survey by Hans F. Schwaiger (hschwaiger@usgs.gov),
#      Larry G. Mastin (lgmastin@usgs.gov), and Roger P. Denlinger (roger@usgs.gov).

#      The model and its source code are products of the U.S. Federal Government and therefore
#      bear no copyright.  They may be copied, redistributed and freely incorporated 
#      into derivative products.  However as a matter of scientific courtesy we ask that
#      you credit the authors and cite published documentation of this model (below) when
#      publishing or distributing derivative products.

#      Schwaiger, H.F., Denlinger, R.P., and Mastin, L.G., 2012, Ash3d, a finite-
#         volume, conservative numerical model for ash transport and tephra deposition,
#         Journal of Geophysical Research, 117, B04204, doi:10.1029/2011JB008968. 

#      We make no guarantees, expressed or implied, as to the usefulness of the software
#      and its documentation for any purpose.  We assume no responsibility to provide
#      technical support to users of this software.

#wh-loopc.sh:           enables while loops?

echo "------------------------------------------------------------"
echo "running map_sensitivity.sh"
echo `date`
echo "------------------------------------------------------------"

# We need to know if we must prefix all gmt commands with 'gmt', as required by version 5
GMTv=5
GMTpre='gmt '
type gmt >/dev/null 2>&1 || { echo >&2 "Command 'gmt' not found.  Assuming GMTv4."; GMTv=4; GMTpre=' ';}

#These lines were added because for some reason my computer doesn't recognize "GMT",
#even though it uses version 5.
GMTv=5
#GMTpre='GMT '
GMTpre='gmt '
echo "GMTpre=$GMTpre, GMTv=$GMTv"
#GMTROOT="/home/ash3d/GMT/GMT4.5.9"
#UTILSDIR="/home/HanfordUser/Ash3d/vsc-ash"
UTILSDIR="/home/lgmastin/Ash3d/git/Ash3d_web"
PROGRAMDIR="${UTILSDIR}/bin"
GRAPHICSDIR="/home/lgmastin/volcanoes/Okmok/scripts/input_files"

#export PATH=/usr/local/bin:${GMTROOT}/bin:$PATH
echo "removing old files"
rm -f *.xyz *.grd contour_range.txt map_range.txt *.lev *.ps *.gif
infile="3d_tephra_fall.nc"

volc=`ncdump -h ${infile} | grep b1l1 | cut -d\" -f2 | cut -c1-30`
date=`ncdump -h ${infile} | grep Date | cut -d\" -f2 | cut -c 1-10`
echo $volc > volc.txt
rm -f var.txt
echo "dp_mm" > var.txt
year=`ncdump -h ${infile} | grep ReferenceTime | cut -d\" -f2 | cut -c1-4`
month=`ncdump -h ${infile} | grep ReferenceTime | cut -d\" -f2 | cut -c5-6`
day=`ncdump -h ${infile} | grep ReferenceTime | cut -d\" -f2 | cut -c7-8`
hour=`ncdump -h ${infile} | grep ReferenceTime | cut -d\" -f2 | cut -c9-10`
minute=`ncdump -h ${infile} | grep ReferenceTime | cut -d\" -f2 | cut -c12-13`


LLLON=`ncdump -h ${infile} | grep b1l3 | cut -d\" -f2 | awk '{print $1}'`
LLLAT=`ncdump -h ${infile} | grep b1l3 | cut -d\" -f2 | awk '{print $2}'`
DLON=`ncdump -h ${infile} | grep b1l4 | cut -d\" -f2 | awk '{print $1}'`
DLAT=`ncdump -h ${infile} | grep b1l4 | cut -d\" -f2 | awk '{print $2}'`

#get volcano longitude, latitude
VCLON=`ncdump -h ${infile} | grep b1l5 | cut -d\" -f2 | awk '{print $1}'`
#the cut command doesn't recognize consecutive spaces as a single delimiter,
#therefore I have to use awk to get the latitude from the second field in b1l5
VCLAT=`ncdump -h ${infile} | grep b1l5 | cut -d\" -f2 | awk '{print $2}'`
echo "VCLON="$VCLON ", VCLAT="$VCLAT

#get source parameters from netcdf file
EDur=`ncdump -v er_duration 3d_tephra_fall.nc | grep er_duration \
              | grep "=" | grep -v ":" | cut -f2 -d"=" | cut -f1 -d"," | cut -f2 -d" "` 
EPlH=`ncdump -v er_plumeheight 3d_tephra_fall.nc | grep er_plumeheight \
              | grep "=" | grep -v ":" | cut -f2 -d"=" | cut -f1 -d"," | cut -f2 -d" "`
EVol=`ncdump -v er_volume 3d_tephra_fall.nc | grep er_volume | grep "=" \
              | grep -v ":" | cut -f2 -d"=" | cut -f1 -d"," | cut -f2 -d" "`

#If volume equals minimum threshold volume, add annotation
echo "EVol=$EVol, EDur=$EDur, EPlH=$EPlH"

DLON_INT="$(echo $DLON | sed 's/\.[0-9]*//')"  #convert DLON to an integer
echo "DLON_INT=$DLON_INT"

#get start time of wind file
echo "getting windfile time"
windtime=`ncdump -h ${infile} | grep NWPStartTime | cut -c20-39`
echo "windtime=$windtime"
iwindformat=`ncdump -h ${infile} |grep b3l1 | cut -c16-20`
echo "iwindformat=${iwindformat}"
windfile="NCEP reanalysis 2.5 degree for $windtime"

echo "Processing " $volc " on " $date

## First process the netcdf file
infilell="3d_tephra_fall.nc"

if test 1 -eq 1
   then

   gsbins=`ncdump -h $infilell | grep "bn =" | cut -c6-8`      # # of grain-size bins
   zbins=`ncdump -h $infilell | grep "z =" | cut -c6-7`        # # of elevation levels
   tmax=`ncdump -h $infilell | grep "t = UNLIMITED" | cut -c22-23` # maximum time

   echo "tmax=$tmax"

   # Create the final deposit grid
   tfinal=$((tmax-1))
   echo "tfinal=$tfinal"
   echo " ${volc} : Generating final deposit grid from dep_tot_out.grd"
   #${GMTpre} grdconvert "$infilell?depothick[$tfinal]" dep_tot_out.grd
   #${GMTpre} grdmath 1.0 dep_tot_out_t${tfinal}.grd MUL = dep_tot_out.grd
   ${GMTpre} grdconvert "$infilell?depothick[$tfinal]" dep_tot_out.grd
else
  #
   t=$((tmax-1))
   lon1=`grdinfo ${infilell} -C | cut -f2`
   lon2=`grdinfo ${infilell} -C | cut -f3`
   lat1=`grdinfo ${infilell} -C | cut -f4`
   lat2=`grdinfo ${infilell} -C | cut -f5`
   # use dc (desk calculator)
   lons1=`solve.sh $lon1 - 360.0`
   lons2=`solve.sh $lon2 - 360.0`
   tvar=(depothick ashcon_max cloud_height cloud_load)

   #${GMTpre} grdreformat "${infile}?depothick[$t]" dep_tot_out.grd
   ${GMTpre} grdconvert "${infile}?depothick[$t]" dep_tot_out.grd
   ${GMTpre} grdedit dep_tot_out.grd -R${lons1}/${lons2}/${lat1}/${lat2}

fi
###############################################################################
#create .lev files of contour values
echo "0.00001  255   0 255" >  dp_0.00001.lev   #deposit (0.01 g/m2)          magenta
echo "0.00003    0   0 255" >  dp_0.00003.lev   #deposit (0.03 g/m2)          blue
echo "0.00010    0 255 255" > dp_0.00010.lev    #deposit (0.10 g/m2)          cyan
echo "0.00030    0 255   0" > dp_0.00030.lev    #deposit (0.30 g/m2)          green
echo "0.00100  255 255   0" > dp_0.00100.lev    #deposit (1.00 g/m2)          yellow
echo "0.00300  255   0   0" > dp_0.00300.lev    #deposit (3.00 g/m2)          red

#get latitude & longitude range
lonmin=$LLLON
latmin=$LLLAT
lonmax=`echo "$LLLON + $DLON" | bc -l`
latmax=`echo "$LLLAT + $DLAT" | bc -l`
echo "lonmin="$lonmin ", lonmax="$lonmax ", latmin="$latmin ", latmax="$latmax
echo "$lonmin $lonmax $latmin $latmax $VCLON $VCLAT" > map_range.txt

PROJ="-JA280/60/16c"          # Lambert azimuthal equal-area projection with origins at 280 lon, 30 lat, 12 cm width
BASE="-Bg"                    #global labeling of latitude & longitude
#AREA="-Rg"                    #global map extent
AREA="-R-180/180/0/90"        #map extent from -180 to 180 lon, 0 to 90 lat.
COAST="-G220/220/220 -W"      # RGB values for land areas (220/220/220=light gray)
DETAIL="-Dc -A1000"           #-Dc=crude-res coastlines (-Dl=lo-res, -Dh=hi-res); -A1000=features smaller than 10000 km2 not plotted

###############################################################################
if test 1 -eq 1
then

###########################################################################################
   #MAKE THE DEPOSIT MAP
      echo " ${volc} : Creating deposit map"
      #${GMTpre} gmtset ELLIPSOID Sphere
      ${GMTpre} gmtset PROJ_ELLIPSOID Sphere
  
      ${GMTpre} pscoast $AREA $PROJ $BASE $DETAIL $COAST -K > temp.ps     #Plot base map
      #${GMTpre} coast -Rg -JA280/30/12c -Bg -Dc -A1000 -Gnavy --GMT_THEME=cookbook -pdf GMT_lambert_az_hemi
      #${GMTpre} pscoast -Rg -JA280/30/12c -Bg -Dc -A1000 -Gnavy -K > temp.ps

      echo "using grdcontour"
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00001.lev  -A- -W1,255/0/255   -O -K >> temp.ps
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00003.lev  -A- -W1,0/0/255     -O -K >> temp.ps
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00010.lev -A- -W1,0/255/255   -O -K >> temp.ps
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00030.lev -A- -W1,0/255/0     -O -K >> temp.ps
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00100.lev -A- -W1,255/255/0   -O -K >> temp.ps
      ${GMTpre} grdcontour dep_tot_out.grd    $AREA $PROJ $BASE -Cdp_0.00300.lev -A- -W1,255/0/0     -O -K >> temp.ps

      echo $VCLON $VCLAT '1.0' | ${GMTpre} psxy $AREA $PROJ -St0.1i -Gblack -Wthinnest -O -K >> temp.ps  #Plot Volcano

      #echo "running ${PROGRAMDIR}/legend_placer_dp_mm"
      #${PROGRAMDIR}/legend_placer_dp_mm

      echo "adding sample locations"
      if test -r ice_core_locations.xy
      then
          #${GMTpre} psxy ice_core_locations.xy $AREA $PROJ -Sc0.05i -Gblack -Wthinnest -V -O -K >> temp.ps  
          ${GMTpre} psxy ice_core_locations.xy $AREA $PROJ -Sc0.05i -Gred -Wthinnest,red -V -O -K >> temp.ps  
      fi

   #  Convert to pdf and display
   echo "convert -rotate 90 temp.pdf -alpha off temp.gif"
   #convert temp.pdf -alpha off temp.gif
   convert -rotate 90 temp.ps -alpha off temp.gif

   #convert temp.gif deposit_thickness_gcm2.gif
   mv temp.gif deposit_thickness_gcm2.gif

   #Add thickness scale
   legendx_UL=600
   legendy_UL=100
   composite -geometry +${legendx_UL}+${legendy_UL} thickness_scale_cryptotephra.png \
         deposit_thickness_gcm2.gif  deposit_thickness_gcm2.gif

   # Clean up more temporary files
   rm -f *.grd *.lev caption.txt map_range.txt
   rm -f temp.* gmt.conf gmt.history

fi

rm -f contour*.xyz volc.txt var.txt

width=`identify deposit_thickness_gcm2.gif | cut -f3 -d' ' | cut -f1 -d'x'`
height=`identify deposit_thickness_gcm2.gif | cut -f3 -d' ' | cut -f2 -d'x'`
echo "Figure width=$width, height=$height"
echo "Eruption start time: $year $month $day $hour"
echo "plume height (km) =$EPlH"
echo "eruption duration (hrs) =$EDur"
echo "erupted volume (km3 DRE) ="$EVol
echo "all done"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "finished map_GMT_deposit.sh"
echo `date`
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
