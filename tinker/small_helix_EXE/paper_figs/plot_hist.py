##Need to change if: 
##   naming convention changes
##   sampling windows change


import numpy as np
import matplotlib.pyplot as plt 
import os.path
from matplotlib import rc_file

molecule='Ac-AAEAAAAXAAAAEAAY-NH2'

mutant = molecule[5] + molecule[10] + molecule[15] 

data = np.genfromtxt('../wham/EXE.output.count')
data2 = np.genfromtxt('../wham/EXE.output.mean')
data3 = np.genfromtxt('../wham/EXE.output.prob')

rc_file('paper_figs.rc') 

fig, ax = plt.subplots(nrows=1, ncols=3)#figsize=(28, 6))
ax[0].plot(data)
ax[0].set_ylim([0,data.max()]) 
ax[0].set_xlim(0,360)
#ax[0].set_xlabel("Dihedral Angle (degrees)")
ax[0].set_ylabel("Number of frames") 
ax[0].text(-0.3,1.05,'a)',horizontalalignment='center',transform=ax[0].transAxes)

ax[1].plot(data2) 
#ax[1].set_ylim(0,data2.max())
ax[1].set_xlim(0,360)
#ax[1].set_xlabel("Dihedral Angle (degrees)")
ax[1].set_ylabel("PMF (kj/mol)")
ax[1].text(-0.3,1.05,'b)',horizontalalignment='center',transform=ax[1].transAxes)

ax[2].plot(data3) 
ax[2].set_ylim(0,data3.max())
ax[2].set_xlim(0,360)
#ax[2].set_xlabel("Dihedral Angle (degrees)")
ax[2].set_ylabel("Probability")
ax[2].text(-0.3,1.05,'c)',horizontalalignment='center',transform=ax[2].transAxes)

ax[1].set_xlabel("Dihedral Angle (degrees)")


plt.savefig("wham_" + mutant + "_combined.pdf", format='pdf')
plt.close()

