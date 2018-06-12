#!/bin/bash

#SBATCH -J umbrellaQXE
#SBATCH -o umbrellaQXE.oj
#SBATCH -n 16 
#SBATCH -p normal  
#SBATCH -t 48:00:00
#SBATCH -A Understanding-biomol
#SBATCH --mail-user=jeremy_first@utexas.edu
#SBATCH --mail-type=all 



./submit_umbrella.sh Ac-AAQAAAAXAAAAEAAY-NH2.pdb
