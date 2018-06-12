#!/bin/bash

anglist=$(seq 0 15 360) 

for angle in $anglist ; do 
    numFrames=$(tail -n1 $angle/*.angaver.dih | awk '{print $1}')
    timeSampled=$(echo "scale=3 ; $numFrames * 2000 * 2 / 1000 / 1000" | bc)
    printf "$angle   $timeSampled\n" 
    done 
