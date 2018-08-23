#!/bin/bash

usage(){
    echo "USAGE: $0 < <mole>.start.xyz structure file > < number of windows (default=24) > "
    exit 
}

if [ -z $WORK ] ; then
    home=/Users/jeremyfirst
else 
    home=/work/03360/jfirst
    fi
TINKERDIR=$home/tinker/bin

if [ -z $1 ] ; then
    usage
    fi 
if [ ! ${1: -9 } == "start.xyz" ] ; then 
    echo "$1 is not a start.xyz file" 
    usage
    fi 
infile=$1 
if [ -z $2 ] ; then 
    numWindows=24 
else 
    numWindows=$2
    fi

interval=$((360/numWindows))
anglelist=$(seq 0 $interval 360) 
molec=${infile%.*}
molec=${molec%.*}

check(){
    for var in $@ ; do 
        if [ ! -s $var ] ; then 
            printf "Failed\n\n" ; printf "\t $var missing, exitting... \n\n"
            exit 
            fi 
        done 
}

MAXTIME=46 ##Since bash can't handle decimals, MAXTIME must be whole number in hours. 
MAXTIME=$((MAXTIME * 60 * 60)) 
STARTTIME=$(date +%s) 
timer(){
    if [ -z $1 ] ; then 
        echo ; echo 
        echo "USAGE: $@ < file to create when timer is up >"  
        echo "ERROR: Timer not started. Calculation may lose data when terminated by slurm" 
        echo ; exit ; fi 
    if [ -f $1 ] ; then rm -r $1 ; fi

    CTIME=$(date +%s) 
    dt=$((CTIME-$STARTTIME)) 
    while [ $dt -lt $MAXTIME ] ; do 
        sleep 120
        CTIME=$(date +%s) 
        dt=$((CTIME-$STARTTIME)) 
        done 
    printf "TIMEOUT\n\n"
    printf "\t**$dt has elapsed. Simulation will exit after next checkpoint is written**\n\n" 
    if [ ! -e  $1 ] ; then 
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
         printf "FAILED\n\n\t\t Failed to find N atom in $infiel\n\n" ; exit ; fi  
}

pushProbe(){
    if [[ -z $1 || -z $2 ]] ; then 
        echo "USAGE: $0 < Starting structure > < angle (degrees) to push probe > "
        exit ; fi 
    start=$1  
    angle=$2

    filename=${start%.*} 
    startName=${filename#*.} 


    printf "Pushing probe to $(printf '%3s' $angle) degrees from molec.$(printf '%-5s' $startName)....."
    if [ -f push/$molec.$angle.xyz ] ; then 
        printf "........................Skipped\n" ; return ; fi
    if [ ! -d push ] ; then 
        mkdir push 
        fi 

    ## must define atom numbers before entering push
    if [[ -z $Nit || -z $CA || -z $CB || -z $CG ]] ; then 
        findAtomNumbers
        fi 
    if [[ -z $Nit || -z $CA || -z $CB || -z $CG ]] ; then
        printf "Failed\n\n\t ** Failed to define dihedral atom numbers ** \n\n" ; exit ; fi

    cd push/
    
    ## Start the timer, create filename.end when 46 hours of computation have passed. 
    timer $filename.end &
    trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

    ## Parameters for MD simulation 
    timeLength=1    ##ps 
    timeStep=2      ##fs
    writeEvery=0.01 ## ps 

    numSteps=$(echo "1000 * $timeLength / $timeStep " | bc ) ##unit conversion is out front to prevent rounding. bc scale = 0 
    numWrites=$(echo "$timeLength / $writeEvery " | bc)
    finalFrame=$(printf %03d $numWrites) 

    ## If .dyn, then we are continuing. Count printed frames to see where we left off. If not continuing, remove frames that are printed. 
    continuemd=false
    if [ -f $filename.dyn ] ; then 
        continuemd=true
        fi 

    existingFrames=0
    for frame in $(seq -f %03g 0 $numWrites) ; do 
        if [ -e $filename.$frame ] ; then 
            if [ ! -f $filename.$frame\u ] ; then 
                printf "Failed\n\n\tError: Different number of coordinate and dipole frames\n\n" 
                printf "Error likely occured becuase the dynamic program was terminated during printing\n\n" ; exit ; fi 

            if $continuemd ; then 
                ((existingFrames++))
                fi 
            fi 
        done 

    initialTime=$(echo "scale = 3 ; $writeEvery * $existingFrames" | bc) 
    timeLeft=$(echo "scale=3 ; $timeLength - $initialTime " | bc) 
    stepsLeft=$(echo " 1000 * $timeLeft / $timeStep " | bc ) 
    
    printf "$(printf '%3.3f' $timeLeft) ps to calculate..." 

    ## Print data to the log 
    if ! $continuemd ; then rm -f push.$angle.log ; fi 

    echo "Dynamics simpulation for $timeLength ps with a $timeStep fs, writing to the trajectory every $writeEvery ps. 
    Therefore, $numSteps steps will be performed and $numWrites frames will be written." >> push.$angle.log 

    echo "$existingFrames frames already found" >> push.$angle.log 
    echo "Since $existingFrames frames are already found, intitialTime is $initialTime ps" >> push.$angle.log 
    echo "There are $timeLeft ps left to simulate, which will take $stepsLeft steps" >> push.$angle.log 
    echo " The final frame will be $filename.$finalFrame" >> push.$angle.log 

    ## Generate key file with large "pushing" dihedreal restraint     
    if [ ! -f push.$angle.key ] ; then 
        force=500.0 ##kJ/(mol rad^2) from Gromacs
        force=$(echo "scale = 3 ; $force / 4.184 / 57.3 / 57.3  " | bc)  ##kcal(/mol?)/deg^2 for Tinker
        cp ../keys/md.key push.$angle.key 
        echo "# Restraints " >> push.$angle.key 
        echo "restrain-torsion $Nit $CA $CB $CG $force $angle $angle " >> push.$angle.key  
    fi       
    
    ## Flag to ensure we caputure starting file from top directory 
    if [ ! -f $start ] ; then 
        if [ -f ../$start ] ; then 
            cp ../$start . 
        else 
            printf "Failed\n\n\tError: $start not found\n\n" ; exit ; fi 
        fi 

    ## Do dynamics
    check push.$angle.key $start 
    $TINKERDIR/dynamic $start -k push.$angle.key $stepsLeft $timeStep $writeEvery 2 298 >> push.$angle.log

    ###Either end with a checkpoint or successfuly completion. 
    if tail push.$angle.log | grep -q "Dynamics Calculation Ending due to User Request" ; then
        check $filename.dyn 
        printf "\n\n\t **Simulation successfully paused at checkpoint**\n\n" 
        exit
    else 
        check $filename.$finalFrame
        cp $filename.$finalFrame $molec.$angle.xyz  
     
        ## Final check and exit 
        check $molec.$angle.xyz
        rm -f *.dyn ##forcibly remove .dyn files so that we don't accidently start from checkpoint 
        trap "killall background" EXIT 
        cd ../
        printf "Success\n" 
        return 
        fi 
}




printf "\n\n\t**Beginning Prep of $numWindows Windows for $molec**\n\n"
startStructure=$infile
for angle in $anglelist ; do 
    pushProbe $startStructure $angle 
    startStructure=$molec.$angle.xyz
done 
printf "\n\n\t**Calculations for $molec complete**\n\n" 

exit

