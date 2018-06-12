#!/bin/bash

#SBATCH -J umbrellaQXQ
#SBATCH -o umbrellaQXQ.oj
#SBATCH -n 16 
#SBATCH -p normal  
#SBATCH -t 48:00:00
#SBATCH -A Understanding-biomol
#SBATCH --mail-user=jeremy_first@utexas.edu
#SBATCH --mail-type=all 



./submit_umbrella.sh Ac-AAQAAAAXAAAAQAAY-NH2.pdb
