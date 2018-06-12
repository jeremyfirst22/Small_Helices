#! /usr/bin/env python

import os
import glob
import sys
import numpy as np
from matplotlib import rc_file
import matplotlib.pyplot as plt
import scipy.stats

molec_list = ['EXE', 'EXQ', 'QXE','QXQ'] 

files = []

for molec in molec_list :
    files.append('small_helix_'+molec+'/fields/total_field.weighted.out')


curdir = os.path.abspath(os.getcwd())

data_points = []
errors = []
for molec in files :
    # print "Reading %s..." %molec
    with open(molec) as f :
        data = f.read()
    splitdata = data.split()
#print data
    data_points.append(float(splitdata[4]))

    errors.append(float(splitdata[5]))

exp_peaks= np.genfromtxt('experimental_peaks.txt',usecols=(1) ) 
exp_error= np.genfromtxt('experimental_peaks.txt',usecols=(2))

ind = range(5)


#print data
for i in range(len(data_points)):
    print molec_list[i]+"   "+str(data_points[i])+"  "+str(errors[i]) 


##Fit line to data
z=np.polyfit(exp_peaks, data_points, 1)
print np.poly1d(z) 

slope, intercept, r_value, p_value, std_err = scipy.stats.linregress(exp_peaks, data_points)

x=np.linspace(exp_peaks.min(),exp_peaks.max())
y=intercept + x*slope
print r_value


## Begin plotting
rc_file('quals_fig.rc')


plt.scatter(exp_peaks, data_points) 
#plt.plot(x,y)
#plt.xticks(np.linspace(2235.6,2235.85,6),np.linspace(2235.6,2235.85,6))
#plt.title('Experimental Frequency v Calculated Field') 
plt.xlabel(r"Experimental Frequency (cm$^{-1}$)") 
plt.ylabel(r"Calculated Field ($\frac{k_b T}{e^- \AA}$)") 

#plt.savefig("quals_calc_v_exp_no_error.pdf",format='pdf') 

plt.xlim(2234.5,2237)
plt.xticks(np.linspace(2234.5,2237,6),np.linspace(2234.5,2237,6))
plt.ylim(1340, 1400) 
#plt.yticks(range(1340,1400,5), range(1340,1400,5)) 
plt.errorbar(exp_peaks,data_points,errors,exp_error,ecolor='b')
plt.savefig("quals_calc_v_exp.pdf", format='pdf') 

plt.close()

