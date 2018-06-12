##Need to change if: 
##   naming convention changes
##   sampling windows change


import numpy as np
import matplotlib.pyplot as plt 
import os.path
#from matplotlib import rc_file

## This block is an ugly way of finding the molecule name by searching through the file names
## A molecule name will be found if it is of the format (dir)/(molecule).*.xvg
#subdirs = os.walk('.').next()[1] ##this returns all the immediate child subdirectories
#namefound = False
#trynum = 0 
#while not (namefound or trynum >= len(subdirs)) :
#   if os.listdir(subdirs[trynum]) != [] : 
#       if os.listdir(subdirs[trynum])[0].endswith('.xvg') : 
#            i = 0 
#            while os.listdir(subdirs[trynum])[0][i] != '.' :
#                i += 1
#            molecule = os.listdir(subdirs[trynum])[0][:i] 
#            namefound = True  
#   trynum += 1
#if not namefound : 
#    print "Error: molecule name not found in any child directories. Check format of directory" 
#    exit()
molecule='Ac-AAEAAAAXAAAAEAAY-NH2'

filename = molecule + ".angdist.dih"

##This will need to change for future naming conventions
mutant = molecule[5] + molecule[10] + molecule[15] 

## Initialize an accumulator for the combined histogram
combined=[]
for i in range(-180,181) :
    combined.append([float(i),float(0)])
combined = np.array(combined) 

##Begin reading files for data
print "computing for mutant " + mutant 
for angle in range(0,361,15): ##this will need to change for different sampling windows.
    path = str(angle) + "/" + filename 
    print path 
    if os.path.isfile(path) :
       file = open(path,'r')

       ## open file, and determine how many lines are in header, close file
       headlines = 0 
       line = file.readline()
       while line.startswith("#") or line.startswith("@") :
           headlines +=1
           line = file.readline()
       file.close() 
       
       ## skip header, read data, add to plot
       data=np.genfromtxt(path, skip_header=headlines)
       plt.plot(data[:,0],data[:,1])

       for ang, value in data :
           index = int(ang + 180) 
           combined[index][1] += value 
       
    else : 
        print "WARNING: " + path + " does not exits. File skipped" 


if not os.path.exists('figures'):
    os.makedirs('figures')
    

#rc_file('paper_figs.rc')


title = "Histograms from Individual Trajectories: " + mutant + " mutant"
plt.title(title)
plt.xlabel("Dihedral Angle (degrees)")
plt.ylabel("Occurances (% per window)") 
plt.axis('tight')
plt.savefig("figures/"+ mutant + "_individual.pdf", format='pdf')

title = "Combined Histogram and Individual Trajectories: " + mutant + " mutant"
plt.title(title)
plt.plot(combined[:,0],combined[:,1])
plt.axis('tight')
plt.savefig("figures/" + mutant + "_both.pdf", format='pdf')
plt.close()

title = "Histogram of Combined Trajectories: " + mutant + " mutant" 
plt.plot(combined[:,0],combined[:,1])
plt.title(title)
plt.axis('tight')
plt.xlabel("Dihedral Angle (degrees)")
plt.ylabel("Occurances (% per window)") 
plt.savefig("figures/" + mutant + "_combined.pdf", format='pdf')
plt.close()


title = "Combined Histogram and Individual Trajectories: QXE mutant"


exit
