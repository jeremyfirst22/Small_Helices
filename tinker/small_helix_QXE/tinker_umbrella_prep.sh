#!/bin/bash

if [ -z $WORK ] ; then 
    home=/Users/jeremyfirst/
else 
    home=$WORK
    fi 

 
TINKERDIR=$home/tinker/bin/
back_ups=$home/back_ups
scripts=$home/back_ups/scripts
PARM=$home/SMALL_MOLECULES/webb_amoebapro13.prm_cnf
StartingStructures=/Users/jeremyfirst/SMALL_MOLECULES/StartingStructures
water=$home/SMALL_MOLECULES/tinker/water/em_water.xyz

usage(){
    echo "USAGE: $0 < .pdb structure file > "
    exit
    } 
 
if [ -z $1 ] ; then 
    usage 
    fi 

if [ ! -f $1 ] ; then 
    echo "$1 not found " 
    usage 
    fi 

if [ ! ${1: -4 } == ".pdb" ] ; then 
    echo "$1 is not a pdb file. " 
    usage 
    fi 

infile=$1 
infile=$(basename $infile) 
top=$(pwd) 
molec=${infile%.*} 
natoms=$(grep ATOM $infile | wc -l) 
keys=$top/keys

check(){
    for var in $@ ; do 
        if [ ! -s $var ] ; then 
            printf "Failed\n\n" ;  printf "\t $var missing, exitting...\n\n"
            exit
            fi
        done    
}

setupdir(){
   printf "Setting up directory............................." 
   if [ ! -f $infile ] ; then 
       cp $StartingStructures/$infile . 
       fi 
   if [ ! -d $top/prep ] ; then 
       mkdir $top/prep 
       fi 
   if [ ! -f prep/$molec.xyz ] ; then 
       cp $molec.xyz prep
       fi 
   if [ ! -d $top/keys ] ; then 
       mkdir $top/keys
       fi 
   if [ ! -f $top/keys/emin.key ] ; then 
       cp $back_ups/keys/emin.key keys/. 
       fi 
   if [ ! -f $top/keys/npt.key ] ; then 
       cp $back_ups/keys/npt.key keys/. 
       fi 


   check $molec.xyz prep/$molec.xyz $water keys/emin.key keys/npt.key
   printf "Success \n" 
} 

convertpdb(){ 
    printf "Generate XYZ file................................" 
    
    if [ -s $molec.xyz ] ; then 
        printf "Skipped\n" 
        return 
        fi 

    $scripts/rename_for_tinker.sh $infile $molec.tinker.pdb
    $scripts/pdbtoxyz.py $molec.tinker.pdb $PARM > $molec.xyz 
    if grep -q "Warnings" $molec.xyz ; then 
        echo ; echo 
        echo "Error: Warning found in file conversion" 
        echo "    Run $scriptsr/ pdbtoxyz.py | grep "Warning" to find warnings " 
        echo "    Likely, an atomname conversion is missing in rename_for_tinker.sh" 
        exit  
        fi 
    check $molec.xyz
    $TINKERDIR/analyze $molec.xyz $PARM emg > analyze.log 
    if grep -q "TINKER is Unable to Continue" analyze.log ; then 
        echo "Error: Analyze xyz file failed. Inspect analyze.log to trace error" 
        exit 
        fi   
    rm $molec.tinker.pdb analyze.log 
    printf "Success\n" 
}

solvate(){
   printf "Solvating structure.............................." 
   if [ -f prep/$molec.xyz_2 ] ; then 
       printf "Skipped\n" ; return ; fi 
   cd prep
   echo 20 > solv.edit 
   echo $water >> solv.edit 
   $TINKERDIR/xyzedit $molec.xyz -k $keys/emin.key < solv.edit > solv.log 
   check $molec.xyz_2
   cd ../
   printf "Success\n"  
} 

add_restraints(){
   printf "Restraining solute..............................." 
   if [[ -f keys/emin.key_restrained && -f keys/npt.key_restrained ]] ; then 
       printf "Skipped\n" ; return ; fi 
   cp keys/emin.key keys/emin.key_restrained  
   cp keys/npt.key keys/npt.key_restrained
   
   echo "" >> keys/emin.key_restrained
   echo "" >> keys/npt.key_restrained
   echo "# Restraints" >> keys/emin.key_restrained
   echo "# Restraints" >> keys/npt.key_restrained
   for i in $(seq 1 $natoms) ; do 
       echo "restrain-position $i" >> keys/emin.key_restrained 
       echo "restrain-position $i" >> keys/npt.key_restrained
       done 
   check keys/emin.key_restrained keys/npt.key_restrained 
   printf "Success\n"
}

sd_restrained(){
   printf "Steepest Descent Minimization with Restraints...."
   if [ -f prep/$molec.xyz_3 ] ; then 
       printf "Skipped\n" ; return ; fi 
   cp keys/emin.key_restrained keys/emin.key_restrained_SD
   echo "steepest-descent" >> keys/emin.key_restrained_SD
   check keys/emin.key_restrained_SD
   cd prep 
   
   $TINKERDIR/minimize $molec.xyz_2 -k $keys/emin.key_restrained_SD 1 > sd_restrained.log  
   
   check $molec.xyz_3
   cd ../
   printf "Success\n" 
}

bfgs_minimize(){
   printf "BFGS Minimization with Restraints................"    
   if [ -f prep/$molec.xyz_4 ] ; then 
       printf "Skipped\n" ; return ; fi 
   cd prep

   $TINKERDIR/minimize $molec.xyz_3 -k $keys/emin.key_restrained 0.5 > bfgs.log 

   check $molec.xyz_4
   cd ../
   printf "Success\n" 
}

NVT_simulation(){
   printf "Beginning NVT simulation........................." 
   if [ -f prep/$molec.xyz_5 ] ; then 
       printf "Skipped\n" ; return ; fi 
   cd prep

   $TINKERDIR/dynamic $molec.xyz_4 -k $keys/npt.key_restrained 80000 2.5 0.1 2 298 > nvt.log 
   cp $molec.2000 $molec.xyz_5

   check $molec.xyz_5
   cd ../
   printf "Success\n" 
}

NPT_simulation(){
   printf "Beginning NPT simulation........................."
   if [ -f prep/$molec.xyz_6 ] ; then 
         printf "Skipped\n" ; return ; fi 
   cd prep

   $TINKERDIR/dynamic $molec.xyz_5 -k $keys/npt.key_restrained 200000 2.5 0.1 4 298 1 > npt.log 
   cp $molec.7000 $molec.xyz_6

   check $molec.xyz_6
   cd ../
   printf "Success\n" 
}


printf "\n\n\t**Beginning calculation for $molec**\n\n" 
convertpdb
setupdir
solvate
add_restraints
sd_restrained
bfgs_minimize
NVT_simulation
NPT_simulation

printf "\n\n\t**Program completed Successfully**\n\n"
