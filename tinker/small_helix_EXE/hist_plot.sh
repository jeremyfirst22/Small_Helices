#!/bin/bash

anglist=$(seq 0 15 360) 

for angle in $anglist ; do 
    cd $angle
    cat Ac-AAEAAAAXAAAAEAAY-NH2.angaver.dih | awk '{print $2}' > angles.dat
    /Users/jeremyfirst/Desktop/normal_distribution/tiltAngle --file angles.dat --out Ac-AAEAAAAXAAAAEAAY-NH2.angdist.dih --overwrite
    cd ../
    done 

python  umbrella_plot_hist.py

