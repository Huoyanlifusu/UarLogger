import numpy as np
import csv
import math
import matplotlib.pyplot as plt
# ARKit及NI数据预处理
pk_arkit = []
pak = []
dk = []
count = 0

with open('ar_data2.csv', newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    for row in reader:
        if count > 0:
            pk_arkit.append(list(map(float, row[0].split('+'))))
            pak.append(list(map(float, row[2].split("+"))))
            dk.append(float(row[3]))
        count += 1
x_cam = []
x = []
for i in range(len(pak)):
    x_cam.append(pak[i][0])
    x.append(i)
fig = plt.figure()
plt.plot(x, x_cam, color = 'r', label = 'x raw data')
plt.xlabel("frame")
plt.ylabel("m")
plt.legend()
plt.show()
# x denotes down, y denotes left, z denotes front of the phone
# conforms arkit camera coordinate in portrait mode
# phoneA is iPhone 13
# phoneB is iPhone 12mini
phoneA_ground_x = 1.208
phoneA_height = 0.145
phoneB_ground_x = 0.924
phoneB_height = 0.132
x_groundTruth = (phoneA_ground_x - phoneA_height/2.0) - (phoneB_ground_x - phoneB_height/2.0)

phoneA_wall_y = 0.477
phoneA_width = 0.078
phoneB_wall_y = 0.435
phoneB_width = 0.063
y_groundTruth = (phoneB_wall_y - phoneB_width/2.0) - (phoneA_wall_y - phoneA_width/2.0)

phoneA_wall_z = -1.013
phoneB_wall_z = -0.312
z_groundTruth = phoneA_wall_z - phoneB_wall_z

# 状态变量定义及初始化
betas = []
beta = pak[0] # beta状态变量初始化
# 枚举变量
k = 0
# 常数参数初始化
rho = 0.001 # 论文里未提及
zeta = 0.001
epsilon = 0.001
Len = 1000 # 迭代次数
m = 15 # 滑动窗口的大小
v = 1.5 # Lambda变化的速率
time_constant = 300
learning_rate_init = np.diag([1,1,1])
# 过程量
N_m = [] # N_m数组的定义及初始化
diag = np.array([100,100,100])
Lambda = np.diag(diag)

def calculateSlidingWindowAvgPosition(N_m):
    res = 0
    for item in N_m:
        res += math.sqrt(item[0]*item[0]+item[1]*item[1]+item[2]*item[2])
    return res/len(N_m)

def calculateCurrentPosition(pk_cur):
    return math.sqrt(pk_cur[0]*pk_cur[0]+pk_cur[1]*pk_cur[1]+pk_cur[2]*pk_cur[2])

def calculate_ri(N_m, beta):
    R_i = []
    y_fbeta = np.zeros((15,1))
    for index, item in enumerate(N_m):
        ri = item[3] * item[3] - abs((beta[0]-item[0])*(beta[0]-item[0]) + (beta[1]-item[1])*(beta[1]-item[1]) + (beta[2]-item[2])*(beta[2]-item[2]))
        R_i.append(ri)
        y_fbeta[index, :] = [item[3] - math.sqrt((beta[0]-item[0])*(beta[0]-item[0]) + (beta[1]-item[1])*(beta[1]-item[1]) + (beta[2]-item[2])*(beta[2]-item[2]))]
    return [R_i, y_fbeta]

def calculateJacobianMatrix(N_m, beta):
    Jacobian = np.zeros((len(N_m), len(beta)))
    for index, item in enumerate(N_m):
        Jacobian[index, :] = [2*(beta[0]-item[0]), 2*(beta[1]-item[1]), 2*(beta[2]-item[2])]
    return Jacobian

def calculateDeltaBeta(Jacobian, beta, Lambda, y_fbeta):
    left = np.dot(np.transpose(Jacobian), Jacobian) + np.dot(Lambda, np.identity(len(beta)))
    right = np.dot(np.transpose(Jacobian), y_fbeta)
    delta_beta = np.dot(np.linalg.inv(left), right)
    return delta_beta

while k < m:
    N_m.append([pk_arkit[k][0], pk_arkit[k][1], pk_arkit[k][2], dk[k]])
    k += 1
    beta = pak[k]
Ri = calculate_ri(N_m, beta)
Err_last = sum(num*num for num in Ri[0][:10])
Err_cur = sum(num*num for num in Ri[0])
for k in range(m, len(pk_arkit)):
    d_cur = dk[k]
    pk_cur = pk_arkit[k]
    if abs(calculateCurrentPosition(pk_cur) - calculateSlidingWindowAvgPosition(N_m)) > rho:
        # update sliding window
        N_m.pop(0)
        N_m.append([pk_cur[0], pk_cur[1], pk_cur[2], d_cur])
        l = 1
        learning_rate = np.multiply(learning_rate_init, np.exp(-k/time_constant))
        while l < Len and abs((Err_last - Err_cur)/Err_last) < zeta:
            Ri = calculate_ri(N_m, beta)
            Jacob = calculateJacobianMatrix(N_m, beta)
            delta_beta = calculateDeltaBeta(Jacob, beta, Lambda, Ri[1])
            i = 0
            for i in range(len(beta)):
                beta[i] += learning_rate[i][i] * delta_beta[i][0]
                if abs(delta_beta[i][0]/beta[i]) < epsilon:
                    Lambda[i][i] /= v
                else:
                    Lambda[i][i] *= v
            Err_last = Err_cur
            Err_cur = sum(num * num for num in Ri[0])
            l += 1
        
    betas.append(beta)
x, y, z = zip(*betas)
x2 = [i for i in range(len(pak))]
plt.plot(x2[m:], x, color = 'r', label = 'cam pos after LM')
plt.xlabel("frame")
plt.ylabel("m")
plt.legend()
plt.show()
