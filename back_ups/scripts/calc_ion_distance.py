import numpy as np

cter = np.genfromtxt('cter.crd') 
nao = np.genfromtxt('nao.crd') 

r = []
for frame in range(50000) : 
    mindist = 0 
    for i in range(14) : 
        rx = cter[frame][4] - nao[frame*14 + i][4]
        ry = cter[frame][5] - nao[frame*14 + i][5]
        rz = cter[frame][6] - nao[frame*14 + i][6]
        distance = pow(pow(rx,2) + pow(ry,2) + pow(rz,2) , 0.5) 
        if (mindist == 0 or distance < mindist) :
            mindist = distance 
    
    r.append(mindist) 

for i in range(len(r)) :
    print r[i] 

