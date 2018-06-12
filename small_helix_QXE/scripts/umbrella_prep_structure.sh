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
TEMP=$TOP/prep

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

clean(){
   if [ ! -s back_up/ ] ; then mkdir back_up/ ; fi 
   mv \#* back_up/ 
   if [ -d amber03a.ff ] ; then rm -r amber03a.ff *.dat ; fi 

   check $MOLEC.npt_relax.gro  
   cp $MOLEC.npt_relax.gro ../$MOLEC.start.gro 
}

runcalc(){
   setupdir
   cd $TEMP
   
   ## prep .gro file from pdb
   if [ ! -s $MOLEC.top ] ; then 
       gmx pdb2gmx -f $fileName -o $MOLEC.gro -p $MOLEC.top -water tip3p -ff amber03a 
       fi
   check $MOLEC.top $MOLEC.gro

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

   ## Solvent relaxation, position restraints on solute, NVT
   if [ ! -s $MOLEC.nvt_relax.tpr ] ; then      
        gmx grompp -f $MDP/solvent_nvt_relax.mdp -c $MOLEC.minimize.gro -p $MOLEC.neutral.top -o $MOLEC.nvt_relax.tpr 
        fi
   check $MOLEC.nvt_relax.tpr 

   if [ ! -s $MOLEC.nvt_relax.gro ] ; then 
        gmx mdrun -s $MOLEC.nvt_relax.tpr -deffnm $MOLEC.nvt_relax
        fi 
   check $MOLEC.nvt_relax.gro 

   ## Solvent relaxation, position restraints on solute, NPT
   if [ ! -s $MOLEC.npt_relax.tpr ] ; then 
       gmx grompp -f $MDP/solvent_npt_relax.mdp -c $MOLEC.nvt_relax.gro -p $MOLEC.neutral.top -o $MOLEC.npt_relax.tpr 
       fi 
   check $MOLEC.npt_relax.tpr 

   if [ ! -s $MOLEC.npt_relax.gro ] ; then 
       gmx mdrun -s $MOLEC.npt_relax.tpr -deffnm $MOLEC.npt_relax
       fi 
   check $MOLEC.npt_relax.gro 

   clean
   cd ../
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
   
   ## charge nuetralize system 
   gmx grompp -f $MDP/vac_md.mdp -p temp.$MOLEC.solvated.top -c temp.$MOLEC.solvated.gro -o temp.genion.tpr 
   check temp.genion.tpr  
   echo SOL | gmx genion -s temp.genion.tpr -neutral -nname $anion -pname $cation -o temp.neutral.gro 
   check temp.neutral.gro 
   gmx pdb2gmx -f temp.neutral.gro -water tip3p -ff amber03a -p $MOLEC.neutral.top -o $MOLEC.neutral.gro 
   check $MOLEC.neutral.gro

## clean
   rm temp.*
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



