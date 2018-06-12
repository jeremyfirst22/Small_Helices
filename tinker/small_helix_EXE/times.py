import matplotlib.pyplot as plt 
import numpy as np

data = np.genfromtxt('times.txt') 

plt.bar(data[:,0],data[:,1]) 
plt.xlim({0,360})


plt.savefig('times.pdf',format='pdf')
