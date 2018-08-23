#!/bin/bash
MDP_BACKUPS=/Users/jeremyfirst/back_ups/mdp_files

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
       echo Copying GMXFF/amber03.a to temp/
       cp -r $WORK/GMXFF/amber03a.ff/ $TEMP
       cp $WORK/GMXFF/*.dat $TEMP
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
   echo beginning calculations.......
   if [ $fileType == pdb ] ; then 
       echo 1 | pdb2gmx -f $fileName -o $MOLEC.gro -p $MOLEC.top -water tip3p 
       fi
   check $MOLEC.top

   check $MOLEC.top $MOLEC.gro $MDP/minimize.mdp 
   grompp -f $MDP/minimize.mdp -po min.mdp.out -c $MOLEC.gro -p $MOLEC.top -o minimize.tpr
   
   
   check minimize.tpr 
   mdrun -s minimize.tpr -c $MOLEC.minimized.gro -e ener.min.edr -g md.min.log -o traj.min.trr

   check $MOLEC.minimized.gro 
   grompp -f $MDP/vac_md.mdp -po vac_md.mdp.out -c $MOLEC.minimized.gro -p $MOLEC.top -o vac_md.tpr 

   check vac_md.tpr
   mdrun -s vac_md.tpr -c $MOLEC.vac_md_end.gro -e ener.vac_md.edr -g md.vac_md.log -o trac.vac_md.trr 
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
checkmdp minimize.mdp vac_md.mdp 

runcalc

echo program completed...



