import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os.path
from math import sqrt

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
ARx, ARy, ARz, vx, vy, vz = [], [], [], [], [], []
NIx, NIy, NIz, NId = [], [], [], []
Times, T = [], 1500

for num in range(T):
    ARx.append(data['ARx'][num])
    ARy.append(data['ARy'][num])
    ARz.append(data['ARz'][num])
    NId.append(data['Distance'][num])
    NIx.append(data['NIx'][num])
    NIy.append(data['NIy'][num])
    NIz.append(data['NIz'][num])
    Times.append(data['TimeStamp'][num])
    if num > 0:
        vx.append((ARx[-1]-ARx[-2])/(Times[-1]-Times[-2]))
        vy.append((ARy[-1]-ARy[-2])/(Times[-1]-Times[-2]))
        vz.append((ARz[-1]-ARz[-2])/(Times[-1]-Times[-2]))
# print(vx)

# initialization
Xk = np.array([0, 0, 0, 0, 0, 0]).reshape(6,1)
Pk = np.diag((10000, 10000, 10000, 10000, 10000, 10000))
Ck = np.identity(6)
def Calculate_A(k):
    A = np.diag((1.0,1.0,1.0,1.0,1.0,1.0))
    A[0][3] = (Times[k] - Times[k-1])
    A[1][4] = (Times[k] - Times[k-1])
    A[2][5] = (Times[k] - Times[k-1])
    return A

def Calculate_C(k):
    C = np.diag((1.0,1.0,1.0,1.0,1.0,1.0))
    C[0][3] = (Times[k] - Times[k-1])
    C[1][4] = (Times[k] - Times[k-1])
    C[2][5] = (Times[k] - Times[k-1])
    return C
# processing noise
Qk = np.diag((0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001))

res = [Xk]
x_mean, y_mean, z_mean = np.mean(NIx), np.mean(NIy), np.mean(NIz)
# def calculate_R():
    # x_var = (x_mean - res[-1][0][0]) ** 2 * 100
    # y_var = (y_mean - res[-1][1][0]) ** 2 * 100
    # z_var = (z_mean - res[-1][2][0]) ** 2 * 100
    # vx_var = (-res[-1][3][0]) ** 2
    # vy_var = (-res[-1][4][0]) ** 2
    # vz_var = (-res[-1][5][0]) ** 2
    # return np.diag((x_var, y_var, z_var, vx_var, vy_var, vz_var))

# def generate_Q():
#     Q = np.random.rand(6, 6)
#     gaussian_noise = np.random.normal(0, 0.1, Q.shape)
#     return gaussian_noise

Rk = np.diag((np.var(NIx)*3, np.var(NIy)*3, np.var(NIz)*80, np.var(vx)*3, np.var(vy)*3, np.var(vz)*10))

for k in range(1, T):
    # prediction
    Ak = Calculate_A(k)
    Xkplusone_pre = Ak @ Xk
    Pkplusone_pre = Ak @ Pk @ Ak.T + Qk
    # update
    zk = np.array([NIx[k], NIy[k], NIz[k], vx[k-1], vy[k-1], vz[k-1]]).reshape(6, 1)
    # Kalman Gain
    # Ck = Calculate_C(k)
    Kk = Pkplusone_pre @ Ck.T @ np.linalg.inv(Ck @ Pkplusone_pre @ Ck.T + Rk)
    Xkplusone_post = Xkplusone_pre + Kk @ (zk - Ck @ Xkplusone_pre)
    Pkplusone_post = Pkplusone_pre @ (np.identity(6) - Kk @ Ck)
    Xk = Xkplusone_post
    Pk = Pkplusone_post
    res.append(Xk)


x_gt = -0.353
arxd = [ARx[i+1] - x_gt for i in range(T-1)]
nixd = [NIx[i+1] - x_gt for i in range(T-1)]
kalmanxd = [res[i][0][0] - x_gt for i in range(T-1)]
t1 = [i for i in range(T-1)]
plt.plot(t1, kalmanxd, color = 'g', label = 'kalman err in x axis (m)')
plt.plot(t1, arxd, color = 'r', label = 'vio err in x axis (m)')
plt.plot(t1, nixd, color = 'b', label = 'uwb err in x axis (m)')
# plt.plot(t1, vx, color = 'c', label = 'x velocity prediction (m/s)')
plt.xlabel('time interval (frame)')
plt.ylabel('x (m)')
plt.legend()
plt.show()

rmse_x_ar = sqrt(sum([n * n for n in arxd])/T)
rmse_x_ni = sqrt(sum([n * n for n in nixd])/T)
rmse_x_kalman = sqrt(sum([n * n for n in kalmanxd])/T)
print(rmse_x_ar, rmse_x_ni, rmse_x_kalman)

y_gt = 0.856
aryd = [ARy[i+1] - y_gt for i in range(T-1)]
niyd = [NIy[i+1] - y_gt for i in range(T-1)]
kalmanyd = [res[i][1][0] - y_gt for i in range(T-1)]
plt.plot(t1, aryd, color = 'r', label = 'vio err in y axis (m)')
plt.plot(t1, niyd, color = 'b', label = 'uwb err in y axis (m)')
plt.plot(t1, kalmanyd, color = 'g', label = 'kalman err in y axis (m)')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval (frame)')
plt.ylabel('y (m)')
plt.legend()
plt.show()

rmse_y_ar = sqrt(sum([n * n for n in aryd])/T)
rmse_y_ni = sqrt(sum([n * n for n in niyd])/T)
rmse_y_kalman = sqrt(sum([n * n for n in kalmanyd])/T)
print(rmse_y_ar, rmse_y_ni, rmse_y_kalman)

z_gt = -1.403
arzd = [ARz[i+1] - z_gt for i in range(T-1)]
nizd = [NIz[i+1] - z_gt for i in range(T-1)]
kalmanzd = [res[i][2][0] - z_gt for i in range(T-1)]
plt.plot(t1, arzd, color = 'r', label = 'vio err in z axis (m)')
plt.plot(t1, nizd, color = 'b', label = 'uwb err in z axis (m)')
plt.plot(t1, kalmanzd, color = 'g', label = 'kalman err in z axis (m)')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval (frame)')
plt.ylabel('z (m)')
plt.legend()
plt.show()

rmse_z_ar = sqrt(sum([n * n for n in arzd])/T)
rmse_z_ni = sqrt(sum([n * n for n in nizd])/T)
rmse_z_kalman = sqrt(sum([n * n for n in kalmanzd])/T)
print(rmse_z_ar, rmse_z_ni, rmse_z_kalman)

vx_kalman = [res[i][3][0] for i in range(T-1)]
plt.plot(t1, vx, color = 'r', label = 'x axis velocity from VIO prediction (m/s)')
plt.plot(t1, vx_kalman, color = 'c', label = 'x axis velocity from kalman filter (m/s)')
plt.xlabel('time interval (frame)')
plt.ylabel('velocity in x axis (m/s)')
plt.show()

vy_kalman = [res[i][4][0] for i in range(T-1)]
plt.plot(t1, vy, color = 'r', label = 'y axis velocity from VIO prediction (m/s)')
plt.plot(t1, vy_kalman, color = 'c', label = 'y velocity from kalman filter (m/s)')
plt.xlabel('time interval (frame)')
plt.ylabel('velocity in y axis (m/s)')
plt.show()

vz_kalman = [res[i][5][0] for i in range(T-1)]
plt.plot(t1, vz, color = 'r', label = 'z velocity from VIO prediction (m/s)')
plt.plot(t1, vz_kalman, color = 'c', label = 'z velocity from kalman filter (m/s)')
plt.xlabel('time interval (frame)')
plt.ylabel('velocity in z axis (m/s)')
plt.show()