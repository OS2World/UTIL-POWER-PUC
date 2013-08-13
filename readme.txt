
 P U C  -  Designed in Year 2000 by Denny Mleinek (denny@esa-box.de)

 Version 1  

 ==============================================================================

 Parallelport:

   378h - 37Fh  =  1. parallel Interface
   278h - 27Fh  =  2. parallel Interface



  Register 379h (889)
  ~~~~~~~~~~~~~~~~~~~
  
    7  6  5  4  3  2  1  0
    |  |  |  |  |  0  0  0
    |  |  |  |  \
    |  |  |  |   \---------> -ERROR ,Pin 15, 0 = Error 
    |  |  |  \
	|  |  |   \------------> SLCT   ,Pin 13, 1 = Printer is OnLine
    |  |  \
    |  |   \---------------> PE     ,Pin 13, 1 = Printer out of paper
    |  \
    |   \------------------> -ACK   ,Pin 10, 0 = Ready for next Char (Acknowledge)
    \
     \---------------------> -BUSY  ,Pin 11, 0 = Printer is busy

                             ^ - = negative logic



  My USV/UPS
  ~~~~~~~~~~

    My USV have a 9-pin sub-d connector:


       Switch 1 /-----------------------*   Pin 1    on Ground in batterymode
           /----                 
           |    \-----------------------*   Pin 9    on Ground in StandBy
           |----                 
           | SW2\-----------------------*   Pin 8    on Ground on low power
           |
           |         LED  +-------------*   Pin 7    +5v-+12v turn usv off !
           |             \#/
           |             ---
           +--------------+-------------*   Pin 5    Ground
           |
          ---
         -----  GROUND

   
 See your Handbook or use your Multimeter to check this. Now make a cabel and
 connect your usv pins to the parallelport. 
 (batterymode, standby, lowpower, ground)

 Thats all, now run  "PUC.EXE test"  and test your USV !

