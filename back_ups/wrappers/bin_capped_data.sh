#! /bin/bash

projDir=/Users/jeremyfirst/HELIX_CAPPED

if [ -z $1 ] ; then 
    echo "Usage: $@ < binSize (1000 is default, but default is disabled) > "
    exit 
    fi 

binSize=$1
for i in $(ls -d $projDir/0_*/[1-2]_*) ; do
    python ~/back_ups/scripts/bin_data.py $i $binSize
    done

if [ -z $binSize ] ; then 
    binSize=$((binSize*3))
    fi 
for i in $(ls -d $projDir/1_*/[1-2]_*) ; do 
    python ~/back_ups/scripts/bin_data.py $i $binSize
    done
