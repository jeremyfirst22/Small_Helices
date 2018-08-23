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
cd222Dir=$analDir/cd222
if [[ $1 == '.' ]] ; then 
     trajDir=$(basename ${PWD}) 
else 
     trajDir=$(basename $trajDir) 
     fi 


if [ ! -d $analDir ] ; then 
     mkdir $analDir
     fi
if [ ! -d $cd222Dir ] ; then  
     mkdir $cd222Dir 
     fi 

cd $cd222Dir 
if [ ! -s cd222.inp ] ; then 
     echo "Using default cd222.inp file from back_ups" 
     cp ~/back_ups/moil.inp/cd222.inp . 
     fi 

check(){
     for var in $@ ; do 
          if [ ! -s $var ] ; then 
                echo ; echo $var missing, exitting...
                exit
                fi 
          done 
} 
check cd222.inp ../../helix.dcd ../../helix.wcon 


echo "Submitting job"
echo "#$ -N cd222 " > sub_cd222
echo "#$ -cwd " >> sub_cd222
echo "#$ -V " >> sub_cd222
echo "#$ -o cd222_$trajDir.out " >> sub_cd222
echo "#$ -e cd222_$trajDir.err " >> sub_cd222
echo "#$ -l h_rt=010:00:00 " >> sub_cd222
echo "#$ -pe mpich 3 " >> sub_cd222
echo "#$ -q all.q " >> sub_cd222

echo >> sub_cd222
echo "~/moil/moil.source/exe/cd222 < cd222.inp > cd222.out" >> sub_cd222
#qsub sub_cd222
echo "Job submitted..." 

#nohup bash sub_cd222 & 
#echo "nohup bash sub_cd222 &" 
#echo "    Process running in background." 

~/moil/moil.source/exe/cd222 < cd222.inp > cd222.out 

cd -
