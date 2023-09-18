      program MakeInput

!program that makes an input file for each model run

      implicit none
      integer            :: iyear,imonth,iday,ihour,iminute,isecond,nargs
      real*8             :: first_windhour,last_windhour
      integer            :: BaseYear                                       !used by HS_yyyymmddhhmm
      logical            :: useLeap                                        !used by HS_yyyymmddhhmm
      real*8             :: hour,HourNow,HoursSince1900
      real*8             :: height_now, duration_now, volume_now, volume_now_old, &
                               m_fines, mu_agg, distal_fraction
      real*8             :: sim_duration                                   !simulation duration
      integer            :: iWindFile
      character(len=13)  :: yyyymmddhhmm_since_1900, windhour_now
      character(len=13)  :: HS_yyyymmddhhmm_since
      character(len=10)  :: wind_yyyymmddhh
      character(len=6)   :: wind_yyyymm
      character(len=5)   :: RunNumber
      character(len=3)   :: gstype,month,monthlabel(12)
      character(len=78)  :: inputline
      character(len=84)  :: outfile
      integer            :: inum,im,irun                               !counter
      integer            :: intRunNumber
      real*8             :: hours_since_1900

      !some constants
      BaseYear         = 1900      !start year for yyyymmddhh
      useLeap          = .true.    !use leap years when calculating yyyymmddhh_since_1900
      sim_duration     = 240.      !simulation duration
      distal_fraction  = 0.05      !fraction of erupted volume that remains in the distal cloud

      !Particle diameters, mass fractions, and densities
      data monthlabel/'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'/

      !read run number
      nargs=iargc()
      if (nargs.ne.1) then
         write(6,*) 'error in MakeInput.  You must provide an input argument giving the run number.'
         write(6,*) 'Program stopped'
        else
         call getarg(1,RunNumber)
      end if
      read(RunNumber,*) intRunNumber             !convert to integer

      !read input file to get date and time
      open(unit=12,file='/home/lgmastin/volcanoes/Okmok/scripts/input_files/input_table.txt', &
                  action='read')
      read(12,*)                                    !skip the first three lines
      read(12,*)
      do inum=1,intRunNumber                        !Now, skip down to the appropriate run number line
         read(12,*)
      end do
      read(12,'(a78)') inputline
      read(inputline,1)  irun, iday, month, iyear, ihour, iminute, isecond, &
                         height_now, duration_now, volume_now_old, m_fines, mu_agg
1     format(i5,3x,i2,x,a3,x,i4,x,i2,x,i2,x,i2,4x,f6.2,6x,f6.2,3x,f7.4, &
           4x,f6.4,5x,f3.1)
      do im=1,12                                !Determine imonth from label
        if (month.eq.monthlabel(im)) then
           imonth=im
           exit
        end if
     end do
     hour = real(ihour)+real(iminute)/60. + real(isecond)/3600.
     HoursSince1900 = hours_since_1900(iyear,imonth,iday,hour)
     volume_now = volume_now_old*distal_fraction

     height_now = 21.0                 ! for 21-km simulations
     duration_now = 3.0

     !Write output (for testing)
!     write(6,10) intRunNumber, irun, iday, month, imonth, iyear, ihour, hour, &
!                 iminute, isecond, HoursSince1900, height_now, duration_now, &
!                 volume_now_old, volume_now, m_fines, mu_agg
!10   format( '    intRunNumber=',i5,/, &
!             '            irun=',i5,/, &
!             '            iday=',i2,/, &
!             '           month=',a3,/, &
!             '          imonth=',i2,/, &
!             '           iyear=',i4,/, &
!             '           ihour=',i4,/, &
!             '            hour=',f6.3,/, &
!             '         iminute=',i2,/, &
!             '         isecond=',i2,/, &
!             '    HoursSince1900=',f12.3,/, &
!             '      height_now=',f6.2,/, &
!             '    duration_now=',f6.2,/, &
!             '      volume_now_old=',f6.4,/, &
!             '      volume_now=',f6.4,/, &
!             '         m_fines=',f6.4,/, &
!             '          mu_agg=',f3.1)

      !write these input values to a summary file
      write(outfile,243)
243   format('/home/lgmastin/volcanoes/Okmok/RunDirs/temp_output/input_summary.txt')
      !write(6,*) 'outfile=',outfile
      open(unit=12,file=outfile,access='append')
      !open(unit=12,file='input_summary.txt',access='append')          !for testing

      !write the input to the summary log
      write(12,2)  RunNumber, iyear, imonth, iday, hour, HoursSince1900, height_now, duration_now, &
                       volume_now, m_fines, mu_agg
      write(6,2)   RunNumber, iyear, imonth, iday, hour, HoursSince1900, height_now, duration_now,  &
                       volume_now, m_fines, mu_agg
2     format(a5,5x,i4,i2.2,i2.2,f05.2,2x,f14.2,f13.1,f11.1,3f10.4)
      close(12)

      !write input file
      open(unit=10,file='ash3d_input.inp')         
      write(10,5) iyear, imonth, iday, hour, duration_now, height_now, volume_now, sim_duration
      close(10)

5     format('#The following is an input file to the model Ash3d, v.1.0',/, &
             '#Created by L.G. Mastin and R. P. Denlinger, U.S. Geological Survey, 2009.',/, &
             '#',/, &
             '#GENERAL SOURCE PARAMETERS. DO NOT DELETE ANY LINES',/, &
             '#  The first line of this block identifies the projection used and the form of',/, &
             '#  the input coordinates and is of the following format:',/, &
             '#    latlonflag projflag (variable list of projection parameters)',/, &
             '#  projflag should describe the projection used for both the windfile(s) and',/, &
             '#  the input coordinates.  Currently, these need to be the same projection.',/, &
             '#  For a particular projflag, additional values are read defining the projection.',/, &
             '#    latlonflag = 0 if the input coordinates are already projected',/, &
             '#               = 1 if the input coordinates are in lat/lon',/, &
             '#    projflag   = 1 -- polar stereographic projection',/, &
             '#           lambda0 -- longitude of projection point',/, &
             '#           phi0    -- latitude of projection point',/, &
             '#           k0      -- scale factor at projection point',/, &
             '#           radius  -- earth radius for spherical earth',/, &
             '#               = 2 -- Alberts Equal Area',/, &
             '#           lambda0 -- ',/, &
             '#           phi0    -- ',/, &
             '#           phi1    -- ',/, &
             '#           phi2    -- ',/, &
             '#               = 3 -- UTM',/, &
             '#           zone    -- zone number',/, &
             '#           north   -- flag indication norther (1) or southern (0) hemisphere',/, &
             '#               = 4 -- Lambert conformal conic',/, &
             '#           lambda0 -- longitude of origin',/, &
             '#              phi0 -- latitude of origin',/, &
             '#              phi1 -- latitude of tangency',/, &
             '#              phi2 -- latitude of second tangency',/, &
             '#            radius -- earth radius for a spherical earth',/, &
             '*******************************************************************************',/, &
             'Okmok                           #Volcano name (character*30)',/, &
             '1 4 -95. 25.0  25.0 25.0 6371.229   #Proj flags and params',/, &
             '-180.0   -88.0                 #x, y of LL corner (112W, 34N)',/, &
             '360.0    176.0                 #grid width and height (km, or deg.  if latlonflag=1)',/, &
             '-158.13      53.430            #vent location         (110.67W, 44.43N)',/, &
             '1.00   1.00                    #DX, DY of grid cells  (km, or deg.)',/, &
             '2.000                          #DZ of grid cells      (always km)',/, &
             '000.           4.0             #diffusion coefficient (m2/s), Suzuki constant',/, &
             '1                              #neruptions, number of eruptions or pulses',/, &
             '*******************************************************************************',/, &
             '#ERUPTION LINES (number = neruptions)',/, &
             '#In the following line, each line represents one eruptive pulse.  ',/, &
             '#Parameters are (1) start time (yyyy mm dd h.hh (UT)); (2) duration (hrs); ',/, &
             '#               (3) plume height;                      (4) eruped volume (km3)',/, &
             '#If the year is 0, then the model run in forecast mode where mm dd h.hh are',/, &
             '#interpreted as the time after the start of the windfile.  In this case, duration, plume',/, &
             '#height and erupted volume are replaced with ESP if the values are negative.',/, &
             '*******************************************************************************',/, &
             i4,2x,i2,2x,i2,3x,f5.2, f8.2, f8.2, f10.4,/, &
             '*******************************************************************************',/, &
             '#WIND OPTIONS',/, &
             '#Ash3d will read from either a single 1-D wind sounding, or gridded, time-',/, &
             '#dependent 3-D wind data, depending on the value of the parameter iwind.',/, &
             '#For iwind = 1, read from a 1-D wind sounding',/, &
             '#            2, read from 3D gridded ASCII files generated by the Java script',/, &
             '#               ReadNAM216forAsh3d or analogous.',/, &
             '#            3, read directly from a single NetCDF file.',/, &
             '#            4, read directly from multiple NetCDF files.',/, &
             '#The parameter iwindFormat specifies the format of the wind files, as follows:',/, &
             '# iwindFormat =  1: ASCII files (this is redundant with iwind=2',/, &
             '#                2: NAM_216pw 45km files (provided by Peter Webley)',/, &
             '#                3: NARR_221 32km (see http://dss.ucar.edu/pub/narr)',/, &
             '#                4:   unassigned',/, &
             '#                5: NAM_216 files from idd.unidata.ucar.edu',/, &
             '#                6: AWIPS_105 90km from idd.unidata.ucar.edu',/, &
             '#                7: CONUS_212 40km from idd.unidata.ucar.edu',/, &
             '#                8: NAM_218 12km',/, &
             '#                9:   unassigned',/, &
             '#               10: NAM_242 11km http://motherlode.ucar.edu/',/, &
             '#               20: NCEP GFS 0.5 degree files (http://www.nco.ncep.noaa.gov/pmb/products/gfs/)',/, &
             '#               21: ECMWF 0.25deg for Hekla intermodel comparison',/, &
             '#               22: NCEP GFS 2.5 degree files',/, &
             '#               23: NCEP DOE Reanalysis 2.5 degree files (http://dss.ucar.edu/pub/reanalysis2)',/, &
             '#                  24: NASA MERRA ',/, &
             '#                  25: NOAA/NCAR Global Reanalysis 1',/, &
             '#                    http://www.esrl.noaa.gov/psd/data/gridded/data.nmc.reanalysis.html',/, &
             '#Line 2:  iHeightHandler. Many plumes extend  higher than the maximum height ',/, &
             '#         of numerical weather prediction models. Ash3d handles this as ',/, &
             '#         determined by the parameter iHeightHandler, as follows:',/, &
             '#    iHeightHandler = 1, stop the program if the plume height exceeds mesoscale height',/, &
             '#                     2, wind velocity at levels above the highest node ',/, &
             '#                        equal that of the highest node.  Temperatures in the',/, &
             '#                        upper nodes dont change between 11 and 20 km; above',/, &
             '#                        20 km they increase by 2 C/km, as in the Standard',/, &
             '#                        atmosphere.  A warning is written to the log file.',/, &
             '*******************************************************************************',/, &
             '5  25                         #iwind, iwindFormat',/, &
             '2                             #iHeightHandler',/, &
             f4.0,'                          #Simulation time in hours',/, &
             'yes                           #stop computation when 99% of erupted mass has deposited?',/, &
             '1                              #nWindFiles, number of gridded wind files (used if iwind>1)',/, &
             '*******************************************************************************',/, &
             '#OUTPUT OPTIONS:',/, &
             '#The list below allows users to specify the output options',/, &
             '#All but the final deposit file can be written out at specified',/, &
             '#times using the following parameters:',/, &
             '#nWriteTimes   = if >0,  number of times output are to be written. The following',/, &
             '# line contains nWriteTimes numbers specifying the times of output',/, &
             '#                if =-1, it specifies that the following line gives a constant time',/, &
             '# interval in hours between write times.',/, &
             '#WriteTimes    = Hours between output (if nWritetimes=-1), or',/, &
             '#                Times (hours since start of first eruption) for each output ',/, &
             '#     (if nWriteTimes >1)',/, &
             '*******************************************************************************',/, &
             'yes     #Print out ESRI ASCII file of final deposit thickness?',/, &
             'yes     #Write out KML file of final deposit thickness?',/, &
             'no      #Print out ESRI ASCII deposit files at specified times?',/, &
             'no      #Write out KML deposit files at specified times?',/, &
             'no      #Print out ASCII files of ash-cloud concentration?',/, &
             'no      #Write out KML files of ash-cloud concentration?',/, &
             'no      #Write out ASCII files of ash-cloud height?',/, &
             'no      #Write out KML files of ash-cloud height?',/, &
             'no      #Write out ASCII files of ash-cloud load (T/km2) at specified times?',/, &
             'no      #Write out KML files of ash-cloud load (T/km2) at specified times?',/, &
             'no      #Write ASCII file of deposit arrival times?',/, &
             'yes     #Write KML file of deposit arrival times?',/, &
             'no      #write ASCII file of cloud arrival times?',/, &
             'no      #Write KML file of cloud arrival times?',/, &
             'yes     #Print out 3-D ash concentration at specified times?',/, &
             'netcdf  #format of ash concentration files   ("ascii", "binary", or "netcdf")',/, &
             '-1      #nWriteTimes',/, &
             '12      #WriteTimes (hours since eruption start)',/, &
             '*******************************************************************************',/, &
             '#WIND INPUT FILES',/, &
             '#The following block of data contains names of wind files.',/, &
             '#If reading from a 1-D wind sounding (i.e. iwind=1) then there should',/, &
             '#be only one wind file.  ',/, &
             '# If reading gridded data there should be iWinNum wind files, each having',/, &
             '# the format volcano_name_yyyymmddhh_FHhh.win',/, &
             '*******************************************************************************',/, &
             'Wind_nc/NCEP',/, &
             '*******************************************************************************',/, &
             '#AIRPORT LOCATION FILE',/, &
             '#The following lines allow the user to specify whether times of ash arrival',/, &
             '#at airports & other locations will be written out, and which file ',/, &
             '#to read for a list of airport locations.',/, &
             '#PLEASE NOTE:  Each line in the airport location file should contain the',/, &
             '#              airport latitude, longitude, projected x and y coordinates, ',/, &
             '#              and airport name.  if you are using a projected grid, ',/, &
             '#              THE X AND Y MUST BE IN THE SAME PROJECTION as the wind files.',/, &
             '#              Alternatively, if proj4 is compiled, you can have Proj4 ',/, &
             '#              find the projected coordinates by typing "yes" to the last parameter',/, &
             '*******************************************************************************',/, &
             'yes                           #Write out ash arrival times at airports to ASCII FILE?',/, &
             'no                            #Write out grain-size distribution to ASCII airports file?',/, &
             'yes                           #Write out ash arrival times to kml file?',/, &
             'ice_core_locations.txt        #Name of file containing airport locations',/, &
             'yes                           #Have Proj4 calculate projected coordinates?',/, &
             '*******************************************************************************',/, &
             '#GRAIN SIZE GROUPS',/, &
             '*******************************************************************************',/, &
             '1                            #Number of settling velocity groups',/, &
             '0.03   1.000    2000.   1.0',/, &
             '*******************************************************************************',/, &
             '#Options for writing vertical profiles',/, &
             '#The first line below gives the number of locations (nlocs) where vertical',/, &
             '# profiles are to be written.  That is followed by nlocs lines, each of which',/, &
             '#contain the location, in the same coordinate system specified above for the',/, &
             '#volcano.',/, &
             '*******************************************************************************',/, &
             '0                             #number of locations for vertical profiles (nlocs)',/, &
             '*******************************************************************************',/, &
             '#netCDF output options',/, &
             '*******************************************************************************',/, &
             '3d_tephra_fall.nc             # Name of output file',/, &
             'Asteroid run                   # Title of simulation',/, &
             'no comment                    # Comment',/, &
             'no                            # use topography?',/, &
             '1 50.                         # Topofile format, smoothing length',/, &
             'GEBCO_08.nc                   # topofile name',/, &
             '#***************************',/, &
             '#** Reset parameters',/, &
             '#***************************',/, &
             'OPTMOD=RESETPARAMS',/, &
             'DEPO_THRESH = 0.000001      # for a 0.001 micron deposit')


      end program MakeInput

!**************************************************************************************************

      function hours_since_1900(iyear,imonth,iday,hours)

      implicit none
      integer                :: iyear,imonth
      integer                :: iday, ileaphours
      real*8                 :: hours
      real*8                 :: hours_since_1900
                                   !cumulative hours in each month
      integer, dimension(12) :: monthours = (/0,744,1416,2160,2880,3624,4344,5088,5832,6552,7296,8016/)

      logical :: IsLeapYear

      ! First check input values
      if (iyear.lt.1900) then
        write(*,*)"ERROR:  year must not be less than 1900."
        stop 1
      endif
      if (imonth.lt.1.or.imonth.gt.12) then
        write(*,*)"ERROR:  month must be between 1 and 12."
        stop 1
      endif
      if (iday.lt.1) then
        write(*,*)"ERROR:  day must be greater than 0."
        stop 1
      endif
      if ((imonth.eq.1.or.&
           imonth.eq.3.or.&
           imonth.eq.5.or.&
           imonth.eq.7.or.&
           imonth.eq.8.or.&
           imonth.eq.10.or.&
           imonth.eq.12).and.iday.gt.31)then
        write(*,*)"ERROR:  day must be <= 31 for this month."
        stop 1
      endif
      if ((imonth.eq.4.or.&
           imonth.eq.6.or.&
           imonth.eq.9.or.&
           imonth.eq.11).and.iday.gt.30)then
        write(*,*)"ERROR:  day must be <= 30 for this month."
        stop 1
      endif
      if ((imonth.eq.2).and.iday.gt.29)then
        write(*,*)"ERROR:  day must be <= 29 for this month."
        stop 1
      endif

      if  ((mod(iyear,4).eq.0)     .and.                          &
           (mod(iyear,100).ne.0).or.(mod(iyear,400).eq.0))then
        IsLeapYear = .true.
      else
        IsLeapYear = .false.
      endif

      ileaphours = 24 * int((iyear-1900)/4.0)
      ! If this is a leap year, but still in Jan or Feb, removed the
      ! extra 24 hours credited above
      if (IsLeapYear.and.imonth.lt.3) ileaphours = ileaphours - 24

      hours_since_1900 = (iyear-1900)*8760.0    + & ! number of hours per normal year 
                         monthours(imonth)      + & ! hours in year at beginning of month
                         ileaphours             + & ! total leap hours since 1900
                         24.0*(iday-1)          + & ! hours in day
                         hours                      ! hour of the day

      end function hours_since_1900

!**************************************************************************************************

       function HS_yyyymmddhhmm_since(HoursSince,byear,useLeaps)
 
 !     Returns a character string yyyymmddhh.hh giving the year, month, day, and hour, given
 !     the number of hours since January 1, of baseyear.
 
       implicit none
       character (len=13)         ::  HS_yyyymmddhhmm_since, string1
       character (len=1)          ::  string0                            ! a filler character
       real(kind=8)               ::  HoursSince
       integer                    ::  byear
       logical                    ::  useLeaps
 
       integer                    ::  iyear, imonth, iday, idoy
       real(kind=8)               ::  hours
 
       integer                    ::  ihours, iminutes
 
       ! Error checking the first argument
       ! Note: this must be real*8; if it was passed as real*4, then it will be
       !        nonesense
       IF(HoursSince.lt.0.or.HoursSince.gt.1.0e9)THEN
         write(*,*)"ERROR: HoursSince variable is either negative or larger"
         write(*,*)"       than ~100,000 years."
         write(*,*)"       Double-check that it was passed as real*8"
         stop 1
       ENDIF
 
       string0 = ':'
 
       call HS_Get_YMDH(HoursSince,byear,useLeaps,iyear,imonth,iday,hours,idoy)
 
       ihours = int(hours)
       iminutes = int(60.0_8*(hours-real(ihours,kind=8)))
 
       write(string1,'(i4,3i2.2,a,i2.2)') iyear, imonth, iday, ihours, string0, iminutes          !build th
 
       HS_yyyymmddhhmm_since = string1
 
       return
       end function HS_yyyymmddhhmm_since

!**************************************************************************************************

      subroutine HS_Get_YMDH(HoursSince,byear,useLeaps,iyear,imonth,iday,hours,idoy)

      implicit none

      real(kind=8),intent(in)       :: HoursSince
      integer     ,intent(in)       :: byear
      logical     ,intent(in)       :: useLeaps
      integer     ,intent(out)      :: iyear
      integer     ,intent(out)      :: imonth
      integer     ,intent(out)      :: iday
      real(kind=8),intent(out)      :: hours
      integer     ,intent(out)      :: idoy

      integer, dimension(0:12)  :: monthours     = (/0,744,1416,2160,2880,3624,4344,5088,5832,6552,7296,8016,8760/)
      integer, dimension(0:12)  :: leapmonthours = (/0,744,1440,2184,2904,3648,4368,5112,5856,6576,7320,8040,8784/)

      integer :: HoursIn_Century
      integer :: HoursIn_This_Century
      integer :: HoursIn_Year
      integer :: HoursIn_This_Year
      integer :: HoursIn_Leap
      integer :: ileaphours
      integer :: byear_correction
      integer :: i
      integer :: icent
      integer :: BaseYear_Y0_OffsetHours_int
      real(kind=8) :: rem_hours
      real(kind=8) :: InYear_Y0_OffsettHours
      logical :: IsLeap
      logical :: IsLeapYear
      real(kind=8) :: month_start_hours,month_end_hours

      ! Error checking the first argument
      ! Note: this must be real*8; if it was passed as real*4, then it will be
      !        nonesense
      IF(HoursSince.lt.0.or.HoursSince.gt.1.0e9)THEN
        write(*,*)"ERROR: HoursSince variable is either negative or larger"
        write(*,*)"       than ~100,000 years."
        write(*,*)"       Double-check that it was passed as real*8"
        stop 1
      ENDIF

      ! div-by-four ARE leapyears -> +1
      ! div-by-100  NOT leapyears -> -1
      ! div-by-400  ARE leapyears -> +1
      !  So, every 400 years, the cycle repeats with 97 extra leap days 
      !  Otherwise, normal centuries have 24 leap days
      !  And four-year packages have 1 leap day
      IF(useLeaps)THEN
        HoursIn_Century  = 24*(365 * 100 + 24)
        HoursIn_Year     = 24*(365)
        HoursIn_Leap     = 24
      ELSE
        HoursIn_Century  = 24*(365 * 100)
        HoursIn_Year     = 24*(365)
        HoursIn_Leap     = 0
      ENDIF

      ! Get the number of hours between base year and year 0
      !  First leap hours
      ileaphours = 0
      byear_correction = 0
      IF(useLeaps)THEN
        IF(byear.ge.0)THEN
          ! clock starts at 0 so include 0 in the positive accounting
          DO i = 0,byear
            if (IsLeapYear(i)) ileaphours = ileaphours + 24
          ENDDO
          if (IsLeapYear(byear))then
            ! If the base year is itself a leapyear, remove the extra 24 hours
            ! since we will always be using Jan 1 of the base year
            byear_correction = -24
          ENDIF
        ELSE
          ! for negative years, count from year -1 to byear
          DO i = byear,-1
            if (IsLeapYear(i)) ileaphours = ileaphours + 24
          ENDDO
          if (IsLeapYear(byear))then
            ! If the base year is itself a leapyear, remove the extra 24 hours
            ! since we will always be using Jan 1 of the base year
            byear_correction = -24
          ENDIF
        ENDIF
      ELSE
        byear_correction = 0
      ENDIF
      ! Now total hours
      BaseYear_Y0_OffsetHours_int = abs(byear)*HoursIn_Year  + &
                                     ileaphours               + &
                                     byear_correction
      BaseYear_Y0_OffsetHours_int = sign(BaseYear_Y0_OffsetHours_int,byear)

      InYear_Y0_OffsettHours = real(BaseYear_Y0_OffsetHours_int,kind=8) + &
                                     HoursSince
      rem_hours = InYear_Y0_OffsettHours
      IF(InYear_Y0_OffsettHours.ge.0.0)THEN
        ! byear and HoursSince result in an iyear .ge. 0
          icent = 0
          HoursIn_This_Century = HoursIn_Century + HoursIn_Leap
          HoursIn_This_Year = HoursIn_Year + HoursIn_Leap

          ! Find which century we are in
          do while (rem_hours.ge.HoursIn_This_Century)
              ! Account for this century
            icent = icent + 1
            rem_hours = rem_hours - HoursIn_This_Century
              ! Figure out the number of hours in the next century to check
            if (mod(icent,4).eq.0) then
              HoursIn_This_Century = HoursIn_Century + HoursIn_Leap
              HoursIn_This_Year = HoursIn_Year + HoursIn_Leap
            else
              HoursIn_This_Century = HoursIn_Century
              HoursIn_This_Year = HoursIn_Year
            endif
          enddo

          ! Find which year we are in
          iyear = 0
          do while (rem_hours.ge.HoursIn_This_Year)
              ! Account for this year
            iyear = iyear + 1
            rem_hours = rem_hours - HoursIn_This_Year
              ! Figure out the number of hours in the next year to check
            if (mod(iyear,4).eq.0) then
              HoursIn_This_Year = HoursIn_Year + HoursIn_Leap
            else
              HoursIn_This_Year = HoursIn_Year
            endif
          enddo

          iyear = iyear + 100*icent
      ELSE
        ! iyear will be negative
        stop 1
      ENDIF
        ! Check if iyear is a leap year

      IF(useLeaps)THEN
        IF (IsLeapYear(iyear))THEN
           IsLeap = .true.
        ELSE
          IsLeap = .false.
        ENDIF
      ELSE
        IsLeap = .false.
      ENDIF
        ! Calculate the day-of-year
      idoy = int(rem_hours/24.0_8)+1

        ! Get the month we are in
      DO imonth=1,12
        IF(IsLeap)THEN
          month_start_hours = real(leapmonthours(imonth-1),kind=8)
          month_end_hours   = real(leapmonthours(imonth),kind=8)
        ELSE
          month_start_hours = real(monthours(imonth-1),kind=8)
          month_end_hours   = real(monthours(imonth),kind=8)
        ENDIF
        IF(rem_hours.ge.month_start_hours.and.rem_hours.lt.month_end_hours)THEN
          rem_hours = rem_hours - month_start_hours
          exit
        ENDIF
      ENDDO
        ! And the day-of month
      iday = int(rem_hours/24.0_8)+1
        ! Hours of day
      hours = rem_hours - real((iday-1)*24,kind=8)

      return

      end subroutine HS_Get_YMDH

!**************************************************************************************************

      function IsLeapYear(iyear)

      implicit none

      integer            :: iyear
      logical            :: IsLeapYear

      ! Note, this uses the proleptic Gregorian calendar with includes year 0
      ! and considers y=0 to be a leap year.

      If ((mod(iyear,4).eq.0).and.(mod(iyear,100).ne.0).or.(mod(iyear,400).eq.0)) then
        IsLeapYear = .true.
      else
        IsLeapYear = .false.
      endif

       ! If(mod(iyear,400).eq.0)THEN
       !   ! div-by-400  ARE leapyears
       !   IsLeap = .true.
       ! elseif(mod(iyear,100).eq.0)THEN
       !   ! div-by-100  NOT leapyears
       !   IsLeap = .false.
       ! elseif(mod(iyear,4).eq.0)THEN
       !   ! div-by-four ARE leapyears
       !   IsLeap = .true.
       ! else
       !   ! everything else is NOT a leapyear
       !   IsLeap = .false.
       ! endif

      return

      end function IsLeapYear

