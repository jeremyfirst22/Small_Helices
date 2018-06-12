#! /usr/bin/env python

import os
import glob
import sys
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats
from matplotlib import rc_file

#molec_list = ['EXE', 'KXE','QXQ', 'EXQ', 'QXE', 'EXK']
molec_list = ['EXQ', 'EXE', 'QXE'] 
number = 3  

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

z=np.polyfit(ind, data_points, 1)
print np.poly1d(z) 

slope, intercept, r_value, p_value, std_err = scipy.stats.linregress(ind, data_points)

x=np.linspace(0,number-1)
y=intercept + x*slope
print r_value

rc_file('paper_fig.rc')

plt.scatter(ind, data_points) 
plt.plot(x,y) 
ax=plt.gca()
ax.get_xaxis().get_major_formatter().set_useOffset(False)
#plt.errorbar(ind,data_points,errors)
plt.xticks( np.arange(0,number, 1.0) , molec_list)
#plt.title('Calculated Total Field at Midpoint of Nitrile Probe')
plt.xlabel('Peptide') 
plt.ylabel(r"Calculated total field ($\frac{k_B T}{e^- \AA}$)") 

plt.savefig("total_field_no_error.pdf", format='pdf') 

plt.close()





