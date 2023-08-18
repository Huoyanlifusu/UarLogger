#!/usr/bin/env python3

import csv
import numpy as np
import matplotlib.pyplot as plt
import os.path

vio_points = []
ni_points = []
cam_move = []
path = os.path.abspath("ar_data2.csv")
with open(path, newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    next(reader)
    i = 0
    for row in reader:
        vio_points.append(list(map(float, row[0].split('+'))))
        ni_points.append(list(map(float, row[1].split('+'))))
        cam_move.append(list(map(float, row[2].split('+'))))

xv, yv, zv = zip(*vio_points)
xu, yu, zu = zip(*ni_points)

xk = np.array(vio_points[0]).reshape(3,1)

Ak = np.identity(3)
Ck = np.concatenate((np.identity(3), np.identity(3)))
Pk = np.identity(3) * 10

std = [np.std(xv), np.std(yv, ddof=1), np.std(zv, ddof=1),
       np.var(xu), np.var(yu, ddof=1), np.var(zu, ddof=1)]
Wn = np.diag([0.1, 0.1, 0.1, 10, 1, 10])
Wk = np.diag(std) + Wn
# 状态方程噪声
Q = np.identity(3) * 0.005

frames = len(ni_points)

zhuangtai = []

for k in range(frames):
    xk_pre = np.dot(Ak, xk)
    Pk_pre = np.dot(Ak, np.dot(Pk, np.transpose(Ak))) + Q

    zk = np.concatenate((np.array(vio_points[k]).reshape(3,1), np.array(ni_points[k]).reshape(3,1)))
    yk = zk - np.dot(Ck, xk_pre)

    Sk = np.dot(Ck, np.dot(Pk_pre, np.transpose(Ck))) + Wk
    Kk = np.dot(np.dot(Pk_pre, np.transpose(Ck)), np.linalg.inv(Sk))

    xk = xk_pre + np.dot(Kk, yk)
    Pk = np.dot(np.identity(3) - np.dot(Kk, Ck), Pk_pre) 
    
    zhuangtai.append([xk[0][0], xk[1][0], xk[2][0]])

# ground truth
phoneA_ground_x = 1.039
phoneA_height = 0.143
phoneB_ground_x = 0.831
phoneB_height = 0.133
x_groundTruth = (phoneA_ground_x - phoneA_height/2.0) - (phoneB_ground_x - phoneB_height/2.0)

phoneA_wall_y = 0.596
phoneA_width = 0.073
phoneB_wall_y = 0.426
phoneB_width = 0.068
y_groundTruth = (phoneB_wall_y - phoneB_width/2.0) - (phoneA_wall_y - phoneA_width/2.0)

#suppose the thickness of the mobile phone is the same
phoneA_wall_z = -0.817
phoneB_wall_z = -0.215
z_groundTruth = phoneA_wall_z - phoneB_wall_z

ni_diff_x = []
ni_diff_y = []
ni_diff_z = []

vio_diff_x = []
vio_diff_y = []
vio_diff_z = []

for lst in ni_points:
    ni_diff_x.append(lst[0] - x_groundTruth)
    ni_diff_y.append(lst[1] - y_groundTruth)
    ni_diff_z.append(lst[2] - z_groundTruth)
for lst in vio_points:
    vio_diff_x.append(lst[0] - x_groundTruth)
    vio_diff_y.append(lst[1] - y_groundTruth)
    vio_diff_z.append(lst[2] - z_groundTruth)

kalman_diff_x = []
kalman_diff_y = []
kalman_diff_z = []
for xk in zhuangtai:
    kalman_diff_x.append(xk[0] - x_groundTruth)
    kalman_diff_y.append(xk[1] - y_groundTruth)
    kalman_diff_z.append(xk[2] - z_groundTruth)

t1 = [i for i in range(frames)]
plt.plot(t1, ni_diff_x, color = 'r', label = 'ni err with gt')
plt.plot(t1, kalman_diff_x, color = 'b', label = 'kalman err with gt')
plt.plot(t1, vio_diff_x, color = 'g', label = 'vio err with gt')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('x axis')
plt.legend()
plt.show()

plt.plot(t1, ni_diff_y, color = 'r', label = 'ni err with gt')
plt.plot(t1, kalman_diff_y, color = 'b', label = 'kalman err with gt')
plt.plot(t1, vio_diff_y, color = 'g', label = 'vio err with gt')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('y axis')
plt.legend()
plt.show()

plt.plot(t1, ni_diff_z, color = 'r', label = 'ni err with gt')
plt.plot(t1, kalman_diff_z, color = 'b', label = 'kalman err with gt')
plt.plot(t1, vio_diff_z, color = 'g', label = 'vio err with gt')
# plt.plot(t1, vx, color = 'g', label = 'x velocity prediction')
plt.xlabel('time interval')
plt.ylabel('z axis')
plt.legend()
plt.show()