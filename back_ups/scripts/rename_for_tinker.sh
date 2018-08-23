#!/bin/bash

if [[ -z $1 || -z $2 ]] ; then 
    echo "Usage : $0 < in .pdb file > < out .pdb file > " 
    exit 
    fi 

filename=$1 
outfile=$2 

sed -e 's/ HH31 ACE /  H1  ACE /g ; 
        s/ HH32 ACE /  H2  ACE /g ; 
        s/ HH33 ACE /  H3  ACE /g ; 
        s/ 1HB ALA / HB1 ALA /g ; 
        s/ 2HB ALA / HB2 ALA /g ; 
        s/ 3HB ALA / HB3 ALA /g ; 
        s/ H   GLN / HN  GLN /g ; 
        s/ H   GLU / HN  GLU /g ; 
        s/ H   CNF / HN  CNF /g ; 
        s/ H   TYR / HN  TYR /g ; 
        s/ H   ALA / HN  ALA /g ; 
        s/ H1  NH2 / HN1 NH2 /g ; 
        s/ H2  NH2 / HN2 NH2 /g ; 
        s/ CT  CNF / CCN CNF /g ; 
        s/ NH  CNF / NCN CNF /g ;  
' $filename > $outfile  



