      program reformatter

!     program that reformats output files into a format that can be read by Matlab

      implicit none
      real*8    ::  thickness(1000,1000)
      integer   ::  i,j,k,nargs,ncols,nrows
      character(len=130) :: infile, inputline
      character(len=130) :: outfile

!     test read command line arguments
      nargs=iargc()
      if (nargs.eq.2) then
         call getarg(1,infile)
         call getarg(2,outfile)
        else if (nargs.eq.0) then
         write(6,*) 'reformatter is a program that reads ESRI ASCII files written'
         write(6,*) 'out by Ash3d and reformats them into rows and columns that'
         write(6,*) 'can be read by Matlab.  To run it,'
         write(6,*) 'You need to enter two command-line arguments:'
         write(6,*) '1) an input filename'
         write(6,*) '2) an output filename.'
         stop
        else
         write(6,*) 'Error.  You need to enter two command-line arguments'
         write(6,*) 'for this program: an input filename and an output filename.'
         write(6,*) '--The first is the name of an ESRI ASCII file written by Ash3d,'
         write(6,*) '  for example, of the cloud or deposit.'
         write(6,*) '--The second is the name of an output file of the data, written'
         write(6,*) '  as rows and columns in a format that Matlab can read.'
         write(6,*) 'Program stopped.'
         stop
      end if


!     read input file
      !write(6,*) 'reformatting ', infile
      open(unit=12,file=infile)
      read(12,'(8x,i3)') ncols
      read(12,'(8x,i3)') nrows
      read(12,'(3/)')                                !skip the first six lines
      do i=1,nrows
         read(12,1) (thickness(i,j), j=1,ncols)
1        format(10f15.3)
         if (i.lt.nrows) read(12,*)                     !skip the line between rows of data
      end do
      close(12)

!     write output file
      open(unit=13,file=outfile)
      !write(6,*) 'outfile=',outfile
      do i=1,nrows
         write(13,3) (thickness(i,j), j=1,ncols)
3        format(800f12.3)
      end do
      close(13)

      !write(6,*) 'all done.'

      end program
