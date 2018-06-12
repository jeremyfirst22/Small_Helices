#! /usr/bin/env python

import os
import glob
import sys
import numpy as np
import matplotlib.pyplot as plt

molec_list = ['EXE', 'KXE','QXQ', 'EXQ', 'QXE', 'EXK']
#molec_list = ['EXQ', 'EXE', 'QXE', 'QXQ']
number = len(molec_list)

files = []

for molec in molec_list :
    if molec == 'TinkerEXE' :
        files.append('tinker/small_helix_EXE/fields/weighted.out') 
    else : 
        files.append('small_helix_'+molec+'/fields/total_field.weighted.out')


curdir = os.path.abspath(os.getcwd())

data_points = []
errors = []
for molec in files :
    print "Reading %s..." %molec
    with open(molec) as f :
        data = f.read()
    splitdata = data.split()
#print data
    data_points.append(float(splitdata[4]))

    errors.append(float(splitdata[5]))


ind = range(number)


#print data
for i in range(len(data_points)):
    print molec_list[i]+"   "+str(data_points[i])+"  "+str(errors[i]) 



plt.scatter(ind, data_points) 
plt.errorbar(ind,data_points,errors)
plt.xticks( np.arange(0,number, 1.0) , molec_list)
#plt.title('Calculated Total Field at Midpoint of Nitrile Probe for 5 Peptides')
plt.xlabel('Peptide') 
plt.ylabel(r"Calculated total field ($\frac{k_B T}{e^- \AA}$)") 

plt.savefig("total_field.pdf", format='pdf') 

plt.close()





