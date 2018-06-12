#!/bin/bash

if [ -z $1 ] ; then 
    echo "USAGE: $0 < mutant (QXE, EXE, QXE, EXQ) > "
    exit 
    fi 

mutant=$1

anglelist=$(seq 0 15 360) 


for angle in $anglelist ; do 
    if [ ! -d $angle ] ; then mkdir $angle ; fi 
    scp jfirst@stampede.tacc.utexas.edu:/work/03360/jfirst/SMALL_MOLECULES/small_helix_$mutant/$angle/*.xvg $angle/.
    done 


