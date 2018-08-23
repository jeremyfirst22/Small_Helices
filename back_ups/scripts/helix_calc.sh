usage(){
    echo "Usage: $0 <mutant (KXE, EXE, EXQ, QXE, QXE) > " 
    exit 
}


if [ -z $1 ] ; then usage ; fi 

FORCE_TOOLS=/Users/jeremyfirst/force_calc_tools
mutant=$1
molec="Ac-AA${mutant:0:1}AAAA${mutant:1:1}AAAA${mutant:2:1}AAY-NH2"

anglist=$(seq 0 15 360) 

helix_calc(){
    if [ -z $1 ] ; then 
        echo "ooops" ; exit ; fi  
    angle=$1

    if [ ! -d $angle ] ; then 
        echo $angle not found. Skipping. Exitting 
        exit 
        fi 
    cd $angle 
    if [ ! -d helix_calc ] ; then 
        mkdir helix_calc 
        fi 
    cd helix_calc
    if [ ! -f protein.ndx ] ; then 
        echo "[ protein ] " > protein.ndx 
        grep -v SOL ../$molec.production.gro | grep -v Na | tail -n+3 | sed '$d' | awk '{print $3}' >> protein.ndx 
        fi
    if [ ! -f helicity.xvg ] ; then 
        gmx helix -f ../$molec.production.xtc -n protein.ndx -s ../$molec.production.tpr 
        fi 
    sed -i -e '/^@/d ; /^#/d ' *.xvg 
    rm -f *.xvg-e

    cd ../../
}




for angle in $anglist ; do 
    helix_calc $angle
    done 

if [ ! -d helix_calc ] ; then mkdir helix_calc ; fi 

if [ ! -s helix_calc/helix.boltzmann.inp ] ; then 
    i=0
    for angle in $anglist ; do 
        echo "wham/$mutant.output.$i.bin   $angle/helix_calc/rms-ahx.xvg" >> helix_calc/helix.boltzmann.inp 
        ((i++))
        done 
    fi 
if [ ! -s helix_calc/helix.weighted.out ] ; then 
    $FORCE_TOOLS/Boltzmann_Weight -p wham/$mutant.output.prob -l helix_calc/helix.boltzmann.inp -o helix_calc/helix.weighted.out 
    fi 
    
