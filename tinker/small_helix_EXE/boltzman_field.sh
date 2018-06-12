#!/bin/bash

anglist=$(seq 0 15 360) 

if [ ! -d fields ] ; then mkdir fields ; fi 

if [ ! -s fields/$field.boltzmann.inp ] ;then 
    i=0
    for angle in $anglist ; do 
        cat $angle/Ac-AAEAAAAXAAAAEAAY-NH2.$angle.fld | awk 'NR > 2 {print $4}' > $angle/Ac-AAEAAAAXAAAAEAAY-NH2.field.dat
        echo "wham/EXE.output.$i.bin   $angle/Ac-AAEAAAAXAAAAEAAY-NH2.field.dat" >> fields/boltzmann.inp
        ((i++)) 
        done 
    fi 



~/force_calc_tools/Boltzmann_Weight -p wham/EXE.output.prob -l fields/boltzmann.inp -o fields/weighted.out


