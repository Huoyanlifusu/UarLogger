import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os.path

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
data = data[:1900]
ARx, ARy, ARz, NId = [], [], [], []
NIx, NIy, NIz = [], [], []

for num in range(1900):
    if data['FeaturePointNumber'][num] > 15:
        ARx.append(data['ARx'][num])
        ARy.append(data['ARy'][num])
        ARz.append(data['ARz'][num])
        NId.append(data['Distance'][num])
        NIx.append(data['NIx'][num])
        NIy.append(data['NIy'][num])
        NIz.append(data['NIz'][num])

xk = np.array([ARx[0], ARy[0], ARz[0]]).reshape(3,1)

Ak = np.identity(3)
Ck = np.concatenate((np.identity(3), np.identity(3)))
Pk = np.identity(3) * 10

std = [np.var(ARx), np.var(ARy), np.var(ARz),
       np.var(NIx), np.var(NIy), np.var(NIz)]
Wn = np.diag([1,1,1,1,1,1])
Wk = np.diag(std) + Wn
# 状态方程噪声
Q = np.identity(3) * 0.005

frames = len(ARx)

kalmanx, kalmany, kalmanz = [], [], []

for k in range(frames):
    xk_pre = np.dot(Ak, xk)
    Pk_pre = np.dot(Ak, np.dot(Pk, np.transpose(Ak))) + Q

    zk = np.concatenate((np.array([ARx[k], ARy[k], ARz[k]]).reshape(3,1), np.array([NIx[k], NIy[k], NIz[k]]).reshape(3,1)))
    yk = zk - np.dot(Ck, xk_pre)

    Sk = np.dot(Ck, np.dot(Pk_pre, np.transpose(Ck))) + Wk
    Kk = np.dot(np.dot(Pk_pre, np.transpose(Ck)), np.linalg.inv(Sk))

    xk = xk_pre + np.dot(Kk, yk)
    Pk = np.dot(np.identity(3) - np.dot(Kk, Ck), Pk_pre) 
    
    kalmanx.append(xk[0][0])
    kalmany.append(xk[1][0])
    kalmanz.append(xk[2][0])

t1 = [i for i in range(frames)]
plt.plot(t1, ARx, color = 'r', label = 'vio distance in x axis')
plt.plot(t1, NIx, color = 'b', label = 'uwb distance in x axis')
plt.plot(t1, kalmanx, color = 'g', label = 'fused distance after kalman filter')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('x axis')
plt.legend()
plt.show()