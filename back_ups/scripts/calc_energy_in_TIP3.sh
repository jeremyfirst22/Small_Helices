#!/bin/bash

MOLEC=$1
NNODES=$2

usage(){
    echo "USAGE: $0 <molecule .gro file> <number of nodes> " 
    exit
}

TOP=${PWD}
TEMP=$TOP/temp
MDP=$TOP/mdp_files

export GMXDATA=$WORK/GMXFF:$GMXDATA

check(){
    for var in $@ ; do 
        if [ ! -s $var ] ; then 
            echo ; echo "$var missing, exiting... "
            exit 
            fi
        done 
}

runcalc(){
     ## copy amber03 force field to working directory if on stampede
     ## $WORK should only be defined on stampede. 
     if [ ! -z $WORK  ] ; then 
         cp -r $WORK/GMXFF/amber03a.ff/ . 
         cp $WORK/GMXFF/*.dat . 
     fi 

     # center molecule and create 5 nm truncated octaheron box
     check molecule.gro 
     gmx editconf -f molecule.gro -bt octahedron -box 5 -o molecule.centered.gro
     check molecule.centered.gro 

     # fill box with solvent
     gmx solvate -cp molecule.centered.gro -o molecule.solvated.gro 
     check molecule.solvated.gro

     # create topology file 
     echo 1 | gmx pdb2gmx -water tip3p -f molecule.solvated.gro -p solvated.top 
     check solvated.top 

     # check STEEP parameters
     gmx grompp -f $MDP/minimize.mdp -po minimize.mdp.out -c molecule.solvated.gro -p solvated.top -o minimize.tpr
     check minimize.tpr
     
     # STEEP 
     gmx mdrun -s minimize.tpr -c molecule.minimized.gro -e ener.minimize.edr -g md.minimize.log -o traj.minimize.trr
     check molecule.minimized.gro
     
     # check MD parameters
     gmx grompp -f $MDP/relax.mdp -po relax.mdout.mdp -c molecule.minimized.gro -p solvated.top -o npt_relax.tpr 
     check npt_relax.tpr
       
     # NPT MD simulation  
     gmx mdrun -s npt_relax.tpr -c relaxed_structure.gro -e ener.relax.edr -g md.relax.log -o traj.relax.trr
     check relaxed_structure.gro
     
     # use last frame and recalculate energetics 
     gmx mdrun -rerun relaxed_structure.gro -s npt_relax.tpr -e ener.rerun.edr -g md.rerun.log -o traj.rerun.trr
}



#### Begin Program


if [ -z $1 ] ; then usage ; fi
if [ ! -s $MOLEC ] ; then echo "$MOLEC file does not exist" ; exit ; fi

if [ ! -d $MDP ] ; then echo "MDP FILES NOT FOUND... EXITING" ; exit ; fi

##Create working directory temp
if [ ! -d $TEMP ] ; then mkdir $TEMP ; fi
##Move original file into temp
cp $1 $TEMP/molecule.gro
## Go to temp and run gromacs calculations
cd $TEMP
runcalc
## Move the final structure and rerun energies to the original directory 
echo "CALCULATION OVER" 
echo "     Copying final structure to $MOLEC.relaxed.gro"
echo "     mdrun -rerun log with energies copied to $MOLEC.rerun.log"
cp $TEMP/relaxed_structure.gro ../${MOLEC%.*}.relaxed.gro 
cp $TEMP/md.rerun.log ../${MOLEC%.*}.rerun.log
cd ..
exit




