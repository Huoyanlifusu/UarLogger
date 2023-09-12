import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os.path

# 剧烈晃动手机后，vio明显偏差较大时，观测方程协方差矩阵设置如下

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
ARx, ARy, ARz, NId = [], [], [], []
NIx, NIy, NIz = [], [], []

for num in range(1000):
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
Wref = [10, 10, 10, 1, 1, 1]
Wn = [np.var(NIx)/np.var(ARx), np.var(NIy)/np.var(ARy), np.var(NIz)/np.var(ARz), np.var(NIx)/np.var(ARx)/10, np.var(NIy)/np.var(ARy)/10, np.var(NIz)/np.var(ARz)/10]
Wk = np.diag(Wn)
# 状态方程噪声
Q = np.identity(3) * 0.001

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

x_gt = -0.148
arxd = [ARx[i] - x_gt for i in range(len(ARx))]
nixd = [NIx[i] - x_gt for i in range(len(NIx))]
kalmanxd = [kalmanx[i] - x_gt for i in range(len(kalmanx))]

plt.plot(t1, arxd, color = 'r', label = 'vio err in x axis')
plt.plot(t1, nixd, color = 'b', label = 'uwb err in x axis')
plt.plot(t1, kalmanxd, color = 'g', label = 'kalman err in x axis')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('x')
plt.legend()
plt.show()

y_gt = -0.195
aryd = [ARy[i] - y_gt for i in range(len(ARy))]
niyd = [NIy[i] - y_gt for i in range(len(NIy))]
kalmanyd = [kalmany[i] - y_gt for i in range(len(kalmany))]

plt.plot(t1, aryd, color = 'r', label = 'vio err in y axis')
plt.plot(t1, niyd, color = 'b', label = 'uwb err in y axis')
plt.plot(t1, kalmanyd, color = 'g', label = 'kalman err in y axis')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('y')
plt.legend()
plt.show()

z_gt = -1.601
arzd = [ARz[i] - z_gt for i in range(len(ARz))]
nizd = [NIz[i] - z_gt for i in range(len(NIz))]
kalmanzd = [kalmanz[i] - z_gt for i in range(len(kalmanz))]

plt.plot(t1, arzd, color = 'r', label = 'vio err in z axis')
plt.plot(t1, nizd, color = 'b', label = 'uwb err in z axis')
plt.plot(t1, kalmanzd, color = 'g', label = 'kalman err in z axis')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('z')
plt.legend()
plt.show()

plt.figure()
plt.title('NI & ARKit distance measurement')
labels = 'AR-x', 'NI-x'
plt.boxplot([ARx, NIx], labels = labels, showmeans = True)
plt.show()

# plt.figure()
# plt.title('NI & ARKit distance measurement')
# labels = 'AR-y', 'NI-y'
# plt.boxplot([ARy, NIy], labels = labels, showmeans = True)
# plt.show()

# plt.figure()
# plt.title('NI & ARKit distance measurement')
# labels = 'AR-z', 'NI-z'
# plt.boxplot([ARz, NIz], labels = labels, showmeans = True)
# plt.show()