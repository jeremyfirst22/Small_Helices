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
hbondsDir=$analDir/hbonds
if [[ $1 == '.' ]] ; then 
     trajDir=$(basename ${PWD}) 
else 
     trajDir=$(basename $trajDir) 
     fi 


if [ ! -d $analDir ] ; then 
     mkdir $analDir
     fi
if [ ! -d $hbondsDir ] ; then  
     mkdir $hbondsDir 
     fi 

cd $hbondsDir 
if [ ! -s hbonds.inp ] ; then 
     echo "Using default hbonds.inp file from back_ups" 
     cp ~/back_ups/moil.inp/hbonds.inp . 
     fi 

check(){
     for var in $@ ; do 
          if [ ! -s $var ] ; then 
                echo ; echo $var missing, exitting...
                exit
                fi 
          done 
} 
check hbonds.inp ../../helix.dcd ../../helix.wcon 


echo "Submitting job"
echo "#$ -N hbonds " > sub_hbonds
echo "#$ -cwd " >> sub_hbonds
echo "#$ -V " >> sub_hbonds
echo "#$ -o hbonds_$trajDir.out " >> sub_hbonds
echo "#$ -e hbonds_$trajDir.err " >> sub_hbonds
echo "#$ -l h_rt=010:00:00 " >> sub_hbonds
echo "#$ -pe mpich 3 " >> sub_hbonds
echo "#$ -q all.q " >> sub_hbonds

echo >> sub_hbonds
echo "~/moil/moil.source/exe/hbonds < hbonds.inp > hbonds.out" >> sub_hbonds
#qsub sub_hbonds
#echo "Job submitted..." 

nohup bash sub_hbonds & 
echo "nohup bash sub_hbonds &" 
echo "    Process running in background." 


cd -
