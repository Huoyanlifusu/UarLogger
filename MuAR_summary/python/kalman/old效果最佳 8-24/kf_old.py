import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os.path
from math import sqrt

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
ARx, ARy, ARz, NId = [], [], [], []
NIx, NIy, NIz = [], [], []

for num in range(1900):
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
Pk = np.identity(3) * 1

std = [np.var(ARx), np.var(ARy), np.var(ARz),
       np.var(NIx), np.var(NIy), np.var(NIz)]
Wref = [10, 10, 10, 1, 1, 1]
Wk = np.diag((100, 100, 100, 10, 10, 0.1))
print(Wk)
# processing noise
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
T = len(t1)

x_gt = -0.353
arxd = [ARx[i] - x_gt for i in range(T)]
nixd = [NIx[i] - x_gt for i in range(T)]
kalmanxd = [kalmanx[i] - x_gt for i in range(T)]

plt.plot(t1, arxd, color = 'r', label = 'vio err in x axis (m)')
plt.plot(t1, nixd, color = 'b', label = 'uwb err in x axis (m)')
plt.plot(t1, kalmanxd, color = 'g', label = 'kalman err in x axis (m)')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval (frame)')
plt.ylabel('x (m)')
plt.legend()
plt.show()

T -= 500
rmse_x_ar = sqrt(sum([n * n for n in arxd[500:]])/T)
rmse_x_ni = sqrt(sum([n * n for n in nixd[500:]])/T)
rmse_x_kalman = sqrt(sum([n * n for n in kalmanxd[500:]])/T)
print(rmse_x_ar, rmse_x_ni, rmse_x_kalman)

y_gt = 0.856
aryd = [ARy[i] - y_gt for i in range(len(ARy))]
niyd = [NIy[i] - y_gt for i in range(len(NIy))]
kalmanyd = [kalmany[i] - y_gt for i in range(len(kalmany))]


plt.plot(t1, aryd, color = 'r', label = 'vio err in y axis (m)')
plt.plot(t1, niyd, color = 'b', label = 'uwb err in y axis (m)')
plt.plot(t1, kalmanyd, color = 'g', label = 'kalman err in y axis (m)')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval (frame)')
plt.ylabel('y (m)')
plt.legend()
plt.show()

rmse_y_ar = sqrt(sum([n * n for n in aryd[500:]])/T)
rmse_y_ni = sqrt(sum([n * n for n in niyd[500:]])/T)
rmse_y_kalman = sqrt(sum([n * n for n in kalmanyd[500:]])/T)
print(rmse_y_ar, rmse_y_ni, rmse_y_kalman)

z_gt = -1.403
arzd = [ARz[i] - z_gt for i in range(len(ARz))]
nizd = [NIz[i] - z_gt for i in range(len(NIz))]
kalmanzd = [kalmanz[i] - z_gt for i in range(len(kalmanz))]

plt.plot(t1, arzd, color = 'r', label = 'vio err in z axis (m)')
plt.plot(t1, nizd, color = 'b', label = 'uwb err in z axis (m)')
plt.plot(t1, kalmanzd, color = 'g', label = 'kalman err in z axis (m)')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval (frame)')
plt.ylabel('z (m)')
plt.legend()
plt.show()

rmse_z_ar = sqrt(sum([n * n for n in arzd[500:]])/T)
rmse_z_ni = sqrt(sum([n * n for n in nizd[500:]])/T)
rmse_z_kalman = sqrt(sum([n * n for n in kalmanzd[500:]])/T)
print(rmse_z_ar, rmse_z_ni, rmse_z_kalman)

plt.figure()
plt.title('NI & ARKit distance measurement')
labels = 'AR-x', 'NI-x'
plt.boxplot([ARx, NIx], labels = labels, showmeans = True)
plt.show()

# print("dx mean of UWB / Kalman is", np.mean(nixd), np.mean(kalmanxd))
# print("dy mean of UWB / Kalman is", np.mean(niyd), np.mean(kalmanyd))
# print("dz mean of UWB / Kalman is", np.mean(nizd), np.mean(kalmanzd))

# comment beyond codes for using in other experiments
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