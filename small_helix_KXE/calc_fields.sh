#!/bin/bash 

anglelist=$(seq 0 15 360)  
TOP=$(PWD)
MDP=$TOP/mdp_files
MDP_BACKUPS=/Users/jeremyfirst/back_ups/mdp_files
FORCE_TOOLS=/Users/jeremyfirst/force_calc_tools

if [ -z $1 ] ; then 
    echo "USAGE: $0 < mutant (EXE, QXE, EXQ, QXQ, KXE) > "
    exit
    fi 

mutant=$1
molec="Ac-AA${mutant:0:1}AAAA${mutant:1:1}AAAA${mutant:2:1}AAY-NH2"

## We need to source the gromacs developers libraries to use g_insert_dummy_atom 
source /usr/local/gromacs/bin/GMXRC.bash 

run_calc(){
    angle=$1 

    echo "Beginning calculations for $angle window" 

    if [ ! -d $angle/field_calc ] ; then mkdir $angle/field_calc ; fi 
    cd $angle/field_calc 
   
    check ../$molec.production.nopbc.gro ../$molec.production.nopbc.xtc 
    
    ##We use veriosn 4.6 of Gromacs for this grompp command, because g_insert_dummy is written for version 4.6
        ## We allow for warnings, since we are generated .tpr from a gromacs 5 mdp file. We are only inserting
           ## atoms this should not matter. 
    if [ ! -s add_dummy.tpr ] ; then 
        grompp -f $MDP/production.mdp -p ../$molec.top -c ../$molec.production.nopbc.gro -o add_dummy.tpr -maxwarn 5
        fi 
    check add_dummy.tpr 

##  Inserts dummy atom at midpoint between probe. In this case, between CZ and CT of residue CNF
    CT=$(grep CNF ../$molec.production.nopbc.gro | grep CT | awk '{print $3}')
    NH=$(grep CNF ../$molec.production.nopbc.gro | grep NH | awk '{print $3}')
    if [ ! -s with_dummy.xtc ] ; then 
         $FORCE_TOOLS/g_insert_dummy_atom -s add_dummy.tpr -f ../$molec.production.nopbc.xtc -o with_dummy.xtc -a1 $CT -a2 $NH
        fi
    check with_dummy.xtc 
    ## make topology to include dummy atom 
    if [ ! -s with_dummy.gro ] ; then 
        $FORCE_TOOLS/g_insert_dummy_atom -s add_dummy.tpr -f ../$molec.production.nopbc.gro -o with_dummy.gro -a1 $CT -a2 $NH 
        fi
    check with_dummy.gro  
    if [ ! -s with_dummy.top ] ; then 
        gmx pdb2gmx -f with_dummy.gro -p with_dummy.top -water tip3p -ff amber03a
        fi 
    check with_dummy.top 

    ## Atom numbers changed when dummy atoms was inserted. need to find new atom numbers 
    CT=$(grep CNF with_dummy.gro | grep CT | awk '{print $3}')
    NH=$(grep CNF with_dummy.gro | grep NH | awk '{print $3}')
    if [ ! -s probe.ndx ] ; then 
        echo "[ probe ] " > probe.ndx 
        echo "$CT $NH" >> probe.ndx 
        fi 
    check probe.ndx 

    ## This is a very ugly way to count the number of atoms that are in the protein. Be very careful with this and double check output!!
    echo "[ protein ] " > protein.ndx
    grep -v TCHG with_dummy.gro | grep -v SOL | grep -v Na | tail -n+3 | sed '$d' | awk '{print $3}' >> protein.ndx   
 
    ## Set up topoogies for three different fields 
    ## 1. Total Field: Field due to all present atoms in system (ie none zeroed)
    if [ ! -s total_field.top ] ; then 
        cp with_dummy.top total_field.top 
        fi
    ## 2. External Field: Field due to all atoms except the C and N of the probe
    if [ ! -s external_field.top ] ; then 
        $FORCE_TOOLS/zero_charges.py with_dummy.top probe.ndx external_field.top  
        fi 
    ## 3. Solvent reaction field. All solute atoms zeroed out. Only force due to solvent 
    if [ ! -s solvent_rxn_field.top ] ; then 
        $FORCE_TOOLS/zero_charges.py with_dummy.top protein.ndx solvent_rxn_field.top 
        fi 
    check total_field.top external_field.top solvent_rxn_field.top 
 

    ## Run calculations for three different fields 
    for field in total_field external_field solvent_rxn_field ; do 
        if [ ! -s $field.xvg ] ; then 
             ## Use mdrun -rerun to calculte the force on the dummy atom at ecah fram 
             if [ ! -s $field.tpr ] ; then 
                 gmx grompp -f $MDP/rerun.mdp -p $field.top -c with_dummy.gro -o $field.tpr 
             fi 
             check $field.tpr 
             if [ ! -s $field.trr ] ; then 
                 gmx mdrun -rerun with_dummy.xtc -s $field.tpr -deffnm $field 
                 fi 
             check $field.trr 
             ## calc field at dummy atom using gmx traj
             echo 2 | gmx traj -f $field.trr -s $field.tpr -of $field.xvg -xvg none  
             rm $field.trr
        fi 
        check $field.xvg 
        ## Print coordinates of C and N of probe ; should only be done once. 
        ##    For some reason, reading coordinates from .trr file does not work well. Reading from xtc file is safer. 
        if [ ! -s positions.xvg ] ; then 
            gmx traj -f with_dummy.xtc -s $field.tpr -n probe.ndx -ox positions.xvg -xvg none 
            fi 
        check positions.xvg 

        ## Project forces along the bond vector
        if [ ! -s $field.projected.xvg ] ; then 
            $FORCE_TOOLS/get_force.py positions.xvg $field.xvg $field.projected.xvg  
            fi
        check $field.projected.xvg
    done 

    echo "Completed calculations for window at $angle degrees."


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

if [ ! -d fields ] ; then mkdir fields ; fi

for field in total_field external_field solvent_rxn_field ; do
    if [ ! -s fields/$field.bolzmann.inp ] ; then 
        i=0 
        for angle in $anglelist ; do 
            echo "wham/$mutant.output.$i.bin   $angle/field_calc/$field.projected.xvg" >> fields/$field.boltzmann.inp 
            ((i++)) 
            done 
        fi 
    check fields/$field.boltzmann.inp 
    if [ ! -s fields/$field.weighted.out ] ; then 
        $FORCE_TOOLS/Boltzmann_Weight -p wham/$mutant.output.prob -l fields/$field.boltzmann.inp -o fields/$field.weighted.out 
        fi 
    check fields/$field.weighted.out 
    echo ; echo "Field calculation compledted for $field" ; echo 
    done 






