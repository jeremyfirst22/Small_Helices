import numpy as np 
import math as m 
import matplotlib.pyplot as plt 
from matplotlib import rc_file

x=np.linspace(2234.5,2237.0,2000)
sigma = 0.28 
mu = 2235.67
y1 = 1/(sigma * m.sqrt(2*np.pi)) * np.exp(-(x-mu)**2/(2*sigma**2))
mu = 2235.82
y2 = 1/(sigma * m.sqrt(2*np.pi)) * np.exp(-(x-mu)**2/(2*sigma**2))
mu = 2235.65
y3 = 1/(sigma * m.sqrt(2*np.pi)) * np.exp(-(x-mu)**2/(2*sigma**2))

rc_file('paper_fig.rc')

plt.plot(x,y1,label="EXE")
plt.plot(x,y2,label="EXQ")
plt.plot(x,y3,label="QXE")
plt.ylabel('Absorbance')
plt.xlabel(r"Wavenumber (cm$^{-1}$)")
plt.xticks(np.linspace(2234.5, 2237.0, 6), np.linspace(2234.5, 2237.0, 6) )
#plt.xlim(2235.0,2236.3)
plt.legend(loc=1)
plt.savefig("simulated_exp.pdf",format='pdf') 
