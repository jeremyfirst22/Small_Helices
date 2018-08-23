#!/bin/bash
if [ -z $WORK ] ; then 
    MDP_BACKUPS=/Users/jeremyfirst/back_ups/mdp_files
else  
    MDP_BACKUPS=/work/03360/jfirst/back_ups/mdp_files
    fi 

fileName=$1

MOLEC=${1%.*}
TOP=${PWD}
MDP=$TOP/mdp_files
TEMP=$TOP/temp

usage(){
    echo "USAGE: $0 <molecular stucture file {.pdb, .gro, .xyz}> <number of nodes> " 
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

checkFileType(){
   if [[ $fileName == *.pdb ]] ; then
        fileType=pdb
       
   elif [[ $fileName == *.gro ]] ; then 
        fileType=gro
        
   elif [[ $fileName == *.xyz ]] ; then 
       echo 'xyz files are not supported... exitting' ; exit

   else 
       echo 'file type not found.... exitting' ; exit 
   fi
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

runcalc(){
   setupdir
   cd $TEMP
   
   ## prep .gro file from pdb
   if [ ! -s $MOLEC.top ] ; then 
       gmx pdb2gmx -f $fileName -o $MOLEC.gro -p $MOLEC.top -water tip3p -ff amber03a 
       fi
   check $MOLEC.top $MOLEC.gro

   ##make dihedral restraint
   if [[ ! -s dihrestraint.itp && ! -s dihedral.ndx ]] ; then  
       echo No dihedral restraints found... generating now. 
       makerestraint
       fi 
   check dihrestraint.itp dihedral.ndx
    
   ## solvate, neutralize 
   if [ ! -s $MOLEC.neutral.gro ] ; then 
        solvate_structure $MOLEC.gro tip3p octahedron 5 'Na+' 'Cl-'
        fi
   check $MOLEC.neutral.gro $MOLEC.neutral.top 

   ## minimize solvent, position restraints on solute
   if [ ! -s $MOLEC.minimize.tpr ] ; then      
        gmx grompp -f $MDP/solvent_min.mdp -c $MOLEC.neutral.gro -p $MOLEC.neutral.top -o $MOLEC.minimize.tpr  
        fi
   check $MOLEC.minimize.tpr 

   if [ ! -s $MOLEC.minimize.gro ] ; then 
        gmx mdrun -s $MOLEC.minimize.tpr -deffnm $MOLEC.minimize
        fi
   check $MOLEC.minimize.gro 
    
   ## Remove pbc articfact
   if [ ! -s $MOLEC.minimize.nopbc.gro ] ; then 
        nopbc $MOLEC.minimize.gro $MOLEC.neutral.top  
        fi
   check $MOLEC.minimize.nopbc.gro 

   ## Solvent relaxation, position restraints on solute, NVT
   if [ ! -s $MOLEC.nvt_relax.tpr ] ; then      
        gmx grompp -f $MDP/solvent_nvt_relax.mdp -c $MOLEC.minimize.nopbc.gro -p $MOLEC.neutral.top -o $MOLEC.nvt_relax.tpr 
        fi
   check $MOLEC.nvt_relax.tpr 

   if [ ! -s $MOLEC.nvt_relax.gro ] ; then 
        gmx mdrun -s $MOLEC.nvt_relax.tpr -deffnm $MOLEC.nvt_relax
        fi 
   check $MOLEC.nvt_relax.gro 

   if [ ! -s $MOLEC.nvt_relax.nopbc.trr ] ; then 
        nopbc $MOLEC.nvt_relax.trr $MOLEC.neutral.top 
        fi 
   check $MOLEC.nvt_relax.nopbc.gro 

   ## Solvent relaxation, position restraints on solute, NPT
   if [ ! -s $MOLEC.npt_relax.tpr ] ; then 
       gmx grompp -f $MDP/solvent_npt_relax.mdp -c $MOLEC.nvt_relax.nopbc.gro -p $MOLEC.neutral.top -o $MOLEC.npt_relax.tpr 
       fi 
   check $MOLEC.npt_relax.tpr 

   if [ ! -s $MOLEC.npt_relax.gro ] ; then 
       gmx mdrun -s $MOLEC.npt_relax.tpr -deffnm $MOLEC.npt_relax
       fi 
   check $MOLEC.npt_relax.gro 

   if [ ! -s $MOLEC.npt_relax.nopbc.gro ] ; then 
       nopbc $MOLEC.npt_relax.trr $MOLEC.neutral.top 
       fi 
   check $MOLEC.npt_relax.nopbc.gro  

   ## Include dihedral restaints in topology 
   if [ ! -s $MOLEC.dihedral.top ] ; then 
       if grep -q "chain topologies" $MOLEC.neutral.top ; then 
            itpfile=$(grep Protein.itp $MOLEC.neutral.top | sed 's/\"//g' | awk '{print $2}')
            if ! grep -q dihrestraint.itp $itpfile ; then  
                 sed -i -e "s/Include Position restraint file/Include Position restraint file$#include \"dihrestraint.itp\"/" $itpfile 
            fi 
            cp $MOLEC.neutral.top $MOLEC.dihedral.top 
       else 
            sed "s/Include Position restraint file/Include Position restraint file$#include \"dihrestraint.itp\"/" $MOLEC.neutral.top > $MOLEC.dihedral.top 
            fi
       fi 
   check $MOLEC.dihedral.top 
  
   ## Make .trp file for production run 
   if [ ! -s $MOLEC.production.tpr ] ; then 
       gmx grompp -f $MDP/production.mdp -p $MOLEC.dihedral.top -c $MOLEC.npt_relax.nopbc.gro -o $MOLEC.production.tpr 
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

   ## remove Periodic boundary conditions
   if [ ! -s $MOLEC.production.nopbc.trr ] ; then 
       nopbc $MOLEC.production.trr $MOLEC.dihedral.top 
       fi 
   check $MOLEC.production.nopbc.trr $MOLEC.production.nopbc.gro 

   ## get dihedral angles 
   if [ ! -s $MOLEC.angaver.xvg || ! -s $MOLEC.angdist.xvg ] ; then 
       gmx angle -f $MOLEC.production.xtc -n dihedral.ndx -type dihedral -od $MOLEC.angdist.xvg -ov $MOLEC.angaver.xvg  
   fi

   ##clean
}

clean(){
   if [ ! -s back_up/ ] ; then mkdir back_up/ ; fi 
   mv \#* back_up/ 
}

makerestraint(){
    r1=100
    probe=CNF

    dihrest=dihrestraint.itp
    dihndx=dihedral.ndx

    CA=$(grep " CA " $MOLEC.gro | grep $probe | awk '{print $3}')
    CB=$(grep " CB " $MOLEC.gro | grep $probe | awk '{print $3}')
    CG=$(grep " CG " $MOLEC.gro | grep $probe | awk '{print $3}')
    CD1=$(grep " CD1 "  $MOLEC.gro | grep $probe | awk '{print $3}')

    echo "[ dihedral_restraints ]" > $dihrest
    printf ";%6s%6s%6s%6s%8s%8s%8s%12s\n" ai aj ak al func phi dphi kfac >> $dihrest
    printf " %6i%6i%6i%6i%8i%8i%8i%12i\n" $CA $CB $CG $CD1 1 $r1  0 70 >> $dihrest
    check $dihrest

    echo "[ X1 ]" > $dihndx
    echo "$CA $CB $CG $CD1" >> $dihndx
    check $dihndx
}

solvate_structure(){
   structure=$1 
   waterType=$2 
   boxtype=$3
   boxSize=$4
   cation=$5
   anion=$6
   if [[ -z $1 || -z $2 || -z $3 || -z $4 || -z $5 || -z $6 ]] ; then 
       "echo USAGE: solvate_structure < structure (.gro) > < water type (tip3p, etc) > < boxtype (octahedral, etc) > < box size (nm) > < cation (Na+) > < anion (Cl-) >"
       exit ; fi
   check $structure

 ## construct box and center protein 
   gmx editconf -f $structure -bt $boxtype -box $boxSize -o temp.centered.gro  
   check temp.centered.gro  
 ## fill box with solvent
   gmx solvate -cp temp.centered.gro -o temp.solvated.gro
   check temp.solvated.gro  
 ## build new topology with waterType as solvent
   gmx pdb2gmx -f temp.solvated.gro -water $waterType -ff amber03a -o temp.$MOLEC.solvated.gro -p temp.$MOLEC.solvated.top 
   check temp.$MOLEC.solvated.gro temp.$MOLEC.solvated.top
   
   ## remove PBC
   nopbc temp.$MOLEC.solvated.gro temp.$MOLEC.solvated.top
   check temp.$MOLEC.solvated.nopbc.gro  

   ## charge nuetralize system 
   gmx grompp -f $MDP/vac_md.mdp -p temp.$MOLEC.solvated.top -c temp.$MOLEC.solvated.nopbc.gro -o temp.genion.tpr 
   check temp.genion.tpr  
   echo SOL | gmx genion -s temp.genion.tpr -neutral -nname $anion -pname $cation -o temp.neutral.gro 
   check temp.neutral.gro 
   gmx pdb2gmx -f temp.neutral.gro -water tip3p -ff amber03a -p $MOLEC.neutral.top -o $MOLEC.neutral.gro 
   check $MOLEC.neutral.gro

## clean
   rm temp.*
}

nopbc(){
    ##Center protein and remove periodic boundary condintions. 
    if [[ ( $1 != *.gro && $1 != *.trr ) || $2 != *.top ]] ; then
         echo "USAGE: nopbc < trajectory (.gro, .trr) > < topology (.top, .tpr) >"
         exit ; fi
    
    check $1 $2     
    topol=$2 
    name=${1%.*}

## generate .tpr file if not already provided
    if [[ $2 == *.top ]] ; then
         tpr=_$name.tpr
         gmx grompp -f $MDP/vac_md.mdp -p $topol -o $tpr -c $name.gro
         check $tpr 
    else 
         tpr=$topol
         check $tpr 
    fi 

## create list of extenstions (ie if trr file passed, then trr file and gro need pbc removed)
    list='gro' 
    if [[ $1 == *.trr ]] ; then list='gro trr' ; fi 

## create nopbc file for either gro file, or both gro file and trr     
    for arg in $list ; do     
         echo System | gmx trjconv -s $tpr -f $name.$arg -o _$name.1.$arg           -pbc whole
         check _$name.1.$arg
    
         echo C-Alpha System | gmx trjconv -s $tpr -f _$name.1.$arg -o _$name.2.$arg -pbc nojump -center -ur compact -boxcenter zero
         check _$name.2.$arg

         echo C-Alpha System | gmx trjconv -s $tpr -f _$name.2.$arg -o _$name.3.$arg -pbc mol -center -ur compact -boxcenter zero
         check _$name.3.$arg

         mv _$name.3.$arg $name.nopbc.$arg
    done 

##clean 
   rm _*
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
if [ -z $1 ] ; then usage ; fi
#if [ ! -s $fileName ] ; then echo "$fileName not found... exitting" ; exit ; fi

checkFileType
checkmdp minimize.mdp vac_md.mdp solvent_min.mdp solvent_nvt_relax.mdp solvent_npt_relax.mdp  production.mdp 

runcalc

echo program completed...



