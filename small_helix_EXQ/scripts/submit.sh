#!/bin/bash

#SBATCH -J umbrellaEXQ
#SBATCH -o umbrellaEXQ.oj
#SBATCH -n 16 
#SBATCH -p normal  
#SBATCH -t 48:00:00
#SBATCH -A Understanding-biomol
#SBATCH --mail-user=jeremy_first@utexas.edu
#SBATCH --mail-type=all 



./submit_umbrella.sh Ac-AAEAAAAXAAAAQAAY-NH2.pdb
