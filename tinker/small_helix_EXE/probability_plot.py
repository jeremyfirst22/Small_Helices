import numpy as np 
import matplotlib.pyplot as plt
#from matplotlib import rc_file

data = np.genfromtxt("wham/EXE.output.prob")
data2 = np.genfromtxt("wham/EXE.output.mean")
frames = len(data)

xvalues = range(-179, 181, 360/frames)

#rc_file('paper_figs.rc')

plt.plot(xvalues, data)
plt.axis('tight') 
plt.title(r"Probability Distribution of $\chi$1 angles") 
plt.xlabel(r"$\chi$1 Angle (degrees)") 
plt.ylabel('Probability') 
plt.savefig('figures/EXE_prob.pdf', format='pdf') 

plt.close()
plt.plot(xvalues, data2) 
plt.axis('tight')
plt.title("Potential of Mean Force: EXE mutant")
plt.xlabel(r"$\chi$1 Angle (degrees)")
plt.ylabel("PMF (kj/mol)") 
plt.savefig('figures/EXE_pmf.pdf',format='pdf') 


exit()


