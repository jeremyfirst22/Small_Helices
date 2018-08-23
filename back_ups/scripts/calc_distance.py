import numpy as np

cter = np.genfromtxt('cter.crd') 
lys= np.genfromtxt('lys.crd') 

r = []
for frame in range(50000) : 
    rx = cter[frame][4] - lys[frame][4]
    ry = cter[frame][5] - lys[frame][5]
    rz = cter[frame][6] - lys[frame][6]
    distance = pow(pow(rx,2) + pow(ry,2) + pow(rz,2) , 0.5) 
    
    r.append(distance) 

for i in range(len(r)) :
    print r[i] 

