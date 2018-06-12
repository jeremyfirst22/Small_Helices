#!/bin/bash
if [ -z $WORK ] ; then 
    MDP_BACKUPS=/Users/jeremyfirst/back_ups/mdp_files
else  
    MDP_BACKUPS=/work/03360/jfirst/back_ups/mdp_files
    fi 

fileName=$1
WINDOW=$2 

MOLEC=${fileName%%.*}
TOP=${PWD}
MDP=$TOP/mdp_files
TEMP=$TOP/$WINDOW

usage(){
    echo "USAGE: $0 < solvated and relaxed structure file  (.gro) > < window (degrees) > " 
    exit
}

check(){
    for var in $@ ; do 
        if [ ! -s $var ] ; then 
            echo ; echo $var missing, exitting... 
            exit
            fi
        done
}

setupdir(){
   if [ ! -d $TEMP ] ; then mkdir $TEMP ; fi 
   ## This is a hack. If $WORK is defined, then we are on stampede 
   ## Also make sure $WORK is not defined on any machine that's not stampede. kthnxbye
   if [ ! -z $WORK ] ; then 
       echo You must be on stampede. 
       if [ ! -d $TEMP/amber03a.ff ] ; then 
           echo Copying GMXFF/amber03.a to temp/
           cp -r $WORK/GMXFF/amber03a.ff/ $TEMP
           cp $WORK/GMXFF/*.dat $TEMP
           fi       
       fi
    
   if [ ! -s $fileName ] ; then 
       echo $fileName not found in current directory, checking StartingStructures directory
       if [ ! -s ../StartingStructures/$fileName ] ; then 
           echo $fileName not found in StartingStructures... exitting
           exit 
       else 
           echo Copying $fileName from StartingStructures to temp/ 
           cp ../StartingStructures/$fileName $TEMP 
           fi
   else 
       cp $fileName $TEMP
       fi
}

clean(){
   if [ ! -s back_up/ ] ; then mkdir back_up/ ; fi 
   mv \#* back_up/ 
   if [ -d amber03a.ff ] ; then rm -r amber03a.ff *.dat ; fi 
}

runcalc(){
   setupdir
   cd $TEMP

   ## Add angle window to molecule name in starting structure
   if [[ $(head -n1 $MOLEC.start.gro) != "$MOLEC $WINDOW" ]] ; then 
           awk '/'$MOLEC'/{print "'$MOLEC' at '$WINDOW' degrees"; next}1' $MOLEC.start.gro > temp.start.gro 
           mv temp.start.gro $MOLEC.start.gro  
       fi

   ## generate topology file 
   if [ ! -s $MOLEC.top ] ; then 
       gmx pdb2gmx -f $MOLEC.start.gro -p $MOLEC.top -o $MOLEC.gro -water tip3p -ff amber03a
       fi
   check $MOLEC.gro $MOLEC.top 

   ##make dihedral restraint
   ## Since we over-write the file for different dihedral restraints, we instead check 
   ## to see what trajectory we will be calculating. 
   if [ ! -s $MOLEC.nvt_relax.gro ] ; then 
       ### kfac=500 at first so we can push the probe into the window quickly. 
       makerestraint $WINDOW 500 
       fi 
   check dihrestraint.itp dihedral.ndx

   ## remove position restraints on probe
   changeposrest $MOLEC.gro posre.itp 

   ## Include dihedral restaints in topology 
   if [ ! -s $MOLEC.dihedral.top ] ; then 
       if grep -q "chain topologies" $MOLEC.top ; then 
            itpfile=$(grep Protein.itp $MOLEC.neutral.top | sed 's/\"//g' | awk '{print $2}')
            if ! grep -q dihrestraint.itp $itpfile ; then  
                 awk '/Include Position restraint file/{print;print"#include \"dihrestraint.itp\" ";next}1' $itpfile
                 ##sed -i -e "s/Include Position restraint file/Include Position restraint file$#include \"dihrestraint.itp\"/" $itpfile 
            fi 
            cp $MOLEC.top $MOLEC.dihedral.top 
       else 
            awk '/Include Position restraint file/{print;print"#include \"dihrestraint.itp\" ";next}1' $MOLEC.top > $MOLEC.dihedral.top 
            fi
       fi 
   check $MOLEC.dihedral.top 

   ## NVT relaxation with kfac=1000. Moves probe into correct position
   if [ ! -s $MOLEC.nvt_relax.tpr ] ; then 
        gmx grompp -f $MDP/force_probe_nvt.mdp -p $MOLEC.dihedral.top -c $MOLEC.gro -o $MOLEC.nvt_relax.tpr 
   fi
   check $MOLEC.nvt_relax.tpr 

   if [ ! -s $MOLEC.nvt_relax.gro ] ; then 
       gmx mdrun -s $MOLEC.nvt_relax.tpr -deffnm $MOLEC.nvt_relax
   fi 
   check $MOLEC.nvt_relax.trr $MOLEC.nvt_relax.gro 
   
   ## Overwrite old dihedral restraint with a lower kfac value to allow sampling of window
   if [ ! -s $MOLEC.production.gro ] ; then 
       makerestraint $WINDOW 70
   fi 
   check dihrestraint.itp dihedral.ndx 

   ## Make .trp file for production run 
   if [ ! -s $MOLEC.production.tpr ] ; then 
       gmx grompp -f $MDP/production.mdp -p $MOLEC.dihedral.top -c $MOLEC.nvt_relax.gro -o $MOLEC.production.tpr 
       fi
   check $MOLEC.production.tpr  
 
   ## Production run
   if [ ! -s $MOLEC.production.gro ] ; then 
       if [ -s $MOLEC.production.cpt ] ; then
           gmx mdrun -s $MOLEC.production.tpr -deffnm $MOLEC.production -cpi $MOLEC.production.cpt 
       else 
           gmx mdrun -s $MOLEC.production.tpr -deffnm $MOLEC.production
           fi
       fi
   check $MOLEC.production.gro 

   ## get dihedral angles 
   if [[ ! -s $MOLEC.angaver.xvg || ! -s $MOLEC.angdist.xvg ]] ; then 
       gmx angle -f $MOLEC.production.xtc -n dihedral.ndx -type dihedral -od $MOLEC.angdist.xvg -ov $MOLEC.angaver.xvg  
       fi
   check $MOLEC.angdist.xvg $MOLEC.angaver.xvg

   ## fix periodic boundary conditions
   if [ ! -s $MOLEC.production.nopbc.xtc ] ; then 
       echo '1 0' | gmx trjconv -f $MOLEC.production.xtc -s $MOLEC.production.tpr -pbc mol -ur compact -center -o $MOLEC.production.nopbc.xtc 
       fi 
   if [ ! -s $MOLEC.production.nopbc.gro ] ; then 
       echo '1 0' | gmx trjconv -f $MOLEC.production.gro -s $MOLEC.production.tpr -pbc mol -ur compact -center -o $MOLEC.production.nopbc.gro 
       fi 
   check $MOLEC.production.nopbc.xtc $MOLEC.production.nopbc.gro 

   clean
   cd ..
}

makerestraint(){
    if [[ -z $1 || -z $2 ]] ; then 
        echo "USAGE: < window (degrees) > < kfac force constant > "
        fi 

    r1=$1
    kfac=$2
    probe='CNF'

    dihrest=dihrestraint.itp
    dihndx=dihedral.ndx

    N=$(grep " N " $MOLEC.gro | grep $probe | awk '{print $3}')
    CA=$(grep " CA " $MOLEC.gro | grep $probe | awk '{print $3}')
    CB=$(grep " CB " $MOLEC.gro | grep $probe | awk '{print $3}')
    CG=$(grep " CG " $MOLEC.gro | grep $probe | awk '{print $3}')

    echo "[ dihedral_restraints ]" > $dihrest
    printf ";%6s%6s%6s%6s%8s%8s%8s%12s\n" ai aj ak al func phi dphi kfac >> $dihrest
    printf " %6i%6i%6i%6i%8i%8i%8i%12i\n" $N $CA $CB $CG 1 $r1 0  $kfac >> $dihrest
    check $dihrest

    echo "[ X1 ]" > $dihndx
    echo "$N $CA $CB $CG" >> $dihndx
    check $dihndx
}

changeposrest(){
    if [[ -z $1 || -z $2 ]] ; then 
        echo "USAGE: changeposrest < structure file (.gro) > < posistion restraint file (posre.itp) > "
        fi 
    structure=$1 
    posrest=$2 
    probe='CNF'
     
    firstAtom=$(grep " N " $MOLEC.gro | grep $probe | awk '{print $3}')
    lastAtom=$(grep " O " $MOLEC.gro | grep $probe | awk '{print $3}') 
    if [[ $[$lastAtom-$firstAtom] != 20 ]] ; then 
        echo "Improper number of atoms found for CNF probe"
        echo exitting ; exit 
        fi
    atomList=$(seq $firstAtom 1 $lastAtom) 

    ## for each atom in the probe, replace the position restraint force constant with 0 
    for atom in $atomList ; do 
        sed -i -e '/'" $atom "'/ s/1000/   0/g' $posrest 
        done  
}

checkmdp(){
   if [ ! -d $MDP ] ; then mkdir $MDP ; fi

   for var in $@ ; do 
       if [ ! -s $MDP/$var ] ; then 
           echo $var missing, copying from $MDP_BACKUPS 
           if [ ! -s $MDP_BACKUPS/$var ] ; then 
               echo "no mdp file found in backups for $var"
               echo "exitting ...." 
               exit 
               fi
           cp $MDP_BACKUPS/$var $MDP/
           fi 
       done
}

### Begin Program 
if [[ -z $1 || -z $2 ]] ; then usage ; fi
#if [ ! -s $fileName ] ; then echo "$fileName not found... exitting" ; exit ; fi

checkmdp force_probe_nvt.mdp production.mdp  

runcalc

echo program completed...


