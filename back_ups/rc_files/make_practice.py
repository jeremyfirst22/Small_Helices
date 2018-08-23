import numpy as np
x = np.linspace(0,100) 
y = np.sin(x) 

from matplotlib import rc_file
rc_file('practice.rc') 

import matplotlib.pyplot as plt
fig = plt.figure() 
ax = fig.add_subplot(1,1,1)  
ax.plot(x,y) 
fig.savefig('plot.pdf') 
