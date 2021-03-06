#!/bin/bash

#SBATCH -J umbrella
#SBATCH -o umbrella.o%j
#SBATCH -n 16 
#SBATCH -p normal
#SBATCH -t 48:00:00
#SBATCH -A Understanding-biomol
#SBATCH --mail-user=jeremy_first@utexas.edu
#SBATCH --mail-type=all


usage(){
    echo "USAGE: $0 <starting pdb structure> "
}

if [ -z $1 ] ; then usage ; exit ; fi 

fileName=$1
MOLEC=${fileName%.*}

if [ ! -s umbrella_prep_structure.sh ] ; then 
    cp /work/03360/jfirst/back_ups/scripts/umbrella_prep_structure.sh . 
    fi 

if [ ! -s umbrella_window.sh ] ; then 
    cp /work/03360/jfirst/back_ups/scripts/umbrella_window.sh . 
    fi 

check(){
    for var in $@ ; do
        if [ ! -s $var ] ; then
            echo ; echo $var missing, exitting... 
            exit
            fi
        done
}

check umbrella_prep_structure.sh umbrella_window.sh

module load intel/14.0.1.106 
module load impi/4.1.3.049
module load boost
module load gromacs/5.0.4

if [ ! -s $MOLEC.start.gro ] ; then 
    ./umbrella_prep_structure.sh $MOLEC.pdb 
    fi 

anglelist=$(seq 0 15 360)

for angle in $anglelist ; do 
    ./umbrella_window.sh $MOLEC.start.gro $angle
    done 

