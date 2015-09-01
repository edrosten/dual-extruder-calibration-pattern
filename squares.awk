#!/usr/bin/gawk -f
#
# Program for making dualextruder calibration GCode.
#
# Copyright Edward Rosten 2015.
#
# Licensed under the Affero GPL
#

function retract()
{
	print "G1 E-2.2 F9000"
}

function unretract()
{
	print "G1 E2.4 F9000"
}

function absolute()
{
	print "G90 ; absolute positioning"
}

function relative()
{
	print "G91 ; relative positioning"
}

BEGIN{
	################################################################################
	#
	# Parameters you certainly need to edit
	
	#Note this is the distance needed to offset the print head by, which is the negative
	#of the extruder offset. I find it more intuitive to work with this number while calibrating.
	#Negate it before entering it into Slic3r

	ext2_off_x = -48.33
	ext2_off_y = -.2

	#Printer parameters. You need to set these
	filament_diameter=1.75
	nozzle_diameter=0.5

	#Nozzle temperatures. The defaults here are for ABS and HIPS. 
	temp0 = 235
	temp1 = 225

	#This increases/decreses the feed rate. Higher rates give better adhesion but thicker results
	#When in early stages of calibration, use a higher feed rate, otherwise layers might miss each 
	#other completely. Lower feed rates give a finer, more precise calibration pattern.
	feed_multiple=1.2

		
	################################################################################	
	#
	# Parameters you might need to edit.
	#
	
	#Bed center (this is where the test square is printed)
	cx = 130
	cy = 130
	
	#Size of the test pattern. Too big and you get warping and slower prints. 10 works well
	#for me.
	size=10

	#Number of levels to print out.
	levels = 40
	
	#Number of layers before switching extruders
	contiguous_layers=4

	#Starting layer height
	zstart = 0.2

	#Layer height
	zinc = 0.2
	
	#Parameters of the head cleaning pass before the test pattern is printed
	clean_start_x = 50
	clean_start_y = 10
	clean_len = 100
	clean_space = 1
	clean_lines=1

	################################################################################
	#
	# No parameters below this point.
	#

	feed_ratio = nozzle_diameter^2 / filament_diameter^2
	emult = feed_ratio * feed_multiple;

	################################################################################
	#
	# First set the temperatures and return control, then set the temperatures
	# and wait. This allows the nozzles to heat in parallel.
	#
	print "T0 ; select extruder 0"
	print "M104 S" temp0  " ; set temperature"
	print "T1 ; select extruder 1"
	print "M104 S" temp1  " ; set temperature"

	print "T0"
	print "M109 S" temp0  " ; set temperature and wait"
	print "T1"
	print "M109 S" temp1  " ; set temperature and wait"

	print "T0"
	print "G21 ; units are mm"
	print "G28 X0 Y0 Z0 ; home X Y"
	print "G29 ; level bed"
	print "G1 F9000 ; fast"
	print "G0 X10 Y10 Z10 ; raise head and over near to 0,0"
	print "G0 X10 Y10 Z10 ; raise head and over near to 0,0"
	
	print "G90 ; absolute positioning"
	print "M83 ; extruder in relative mode"

	print "T0 ; select extruder 0"

	
	print "T0 ; select extruder 0"
	#print "M109 S" temp0  " ; wait for temperature"
	print "T1 ; select extruder 1"
	#print "M109 S" temp1  " ; wait for set temperature"
	
	l=0;

	print "T0"
	
	#Extruder cleaning
	print "G1 X" clean_start_x " Y" clean_start_x" Z" zstart, "F9000"
	
	relative();
	
	for(ex=0; ex < 2; ex++)
	{
		print "T"ex
		for(i=0; i < clean_lines; i++)
		{
			print "; Line start"
			print "G1 X"clean_len " E" (clean_len*emult) " F500 ; forward"
			print "G1 Y"clean_space
			print "G1 X"(-clean_len) " E" (clean_len*emult) " F500 ; reverse"
			print "G1 Y"clean_space
			retract()
		}

	}
	
	absolute()
	otool=-1

	print "M106 ; Fans on"

	for(l=0; l < levels; l++)
	{
		if(int(l/contiguous_layers)%2 == 0)
		{
			xo=0
			yo=0
			tool=0
		}	
		else
		{
			xo = ext2_off_x
			yo = ext2_off_y
			tool=1
		}

		if(otool != tool)
			retract()

		print "T" tool

		if(otool != tool)
			unretract()

		otool = tool

		s = size
		zpos = zstart + zinc * l


		print  "G1", "X" xo + cx + s/2, "Y" yo + cy + s/2, "Z"zpos, " F9000"

		print  "G1", "X" xo + cx - s/2, "Y" yo + cy + s/2, "E" (emult*s/2), "F1250"
		print  "G1", "X" xo + cx - s/2, "Y" yo + cy - s/2, "E" (emult*s/2) 
		print  "G1", "X" xo + cx + s/2, "Y" yo + cy - s/2, "E" (emult*s/2)
		print  "G1", "X" xo + cx + s/2, "Y" yo + cy + s/2, "E" (emult*s/2)

	}
	
	print "; End"
	print "T0"
	retract()
	retract()
	retract()
	print "T1"
	retract()
	retract()
	retract()
	print "G1 X0 Y0 Z30 F15000"
	print "M18 ; Motors off"
	print "M106 S0 ; Fans off"

}
