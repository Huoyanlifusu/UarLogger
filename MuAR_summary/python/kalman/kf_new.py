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
Pk = np.diag((0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001))
Ck = np.identity(6)
def Calculate_A(k):
    A = np.diag((1.0,1.0,1.0,1.0,1.0,1.0))
    #print(Times[k]-Times[k-1])
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

Rk = np.diag((np.var(NIx)*150, np.var(NIy)*150, np.var(NIz)*150, np.var(vx)*3, np.var(vy)*3, np.var(vz)*3))
# Rk = np.diag((10, 10, 10, 1, 1, 1))
Qk = np.diag((0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001))
print(Rk)
Pk = np.diag((np.var(NIx), np.var(NIy), np.var(NIz), np.var(vx), np.var(vy), np.var(vz)))
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

y_gt = 0.856
aryd = [ARy[i+1] - y_gt for i in range(T-1)]
niyd = [NIy[i+1] - y_gt for i in range(T-1)]
kalmanyd = [res[i][1][0] - y_gt for i in range(T-1)]

z_gt = -1.403
arzd = [ARz[i+1] - z_gt for i in range(T-1)]
nizd = [NIz[i+1] - z_gt for i in range(T-1)]
kalmanzd = [res[i][2][0] - z_gt for i in range(T-1)]

rmse_T = T-250
rmse_x_ar = sqrt(sum([n * n for n in arxd[250:]])/rmse_T)
rmse_x_ni = sqrt(sum([n * n for n in nixd[250:]])/rmse_T)
rmse_x_kalman = sqrt(sum([n * n for n in kalmanxd[250:]])/rmse_T)

rmse_y_ar = sqrt(sum([n * n for n in aryd[250:]])/rmse_T)
rmse_y_ni = sqrt(sum([n * n for n in niyd[250:]])/rmse_T)
rmse_y_kalman = sqrt(sum([n * n for n in kalmanyd[250:]])/rmse_T)

rmse_z_ar = sqrt(sum([n * n for n in arzd[250:]])/rmse_T)
rmse_z_ni = sqrt(sum([n * n for n in nizd[250:]])/rmse_T)
rmse_z_kalman = sqrt(sum([n * n for n in kalmanzd[250:]])/rmse_T)
print(rmse_x_ar, rmse_x_ni, rmse_x_kalman, rmse_y_ar, rmse_y_ni, rmse_y_kalman, rmse_z_ar, rmse_z_ni, rmse_z_kalman)

plt.figure(figsize=(1,3))
# labels = 'VIO', 'UWB'
# f = plt.boxplot([ARx, NId], vert=True, labels = labels, patch_artist=True)
font1 = {"family" : "Times New Roman", "weight" : "bold", "size" : 25}
font2 = {"family" : "Times New Roman", "weight" : "bold", "size" : 20}
# c_list = ['#118AD5', '#ffd166']
# for box, c in zip(f['boxes'], c_list):  # 对箱线图设置颜色
    # box.set(color=c, linewidth=2)
    # box.set(facecolor=c)
# plt.ylabel('Ranging Error (m)', font1)
# plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
# plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
# plt.ylim((-0.19, 0.41))
# plt.yticks(np.arange(-0.1, 0.31, 0.1))
# plt.grid(axis="y", zorder = 0)
# plt.show()

ax1 = plt.subplot(131)
t1 = [i for i in range(T-1-250)]
plt.title("X Axis", font1)
plt.plot(t1, kalmanxd[250:], color = 'g', label = 'Kalman Filter', linewidth = 2, zorder = 100)
plt.plot(t1, arxd[250:], color = 'r', label = 'VIO')
plt.plot(t1, nixd[250:], color = 'b', label = 'UWB')
# plt.plot(t1, vx, color = 'c', label = 'x velocity prediction (m/s)')
plt.xlabel('Time (frame)', font1)
plt.ylabel('Localization Error (m)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.1, 0.2))
plt.xticks(np.arange(0, 1501, 500))
plt.yticks(np.arange(0, 0.21, 0.2))
plt.legend(prop = font2)
# plt.ylabel('x (m)')

ax2 = plt.subplot(132)
plt.title("Y Axis", font1)
plt.plot(t1, aryd[250:], color = 'r')
plt.plot(t1, niyd[250:], color = 'b')
plt.plot(t1, kalmanyd[250:], color = 'g', linewidth = 2, zorder = 100)
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('Time (frame)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.25, 0.3))
plt.yticks(np.arange(-0.2, 0.21, 0.2))
plt.xticks(np.arange(0, 1501, 500))
# plt.ylabel('y (m)')

ax3 = plt.subplot(133)
plt.title("Z Axis", font1)
plt.plot(t1, arzd[250:], color = 'r')
plt.plot(t1, nizd[250:], color = 'b')
plt.plot(t1, kalmanzd[250:], color = 'g', linewidth = 2, zorder = 100)
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('Time (frame)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.2, 0.1))
plt.yticks(np.arange(-0.2, 0.01, 0.2))
plt.xticks(np.arange(0, 1501, 500))
# plt.ylabel('z (m)')

plt.legend()
plt.show()

vx_kalman = [res[i][3][0] for i in range(T-1)]
vy_kalman = [res[i][4][0] for i in range(T-1)]
vz_kalman = [res[i][5][0] for i in range(T-1)]
t1 = [i for i in range(T-1)]

rmse_vx_ar = sqrt(sum([n * n for n in vx])/T)
rmse_vx_kf = sqrt(sum([n * n for n in vx_kalman])/T)
print(rmse_vx_ar, rmse_vx_kf)
rmse_vy_ar = sqrt(sum([n * n for n in vy])/T)
rmse_vy_kf = sqrt(sum([n * n for n in vy_kalman])/T)
print(rmse_vy_ar, rmse_vy_kf)
rmse_vz_ar = sqrt(sum([n * n for n in vz])/T)
rmse_vz_kf = sqrt(sum([n * n for n in vz_kalman])/T)
print(rmse_vz_ar, rmse_vz_kf)

plt.figure(figsize=(1,3))

ax1 = plt.subplot(131)
plt.title("X Axis", font1)
plt.plot(t1, vx, color = 'r', label = 'VIO')
plt.plot(t1, vx_kalman, color = 'c', label = 'Kalman Filter')
plt.xlabel('Time (frame)', font1)
plt.ylabel('Velocity (m/s)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.4, 0.4))
plt.yticks(np.arange(-0.2, 0.21, 0.2))
plt.xticks(np.arange(0, 1501, 500))
plt.legend(prop = font2)

ax2 = plt.subplot(132)
plt.title("Y Axis", font1)
plt.plot(t1, vy, color = 'r')
plt.plot(t1, vy_kalman, color = 'c')
plt.xlabel('Time (frame)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.3, 0.3))
plt.yticks(np.arange(-0.2, 0.21, 0.2))
plt.xticks(np.arange(0, 1501, 500))

ax3 = plt.subplot(133)
plt.title("Z Axis", font1)
plt.plot(t1, vz, color = 'r')
plt.plot(t1, vz_kalman, color = 'c')
plt.xlabel('Time (frame)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.2, 0.2))
plt.yticks(np.arange(-0.2, 0.21, 0.2))
plt.xticks(np.arange(0, 1501, 500))

plt.show()