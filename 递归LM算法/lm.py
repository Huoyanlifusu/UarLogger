import numpy as np
import csv
import math
import matplotlib.pyplot as plt
# ARKit及NI数据预处理
pk_arkit = []
pk_ni = []
count = 0

with open('ar_data2.csv', newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    for row in reader:
        if count > 0:
            pk_arkit.append(list(map(float, row[0].split('+'))))
            pk_ni.append(list(map(float, row[1].split("+"))))
        count += 1
x_cam = []
y_cam = []
z_cam = []
x_ni = []
y_ni = []
z_ni = []
x1 = []
for i in range(len(pk_ni)):
    x_cam.append(pk_arkit[i][0])
    y_cam.append(pk_arkit[i][1])
    z_cam.append(pk_arkit[i][2])
    x_ni.append(pk_ni[i][0])
    y_ni.append(pk_ni[i][1])
    z_ni.append(pk_ni[i][2])
    x1.append(i)
fig = plt.figure()
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
beta = np.array([[1.0],[1.0],[1.0]])  # beta状态变量初始化
# 枚举变量
k = 0
# 常数参数初始化
rho = 0.0003 # 论文里未提及 应该是一个控制beta是否更新的阈值
zeta = 0.0001
epsilon = 0.001
Len = 100 # 单次更新次数
m = 30 # 滑动窗口的大小
v = 5 # Lambda变化的速率
time_constant = 50 # 时间常数
learning_rate_init = np.diag([1.0,1.0,1.0])
# 过程量
N_m = [] # N_m数组的定义及初始化
diag = np.array([10.0,10.0,10.0])
Lambda = np.diag(diag)
Err_last = 0.5
Err_cur = 0.5

def calculateSlidingWindowAvgPosition(N_m, beta):
    res = 0
    for item in N_m:
        res += math.sqrt(abs(beta[0][0]*item[0]*item[0])+abs(beta[1][0]*item[1]*item[1])+abs(beta[2][0]*item[2]*item[2]))
    return res/len(N_m)

def calculateCurrentPosition(pk_cur, beta):
    return math.sqrt(abs(beta[0][0]*pk_cur[0]*pk_cur[0])+abs(beta[1][0]*pk_cur[1]*pk_cur[1])+abs(beta[2][0]*pk_cur[2]*pk_cur[2]))

def calculate_ri(N_m, beta):
    R_i = []
    y_fbeta = np.zeros((len(N_m),1))
    for index, item in enumerate(N_m):
        ri = 0
        for i in range(beta.shape[0]):
            ri -= math.pow(item[3+i] - beta[i][0]*item[i], 2)
        R_i.append(ri)
        y_fbeta[index, :] = [-math.sqrt(abs(ri))]
    return [R_i, y_fbeta]

def calculateJacobianMatrix(N_m, beta):
    Jacobian = np.zeros((len(N_m), len(beta)))
    for index, item in enumerate(N_m):
        item1 = 2*item[0]*(beta[0][0]-item[3])
        item2 = 2*item[1]*(beta[1][0]-item[4])
        item3 = 2*item[2]*(beta[2][0]-item[5])
        Jacobian[index, :] = [item1, item2, item3]
    return Jacobian

def calculateDeltaBeta(Jacobian, beta, Lambda, y_fbeta):
    left = np.dot(np.transpose(Jacobian), Jacobian) + np.dot(Lambda, np.identity(len(beta)))
    right = np.dot(np.transpose(Jacobian), y_fbeta)
    delta_beta = np.dot(np.linalg.inv(left), right)
    return delta_beta

while k < m:
    N_m.append([pk_arkit[k][0], pk_arkit[k][1], pk_arkit[k][2], pk_ni[k][0], pk_ni[k][1], pk_ni[k][2]])
    k += 1

for k in range(m, len(pk_arkit)):
    print(k)
    pk_ni_cur = pk_ni[k]
    pk_cur = pk_arkit[k]
    if abs(calculateCurrentPosition(pk_cur, beta) - calculateSlidingWindowAvgPosition(N_m, beta)) > rho:
        # update sliding window
        N_m.pop(0)
        N_m.append([pk_cur[0], pk_cur[1], pk_cur[2], pk_ni_cur[0], pk_ni_cur[1], pk_ni_cur[2]])
        l = 1
        learning_rate = np.multiply(learning_rate_init, np.exp(-k/time_constant))
        while l < Len:
            if l > 2 and abs((Err_last - Err_cur)/Err_last) > zeta:
                break
            Ri = calculate_ri(N_m, beta)
            Jacob = calculateJacobianMatrix(N_m, beta)
            delta_beta = calculateDeltaBeta(Jacob, beta, Lambda, Ri[1])
            i = 0
            for i in range(beta.shape[0]):
                beta[i][0] += learning_rate[i][i] * delta_beta[i][0]
                if abs(delta_beta[i][0]/beta[i][0]) < epsilon:
                    Lambda[i][i] /= v
                    v *= 1.4
                else:
                    Lambda[i][i] *= v
                    v /= 1.4
            Err_last = Err_cur
            Err_cur = sum(num * num for num in Ri[0])
            l += 1
    betas.append([beta[0][0], beta[1][0], beta[2][0]])
sx, sy, sz = zip(*betas)
newx, newy, newz = [], [], []
for i in range(m, len(pk_ni)):
    newx.append(pk_arkit[i][0]*sx[i-m])
    newy.append(pk_arkit[i][0]*sy[i-m])
    newz.append(pk_arkit[i][2]*sz[i-m])
x2 = [i+m for i in range(len(betas))]
xg =[x_groundTruth] * len(x1)
plt.plot(x1, x_cam, color = 'r', label = 'arkit x diff raw data')
plt.plot(x1, x_ni, color = 'g', label = 'ni x diff raw data')
plt.plot(x1, xg, color = 'c', label = 'x diff ground truth')
plt.plot(x2, newx, color = 'b', label = 'x diff after LM')
plt.xlabel("frame")
plt.ylabel("m")
plt.legend()
plt.show()

y2 = [i+m for i in range(len(betas))]
yg =[y_groundTruth] * len(x1)
plt.plot(x1, y_cam, color = 'r', label = 'arkit y diff raw data')
plt.plot(x1, y_ni, color = 'g', label = 'ni y diff raw data')
plt.plot(x1, yg, color = 'c', label = 'y diff ground truth')
plt.plot(y2, newy, color = 'b', label = 'y diff after LM')
plt.xlabel("frame")
plt.ylabel("m")
plt.legend()
plt.show()

z2 = [i+m for i in range(len(betas))]
zg =[z_groundTruth] * len(x1)
plt.plot(x1, z_cam, color = 'r', label = 'arkit z diff raw data')
plt.plot(x1, z_ni, color = 'g', label = 'ni z diff raw data')
plt.plot(x1, zg, color = 'c', label = 'z diff ground truth')
plt.plot(z2, newz, color = 'b', label = 'z diff after LM')
plt.xlabel("frame")
plt.ylabel("m")
plt.legend()
plt.show()