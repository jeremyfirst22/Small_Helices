#!/bin/bash

anglist=$(seq 0 15 360)

for angle in $anglist ; do 
    if [ ! -d $angle ] ; then mkdir $angle ; fi 
    scp jfirst@stampede.tacc.utexas.edu:/scratch/03360/jfirst/SMALL_MOLECULES/tinker/small_helix_EXE/$angle/Ac-AAEAAAAXAAAAEAAY-NH2.angaver.dih $angle
    scp jfirst@stampede.tacc.utexas.edu:/scratch/03360/jfirst/SMALL_MOLECULES/tinker/small_helix_EXE/$angle/Ac-AAEAAAAXAAAAEAAY-NH2.$angle.fld $angle
    
    done 

