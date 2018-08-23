#!/bin/bash


if [ ! -z $WORK ] ; then 
    home=$WORK 
else 
    home=/Users/jeremyfirst
    fi 
TINKERDIR=$home/tinker/bin

if [ -z $1 ] ; then 
    echo "USAGE: $@ < molec.angle.xyz > This file should already be prepped in push directory. " 
    exit 
    fi 

infile=$1
molec=${infile%.*} 
angle=${molec#*.} 
molec=${molec%.*} 

check(){
    for arg in $@ ; do 
        if [ ! -s $var ] ; then
            printf "\t**ERROR: $arg not found. Exitting.\n\n" 
            exit 
            fi 
        done 
}

if [ ! -d $angle ] ; then 
    mkdir $angle 
    fi 
check push/$molec.$angle.xyz keys/md.key

timer(){
    rm -f $1 
    CTIME=$(date +%s) 
    dt=$((CTIME - STARTTIME))
    while [ $dt -lt $MAXTIME ] ; do 
        sleep 120 
        CTIME=$(date +%s) 
        dt=$((CTIME-$STARTTIME))
        done

    printf "\t**$dt has elapsed. Simulation will exit after next checkpoint is writting**\n\n" 
    if [ ! -e $1 ] ; then 
        touch $1 
        fi 
    return 
}


findAtomNumbers(){
    ##This is a really ugly way to search for the atom numbers for N CA CB CG in CNF probe
    CG=$(grep " CG " $infile | grep " 293 " | awk '{print $1}')
    CBline=$(grep " CB " $infile | grep " 291 ") 
    CB=$(echo $CBline | awk '{print $1}') 
    ##This line uses awk to print only last few columns (bonded atoms). 
    ## Code was taken from http://stackoverflow.com/questions/2626274/print-all-but-the-first-three-columns
    CBbonds=$(echo $CBline | awk '{for(i=7;i<NF;i++)printf "%s",$i OFS; if (NF) printf "%s",$NF; printf ORS}')
    ## Search each bonded atoms to have CB in bonded atoms. 
    for bond in $CBbonds ; do  
    if grep " $bond " $infile | grep " CA " | grep -q " $CB " ; then 
    CAline=$(grep " $bond " $infile | grep " CA " | grep " $CB ")  
    ## Extract bonded atoms from CA so we can find amide N later. 
    CAbonds=$(echo $CAline | awk '{for(i=7;i<NF;i++)printf "%s",$i OFS; if (NF) printf "%s",$NF; printf ORS}')
    CA=$(echo $CAline | awk '{print $1}') 
    fi  
    done 
    if [ -z $CA ] ; then 
    printf "FAILED\n\n\t\t Failed to find CA atom in $infile\n\n" ; exit ; fi  
    for bond in $CAbonds ; do  
    if grep " $bond " $infile | grep " N " | grep -q " $CA " ; then 
    Nit=$(grep " $bond " $infile | grep " N " | grep " $CA " | awk '{print $1}')
    fi  
    done 
    if [ -z $Nit ] ; then 
    printf "FAILED\n\n\t\t Failed to find N atom in $infile\n\n" ; exit ; fi  
}

do_md(){
    cd $angle

    MAXTIME=46
    MAXTIME=$((MAXTIME * 60 * 60 )) 
    STARTTIME=$(date +%s) 
    timer $molec.$angle.end &
    trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT 

    if [ ! -f $molec.$angle.xyz ] ; then 
        cp ../push/$molec.$angle.xyz . 
        fi 
    check $molec.$angle.xyz 

    if [ ! -f production.$angle.key ] ; then 
        force=70 ##kJ/mol/rad)^2 from Gromacs 
        force=$(echo "scale = 3 ; $force / 4.184 / 57.3 / 57.3  " | bc)  ##kcal(/mol?)/deg^2 for Tinker
        findAtomNumbers  
        cp ../keys/md.key production.$angle.key 
    
        echo "# Restraints " >> production.$angle.key 
        echo "restrain-torsion $Nit $CA $CB $CG $force $angle $angle " >> production.$angle.key      
        echo >> production.$angle.key
        fi 
    check $molec.$angle.xyz production.$angle.key 
    
    timeLength=10 ## ns
    timeStep=2    ## fs 
    writeEvery=4  ## ps 
    
    numSteps=$(echo "1000 * 1000 * $timeLength / $timeStep " | bc) 
    numWrites=$(echo "1000 * $timeLength /  $writeEvery " | bc) 
    finalFrame=$(printf %03d $numWrites) 
    
    continuemd=false
    if [ -f $molec.$angle.dyn ] ; then 
        continuemd=true 
        fi 

    existingFrames=0 
    for frame in $(seq -f %03g 0 $numWrites) ; do 
        if [ -e $molec.$angle.$frame ] ; then 
            if [ ! -e $molec.$angle.$frame\u ] ; then 
                printf "Failed\n\n\tError: Different number of coordinate and dipole frames\n\n" 
                printf "Error likely occured because the dynamic program was terminate during printing\n\n" ; exit ; fi 
            if $continuemd ; then 
                ((existingFrames++)) 
                fi 
            fi 
        done 

    initialTime=$(echo "scale = 3 ; $writeEvery * $existingFrames / 1000" | bc) ##ns 
    timeLeft=$(echo "scale=3 ; $timeLength -  $initialTime " | bc)              ## ns 
    stepsLeft=$(echo "1000 * 1000  * $timeLeft / $timeStep " | bc)              ##steps 

    if ! $continuemd ; then 
        rm -f production.$angle.log 
        printf "\n\n\t******Beginning calculation for $molec at $angle degrees******\n\n"
    else 
        echo $stepsLeft ; echo $numSteps 
        printf "\n\n\t******Resuming calculation for $molec at $angle degrees****** \n\n" 
        printf "\t\t\tCurrent simulation time: $initialTime ns \n" 
        printf "\t\t\tCurrent steps: $(( numSteps - stepsLeft)) \n"
        printf "\t\t\tCurrent frame: %03i \n\n" $existingFrames

        printf "\t\t\tSimulation time left: $timeLeft ns \n" 
        printf "\t\t\tSteps left: $stepsLeft \n" 
        printf "\t\t\tFrames left: $((finalFrame - $existingFrames))\n\n"   
        fi 

    printf "\t\t\tTarget simulation time: $timeLength ns \n" 
    printf "\t\t\tTarget steps: $numSteps \n" 
    printf "\t\t\tTarget frames: $finalFrame \n" 
    printf "\t\t\tTime step: $timeStep fs\n"
    printf "\t\t\tFrames printed every $writeEvery ps ($((writeEvery * 1000 / $timeStep )) steps) \n\n\n\n" 

    $TINKERDIR/dynamic $infile -k production.$angle.key $stepsLeft $timeStep $writeEvery 2 298 
     
    if tail production.$angle.log | grep -q "Dynamics Calculation Ending due to User Request" ; then 
        check $filenme.dyn 
        printf "\n\n\t **Simulation successfully paused at checkpoint**\n\n"
        printf "\n\n\t **Copying data from /tmp to /scratch ** \n\n" 
        exit 
    else 
        check $filename.$finalFrame
        
        rm -f *.dyn  

        trap "killall background" EXIT 
        cd ../
        return 
        fi 
}

do_md






