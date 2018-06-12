import numpy as np 
import matplotlib.pyplot as plt

data = np.genfromtxt("wham/EXQ.output.prob")
data2 = np.genfromtxt("wham/EXQ.output.mean")
frames = len(data)

xvalues = range(-179, 181, 360/frames)

plt.plot(xvalues, data)
plt.axis('tight') 
plt.title(r"Probability Distribution of $\chi$1 angles") 
plt.xlabel(r"$\chi$1 Angle (degrees)") 
plt.ylabel('Probability') 
plt.savefig('figures/EXQ_prob.pdf', format='pdf') 

plt.close()
plt.plot(xvalues, data2) 
plt.axis('tight')
plt.title("Potential of Mean Force: EXQ mutant")
plt.xlabel(r"$\chi$1 Angle (degrees)")
plt.ylabel("PMF (kj/mol)") 
plt.savefig('figures/EXQ_pmf.pdf',format='pdf') 


exit()


