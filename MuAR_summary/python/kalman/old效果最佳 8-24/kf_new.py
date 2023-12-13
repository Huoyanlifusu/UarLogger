import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os.path

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

# 初始化
Xk = np.array([NIx[0], 0, 0, 0, 0, 0]).reshape(6,1)
Pk = np.diag((10, 1, 1, 1000, 1000, 1000))

def Calculate_A(k):
    A = np.diag((1.0,1.0,1.0,1.0,1.0,1.0))
    A[0][3] = A[1][4] = A[2][5] = Times[k] - Times[k-1]
    return A
Ck = np.identity(6)
# 过程噪声 测量噪声
Q = np.diag((0.0001, 0.0001, 0.0001, 0.001, 0.001, 0.001))
R = np.diag((np.var(NIx)*1000, np.var(NIy)*1000, np.var(NIz)*100, np.var(vx), np.var(vy), np.var(vz)))

res = []

def calculate_Q(k):
    dt = Times[k] - Times[k-1]
    return np.diag((vx[k-1]*dt, vy[k-1]*dt, vz[k-1]*dt, 0, 0, 0))

for k in range(1, T):
    # 预测公式
    Qk = calculate_Q(k)
    Ak = Calculate_A(k)
    Xkplusone_pre = Ak @ Xk
    Pkplusone_pre = Ak @ Pk @ Ak.T + Qk
    # 更新公式
    zk = np.array([NIx[k], NIy[k], NIz[k], vx[k-1], vy[k-1], vz[k-1]]).reshape(6, 1)
    # Kalman Gain
    K = Pkplusone_pre @ Ck.T @ np.linalg.inv(Ck @ Pkplusone_pre @ Ck.T + R)
    Xkplusone_post = Xkplusone_pre - K @ (zk - Ck @ Xkplusone_pre)
    Pkplusone_post = Pkplusone_pre - K @ Ck @ Pkplusone_pre
    Xk = Xkplusone_post
    Pk = Pkplusone_post
    res.append(Xk)


x_gt = -0.353
arxd = [ARx[i+1] - x_gt for i in range(T-1)]
nixd = [NIx[i+1] - x_gt for i in range(T-1)]
kalmanxd = [res[i][0][0] - x_gt for i in range(T-1)]
t1 = [i for i in range(T-1)]
plt.plot(t1, kalmanxd, color = 'g', label = 'kalman err in x axis')
plt.plot(t1, arxd, color = 'r', label = 'vio err in x axis')
plt.plot(t1, nixd, color = 'b', label = 'uwb err in x axis')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('x')
plt.legend()
plt.show()

y_gt = 0.856
aryd = [ARy[i+1] - y_gt for i in range(len(ARy)-1)]
niyd = [NIy[i+1] - y_gt for i in range(len(NIy)-1)]
kalmanyd = [res[i][1][0] - y_gt for i in range(len(res))]
plt.plot(t1, aryd, color = 'r', label = 'vio err in y axis')
plt.plot(t1, niyd, color = 'b', label = 'uwb err in y axis')
plt.plot(t1, kalmanyd, color = 'g', label = 'kalman err in y axis')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('y')
plt.legend()
plt.show()