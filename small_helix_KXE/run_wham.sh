#!/bin/bash

if [ -z $1 ] ; then 
    echo "USAGE: $0 < mutant (QXE, EXE, QXE, EXQ, KXE) > "
    exit 
    fi 

if [ ! -d 'wham' ] ; then mkdir wham ; fi 

mutant=$1
TOP=${PWD}
WHAM=$TOP/wham
inputfile=$WHAM/$mutant.wham.inp
outputfile=$WHAM/$mutant.output

anglelist=$(seq 0 15 360) 

molec="Ac-AA${mutant:0:1}AAAA${mutant:1:1}AAAA${mutant:2:1}AAY-NH2"

i='0'
rm $inputfile 
for angle in $anglelist ; do 
    echo $i $angle/$molec.angaver.xvg $angle 0 70 300 >> $inputfile  
    ((i++))
    done 

~/wham/wham-1.0/WHAM --f $inputfile --o $outputfile --b 1

