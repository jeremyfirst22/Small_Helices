#! /usr/bin/env python

import sys
import numpy as np
import matplotlib.pyplot as plt

molec_list = ['EXE', 'KXE','QXQ', 'EXQ', 'QXE', 'EXK']


files = []

for molec in molec_list :
    files.append('small_helix_'+molec+'/helix_calc/cd222.weighted.out')

data_points = []
errors = []
for molec in files :
    print "Reading %s..." %molec
    with open(molec) as f :
        data = f.read()
    splitdata = data.splitlines()
    splitdata = splitdata[1].split()
#print data
    data_points.append(float(splitdata[4]))

    errors.append(float(splitdata[5]))


ind = range(5)


#print ind
for i in range(len(data_points) ) : 
    print data_points[i]



plt.bar(ind, data_points, width=1, bottom=None, yerr=errors,ecolor='Red')
plt.xticks( np.arange(0.5,5.5, 1.0) , molec_list)
plt.ylabel('RMS Deviation from ideal helix') 

#plt.plot(data_points)
plt.savefig('helicity.pdf',format='pdf') 





