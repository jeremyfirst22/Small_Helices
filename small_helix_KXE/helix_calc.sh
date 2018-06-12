#!/bin/bash 

anglelist=$(seq 0 15 360)  
TOP=$(PWD)
MDP=$TOP/mdp_files
MDP_BACKUPS=/Users/jeremyfirst/back_ups/mdp_files
FORCE_TOOLS=/Users/jeremyfirst/force_calc_tools

if [[ -z $1 || -z $2 ]] ; then 
    echo "USAGE: $0 < mutant (EXE, QXE, EXQ, QXQ, KXE) > "
    exit
    fi 

mutant=$1
name=$2
molec="Ac-AA${mutant:0:1}AAAA${mutant:1:1}AAAA${mutant:2:1}AAY-NH2"

## We need to source the gromacs developers libraries to use g_insert_dummy_atom 
source /usr/local/gromacs/bin/GMXRC.bash 

run_calc(){
    angle=$1 

    echo "Beginning calculations for $angle window" 

    if [ ! -d $angle/helix_calc ] ; then mkdir $angle/helix_calc ; fi 
    cd $angle/helix_calc 

    if [ ! -f $name.xvg ] ; then 
   
         check ../$molec.production.nopbc.gro ../$molec.production.nopbc.xtc 

         ## This is a very ugly way to count the number of atoms that are in the protein. Be very careful with this and double check output!!
         echo "[ protein ] " > protein.ndx
         grep -v SOL ../$molec.production.gro | grep -v Na | tail -n+3 | sed '$d' | awk '{print $3}' >> protein.ndx   
 
         gmx helix -f ../$molec.production.nopbc.xtc -n protein.ndx -s ../$molec.production.tpr

         echo "Completed calculations for window at $angle degrees."
         fi 
    check $name.xvg 
    cd $TOP
}

check(){
    for var in $@ ; do 
        if [ ! -s $var ] ; then 
            echo ; echo $var missing, exitting....
            exit 
            fi 
        done 
}

if [ ! -s $MDP/rerun.mdp ] ; then 
    if [ ! -s $MDP_BACKUPS/rerun.mdp ] ; then 
        echo "rerun.mdp not found in mdp_backups... exitting " 
        exit 
        fi 
    cp $MDP_BACKUPS/rerun.mdp $MDP/.
    fi
check $MDP/rerun.mdp 

for angle in $anglelist ; do 
    run_calc $angle 
    done 

if [ ! -d helix_calc ] ; then mkdir helix_calc ; fi

if [ ! -s helix_calc/$name.bolzmann.inp ] ; then 
    i=0 
    for angle in $anglelist ; do 
       echo "wham/$mutant.output.$i.bin   $angle/helix_calc/$name.xvg" >> helix_calc/$name.boltzmann.inp 
       ((i++)) 
       done 
    fi 
check helix_calc/$name.boltzmann.inp 
if [ ! -s helix_calc/$name.weighted.out ] ; then 
    $FORCE_TOOLS/Boltzmann_Weight -p wham/$mutant.output.prob -l helix_calc/$name.boltzmann.inp -o helix_calc/$name.weighted.out 
    fi 
check helix_calc/$name.weighted.out 
echo ; echo "Field calculation compledted for $field" ; echo 






