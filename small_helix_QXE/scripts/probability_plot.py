import numpy as np 
import matplotlib.pyplot as plt

data = np.genfromtxt("wham/QXE.output.prob")
data2 = np.genfromtxt("wham/QXE.output.mean")
frames = len(data)

xvalues = range(-179, 181, 360/frames)

plt.plot(xvalues, data)
plt.axis('tight') 
plt.title(r"Probability Distribution of $\chi$1 angles") 
plt.xlabel(r"$\chi$1 Angle (degrees)") 
plt.ylabel('Probability') 
plt.savefig('figures/QXE_prob.pdf', format='pdf') 

plt.close()
plt.plot(xvalues, data2) 
plt.axis('tight')
plt.title("Potential of Mean Force: QXE mutant")
plt.xlabel(r"$\chi$1 Angle (degrees)")
plt.ylabel("PMF (kj/mol)") 
plt.savefig('figures/QXE_pmf.pdf',format='pdf') 


exit()


