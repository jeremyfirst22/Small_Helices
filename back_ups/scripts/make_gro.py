import numpy as np
import shlex

fileName = 'ace-cys-nme.xyz'
paramName = 'atomtypes.prm'
bionames = 'bionames.prm' 

##Dict - Amber Residue names from biotypes
##
biotype2residue = {
    'Acetyl N-Terminus': 'ACE', 
    'CNC':'CNC',
    'N-MeAmide C-Terminus':'NME',
    'Alanine' : 'ALA', 
    'Cysteine' : 'CYS',
    'Water':'WATER'}


## reads data from file 
## returns a list of lists of the atom data
def read_data_file(fileName):
    atomData = []

    file = open(fileName, 'r') 
    raw_data = file.read()
    file.close()

    raw_data = raw_data.splitlines()
    for atom in range(len(raw_data)): 
        line = shlex.split(raw_data[atom])
        atomData.append(line)

    return atomData

## matches the atom type number from .xyz to atom name from .prm
## returns atomname from .prm 
def find_atom_name(atomNumber): 
    found = False
    i = 0
    name = "UNKNOWN" 
    while not found and i < len(atomData) : 
        if atomData[i][1] == atomNumber : 
            name = atomData[i][3] 
            found = True

        i += 1
    return name

## matches the atomnumber to the correct resname using a dict. 
## returns resname found from atom number in the dict
def find_resname(atomNumber): 
    found = False
    i = 0 
    resname = "UNKNOWN" 
    while not found and i < len(bioData) : 
        if bioData[i][4] == atomNumber : 
            resname = biotype2residue[bioData[i][3] ]
            found = True
        i +=1 
    
    return resname 

## Constructs a record in string format of data needed in .gro file
## returns record
def make_record(atom, resnumber):
    resnumber = str(resnumber)
    atomname = find_atom_name(data[atom][5]) 
    resname = find_resname(data[atom][5])
    number = str(data[atom][0]) 
    x = str(round(float(data[atom][2]),3)) 
    y = str(round(float(data[atom][3]),3)) 
    z = str(round(float(data[atom][4]),3)) 
    record = [resnumber, resname, atomname, number, x, y, z] 
    return record 

#def getresnumber(???????) 
#

## prints the record with proper spacing -- needs to be fixed. 
## returns nothing, printing should be caputured in terminal with > example.gro
def print_gro(record): 
    string = ''
    print (record[0].rjust(5) +  
    record[1].rjust(5) + 
    record[2].rjust(5) +  
    record[3].rjust(5) +  
    record[4].rjust(8) +  
    record[5].rjust(8) +  
    record[6].rjust(8)) 
    

###################################################################################
##### Begin program     
data = np.genfromtxt(fileName, skip_header=2, usecols=(0,1,2,3,4,5), dtype='str')
atomData = read_data_file(paramName)
bioData = read_data_file(bionames)
# reads atoms in from parameter file. atomData is required by a few functions


proteinAtoms = 0 
i = 0 
while data[i][5] != ('248' or '247'):
    proteinAtoms += 1 
    i +=1 
 
resnumber = '???'

for atom in range(proteinAtoms - 1): 
    record = make_record(atom, resnumber) 
    print_gro(record)


