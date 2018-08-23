#!/usr/bin/env python 


import numpy as np 
import sys
import shlex 


def Usage() :
     print "Usage: %s < .pdb file > < parameter file > " %(sys.argv[0]) 
     sys.exit() 
try : 
     filename = sys.argv[1] 
     with open(filename) as f : 
          data = f.readlines() 
except : 
     Usage() 
     print "Error reading in ", filename 
     sys.exit() 
try : 
     parameterFile = sys.argv[2] 
     with open(parameterFile) as f: 
          params = f.readlines()
except : 
     Usage() 
     print "Error reading in ", filename 
     sys.exit()

residues = {
    'ACE' : 'Acetyl N-Terminus', 
    'NME' : 'N-MeAmide C-Terminus' , 
    'CNF' : 'CNF', 
    'GLU' : 'Glutamic Acid', 
    'GLN' : 'Glutamine' , 
    'ALA' : 'Alanine', 
    'TYR' : 'Tyrosine' , 
    'NH2' : 'Amide C-Terminus' 
} 

def findAtomType(atom, res) :
     atomType = '0000' 
     res = residues[res] 
     found = False 
     ## Try to map atom name and resname to residue and atom number using param file 
     for i in range(len(parmData)) : 
         if atom == parmData[i][0] and res == parmData[i][1] : 
             atomType = parmData[i][2] 
             found = True 
     if not found : 
         ## Really dangerous, remove index number for multiple atoms of same name (ie, H1 -> H)
         if atom[-1] in ['1','2','3'] : 
             atom = atom[:-1]
             for i in range(len(parmData)) : 
                 if atom == parmData[i][0] and res == parmData[i][1] : 
                     atomType = parmData[i][2]
                     found = True 
     if not found : 
         print "Warning: Could not find atomType for atom %s in residue %s "%(atom, res) 
     return atomType
      

parmData = [] 
atomindex = 0 
atomData = [] 
connectData = [] 
oldToNew = {}

## Read biotype lines in param file. 
for line in params: 
    if 'biotype' in line : 
        linedata = shlex.split(line) 
        atomName = linedata[2] 
        resname = linedata[3].strip('"')  
        atomType = linedata[4]   
        parmData.append([atomName, resname, atomType]) 

## Extract atom data and bond data from pdb file 
for line in data : 
    if 'ATOM' in line or 'HETATM' in line  : 
        linedata = line.split() 
        atomindex += 1 
        oldindex = linedata[1] 
        atomname = linedata[2]
        xcoord = str("%0.6f" %(float(linedata[6]))) 
        ycoord = str("%0.6f" %(float(linedata[7]))) 
        zcoord = str("%0.6f" %(float(linedata[8])))
        resName = linedata[3] 
        atomType = findAtomType(atomname, resName) 
        oldToNew[oldindex] = atomindex
        atomData.append([atomindex, atomname, xcoord, ycoord, zcoord, atomType]) 
    if 'CONECT' in line : 
        linedata = line.split() 
        linedata.pop(0) 
        if not len(linedata) == 1 : connectData.append(linedata)      


newConnectData = [] 
for i in range(len(connectData)) : 
    newConnectData.append([]) 
    
for i in range(len(connectData)) : 
    atom = oldToNew[connectData[i][0]]
    for j in range(len(connectData[i])) : 
         newConnectData[atom-1].append(oldToNew[connectData[i][j]])
if len(newConnectData) != len(atomData) : 
    print "ERROR: connect Data of different length than atomData" 
    sys.exit() 


## print formatted xyz file 
print "%6i" %atomindex
for i in range(len(atomData)) :  
    sys.stdout.write( "%6i" %atomData[i][0]) 
    sys.stdout.write("  ")
    sys.stdout.write( "%s" %atomData[i][1].ljust(6)) 
    sys.stdout.write( "%s" %atomData[i][2].rjust(9) ) 
    sys.stdout.write( "%s" %atomData[i][3].rjust(12) )
    sys.stdout.write( "%s" %atomData[i][4].rjust(12) ) 
    
    sys.stdout.write( "%s" %atomData[i][5].rjust(6) ) 


    for j in range(len(newConnectData[i]) - 1) :
        sys.stdout.write( "%6i" %newConnectData[i][j+1] )                                      
    sys.stdout.write("\n") 

