#!/usr/bin/env python


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import glob
import os
import sys

def Usage():
    print "Usage: %s <Data directory> <binSize>"%(sys.argv[0])

binSize = 1000
try :
    workingdir = os.path.abspath(sys.argv[1])
    os.chdir(workingdir)
except :
    Usage()
    sys.exit()
try :
    binSize = int(sys.argv[2])
except :
    Usage()
    print "No bin size indicated, defaulting to %i"%binSize

datafiles = glob.glob('*_*ns/ANALYSIS/helen/helen.nrt')
curdir = os.path.abspath(os.getcwd())
solvent, state = curdir.split('/')[-2:]
outname = "binned_helix_%s_%s.pdf"%(solvent,state)
outname = os.path.join(curdir,outname)
solvents = { 'TERT': 'tert-butanol', 'WATER': 'water' }
chartTitle = 'Binned data from %s in %s'%(state.split('_')[-1].lower(),solvents[solvent.split('_')[-1]]) 

for filename in datafiles: 
    print "Reading %s..."%filename 
    datai = np.genfromtxt(filename)
    try : data = np.concatenate([data,datai])
    except NameError : data = datai
    print "\t Sizes: %i (%i)" %(len(datai), len(data))

frameNumber = len(data)
assert frameNumber > 0 

binNumber = frameNumber/binSize

print "Done reading data" 

y1 = data[:,4] #alpha helix
y2 = data[:,3] # 3-10 helix
y3 = data[:,2] # unfolded

y1binned =[] 
y2binned =[] 
y3binned =[] 


print frameNumber, " frames"
print binSize, " frames per bin"
print binNumber, "bins to be graphed"

for j in range(binNumber):
    sum1 = 0
    sum2 = 0
    sum3 = 0

    for i in range(binSize):
        sum1 += y1[i + j*binSize]
        sum2 += y2[i + j*binSize] 
        sum3 += y3[i + j*binSize] 

    y1binned.append(sum1/binSize)
    y2binned.append(sum2/binSize)
    y3binned.append(sum3/binSize)

y1binned = np.array(y1binned)
y2binned = np.array(y2binned)
y3binned = np.array(y3binned)

binWidth = float(binSize/1000.) 
print "binWidth is %f "%binWidth

print "Data read.... now plotting"

#plt.bar(binSize/1000.*np.arange(len(y1binned)), y1binned, width=binWidth,edgecolor='b' , color='b' , bottom=y3binned+y2binned, label= 'alpha helix')
#plt.bar(binSize/1000.*np.arange(len(y2binned)), y2binned, width=binWidth,edgecolor='g' , color='g' ,  bottom=y3binned, label= '3-10 helix')
#plt.bar(binSize/1000.*np.arange(len(y3binned)), y3binned, width=binWidth,edgecolor='r' , color='r' , label= 'unfolded')

x = np.linspace(0,binSize*binNumber/ 10,binNumber) 

#plt.plot(x,y1binned+y2binned+y3binned,color='b') 
#plt.plot(x,y2binned+y3binned,color='g') 
#plt.plot(x,y3binned,color='r') 

plt.fill_between(x/100,0,y3binned,facecolor='r',linewidth=0.0)
plt.fill_between(x/100,y3binned,y3binned+y2binned,facecolor='g',linewidth=0.0) 
plt.fill_between(x/100,y3binned+y2binned,1,facecolor='b',linewidth=0.0) 

blue = mpatches.Patch([],[],color='b',label=r"$\alpha$-helix")
green= mpatches.Patch([],[],color='g',label=r"$3_{10}$-helix")
red  = mpatches.Patch([],[],color='r',label=r"unfolded")
plt.legend(handles=[blue, green, red],loc=4)

print "Data plotted.... now labeling"

binSize/1000.*len(y1binned)
#plt.xlim(0,binSize/1000.*(0+len(y1binned)))
plt.ylim(0,1)

plt.xlabel('time (ns)')
plt.ylabel('% helical structure')
plt.title(chartTitle)

print "Plot labeled.... now saving"

plt.savefig(outname, format='pdf')
plt.close()
print "plot saved to ", outname





