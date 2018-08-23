#!/bin/bash

usage(){
    echo "Usage: $@ <Directory with trajectory to run helicity calc on > " 
    exit 
}

if [ -z $1 ] ; then 
    usage
    fi 

if [ ! -d $1 ] ; then 
    echo "$1 Directory not found " 
    usage 
    fi 

echo ; echo 

trajDir=$1 
analDir=$trajDir/ANALYSIS
helenDir=$analDir/helen
if [[ $1 == '.' ]] ; then 
     trajDir=$(basename ${PWD}) 
else 
     trajDir=$(basename $trajDir) 
     fi 


if [ ! -d $analDir ] ; then 
     mkdir $analDir
     fi
if [ ! -d $helenDir ] ; then  
     mkdir $helenDir 
     fi 

cd $helenDir 
if [ ! -s helen.inp ] ; then 
     echo "Using default helen.inp file from back_ups" 
     cp ~/back_ups/moil.inp/helen.inp . 
     fi 

check(){
     for var in $@ ; do 
          if [ ! -s $var ] ; then 
                echo ; echo $var missing, exitting...
                exit
                fi 
          done 
} 
check helen.inp ../../helix.dcd 


echo "Submitting job"
echo "#$ -N helen " > sub_helen
echo "#$ -cwd " >> sub_helen
echo "#$ -V " >> sub_helen
echo "#$ -o helen_$trajDir.out " >> sub_helen
echo "#$ -e helen_$trajDir.err " >> sub_helen
echo "#$ -l h_rt=010:00:00 " >> sub_helen
echo "#$ -pe mpich 3 " >> sub_helen
echo "#$ -q all.q " >> sub_helen

echo >> sub_helen
echo "~/moil/moil.source/exe/helen < helen.inp > helen.out" >> sub_helen
#qsub sub_helen
#echo "Job submitted..." 

nohup bash sub_helen & 
echo "nohup bash sub_helen &" 
echo "    Process running in background." 


cd -
