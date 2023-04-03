import csv
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

ar_points = []
ni_points = []
mycam = []
count = 0
with open('ar_data_2.csv', newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    for row in reader:
        count += 1
        if count >= 2194:
            ar_points.append(row[0].split('+'))
            ni_points.append(row[1].split('+'))
            mycam.append(row[1].split('+'))
points1 = []
points2 = []
points3 = []
err = []
for point in ar_points[1:]:
    x, y, z = float(point[0]), float(point[1]), float(point[2])
    points1.append((x, y, z))
for point in ni_points[1:]:
    x, y, z = float(point[0]), float(point[1]), float(point[2])
    points2.append((x, y, z))
for i in range(len(points1)):
    x, y, z = float(points1[i][0] - points2[i][0]), float(points1[i][1] - points2[i][1]), float(points1[i][2] - points2[i][2])
    err.append((x, y, z))
x1, y1, z1 = zip(*points1)
x2, y2, z2 = zip(*points2)
x4, y4, z4 = zip(*err)
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.plot(x1, y1, z1, c = 'r', marker = 'o', markersize = 1, label = "peer pos in arkit")
ax.plot(x2, y2, z2, c = 'b', marker = 'o', markersize = 1, label = "peer pos in ni")
ax.plot(x4, y4, z4, c = 'g', marker = 'o', markersize = 1, label = 'pos error')
ax.set_xlabel("X axis")
ax.set_ylabel("Y axis")
ax.set_zlabel("Z axis")
# ax.set_xlim(0.01, 0.02)
# ax.set_ylim(0.05, 0.15)
# ax.set_zlim(-0.24, -0.19)
ax.legend()
plt.show()


# 递归法减小误差
x_pre = [-0.1]
e_est = [0.5]
k = []
z_in = []
e_mea = 0.01
for index in range(len(points1)):
    point1x = points1[index][0]
    point2x = points2[index][0]
    k.append(e_est[-1]/(e_est[-1]+e_mea))
    z_in.append(point1x - point2x)
    x_pre.append(x_pre[-1]+k[-1]*(z_in[-1]-x_pre[-1]))
    e_est.append((1 - k[-1])*e_est[-1])
x1 = range(0, len(x_pre))
x2 = range(1, len(z_in)+1)
plt.plot(x1, x_pre, color = 'r', label = 'pre_error')
plt.plot(x2, z_in, color = 'b', label = 'mea_error')
plt.xlabel('x axis')
plt.ylabel('y axis')
plt.legend()
plt.show()

y_pre = [0.03]
e_est = [0.3]
k = []
z_in = []
e_mea = 0.7
for index in range(len(points1)):
    point1y = points1[index][1]
    point2y = points2[index][1]
    k.append(e_est[-1]/(e_est[-1]+e_mea))
    z_in.append(point1y - point2y)
    y_pre.append(y_pre[-1]+k[-1]*(z_in[-1]-y_pre[-1]))
    e_est.append((1 - k[-1])*e_est[-1])
yi = range(0, len(y_pre))
y2 = range(1, len(z_in)+1)
plt.plot(x1, y_pre, color = 'r', label = 'pre_error')
plt.plot(x2, z_in, color = 'b', label = 'mea_error')
plt.xlabel('x axis')
plt.ylabel('y axis')
plt.legend()
plt.show()

z_pre = [-0.03]
e_est = [0.3]
k = []
z_in = []
e_mea = 0.1
for index in range(len(points1)):
    point1z = points1[index][2]
    point2z = points2[index][2]
    k.append(e_est[-1]/(e_est[-1]+e_mea))
    z_in.append(point1z - point2z)
    z_pre.append(z_pre[-1]+k[-1]*(z_in[-1]-z_pre[-1]))
    e_est.append((1 - k[-1])*e_est[-1])
z1 = range(0, len(y_pre))
z2 = range(1, len(z_in)+1)
plt.plot(z1, z_pre, color = 'r', label = 'pre_error')
plt.plot(z2, z_in, color = 'b', label = 'mea_error')
plt.xlabel('x axis')
plt.ylabel('y axis')
plt.legend()
plt.show()


#卡尔曼滤波最优化位置
jiaquan_k = 0.64
u_input = np.array([[1], [2], [3]]).reshape(3,1)
for index in range(1, len(points1)):
    x_diff = (points1[index][0] - points1[index-1][0]) * jiaquan_k + (points2[index][0] - points2[index-1][0]) * (1 - jiaquan_k)
    y_diff = (points1[index][1] - points1[index-1][1]) * jiaquan_k + (points2[index][1] - points2[index-1][1]) * (1 - jiaquan_k)
    z_diff = (points1[index][2] - points1[index-1][2]) * jiaquan_k + (points2[index][2] - points1[index-1][2]) * (1 - jiaquan_k)
    new_row = np.array([[x_diff], [y_diff], [z_diff]]).reshape(3, 1)
    u_input = np.append(u_input, new_row, axis=1)

vec_xianyan = np.array([[0], [0], [0]]).reshape(3,1)

x0 = points1[0][0]*jiaquan_k + points2[0][0]*(1-jiaquan_k)
y0 = points1[0][1]*jiaquan_k + points2[0][1]*(1-jiaquan_k)
z0 = points1[0][2]*jiaquan_k + points2[0][2]*(1-jiaquan_k)
vec_houyan = np.array([[0], [0], [0]])
#常数矩阵
A = np.eye(3)
B = np.eye(3)
H = np.eye(3)
cov_matrix = np.array([[0.1, 0, 0], [0, 0.1, 0], [0, 0, 0.1]])
cov_matrix2 = np.array([[0.1, 0, 0], [0, 0.1, 0], [0, 0, 0.1]])
cov_matrix3 = np.array([[0.1, 0, 0], [0, 0.1, 0], [0, 0, 0.1]])
mean = np.zeros(3)
Q = np.random.multivariate_normal(mean, cov_matrix)
R = np.random.multivariate_normal(mean, cov_matrix2)
Q = np.diagflat(Q)
R = np.diagflat(R)
#迭代矩阵
P = np.random.multivariate_normal(mean, cov_matrix3)
P = np.diagflat(P)
Pk_xianyan = np.eye(3)
Kk = np.eye(3)

for i in range(1, len(u_input[0])):
    xianyan = (np.dot(A, vec_houyan[:,-1]) + np.dot(B, u_input[:,i])).reshape(3, 1)
    vec_xianyan = np.append(vec_xianyan, xianyan, axis = 1)
    Pk_xianyan = np.dot(np.dot(A, P), np.transpose(A)) + Q

    denominator = np.linalg.inv(np.dot(np.dot(H, Pk_xianyan),np.transpose(H)) + R)
    nominator = np.dot(Pk_xianyan, np.transpose(H))
    Kk = np.dot(nominator, denominator)
    zk = np.array([[(points1[i][0]+points2[i][0])/2.0], [(points1[i][1]+points2[i][1])/2.0], [(points1[i][2]+points2[i][2])/2.0]]).reshape(3, 1)
    houyan = xianyan + np.dot(Kk, zk - np.dot(H, xianyan))
    vec_houyan = np.append(vec_houyan, houyan.reshape(3, 1), axis = 1)
    P = Pk_xianyan - np.dot(np.dot(Kk, H), Pk_xianyan)

fig = plt.figure()
ax2 = fig.add_subplot(111, projection='3d')
x1, y1, z1 = zip(*points1)
x2, y2, z2 = zip(*points2)
ax2.plot(x1, y1, z1, c = 'r', marker = 'o', markersize = 3, label = "peer pos in arkit")
ax2.plot(x2, y2, z2, c = 'b', marker = 'o', markersize = 3, label = "peer pos in ni")
ax2.plot(vec_houyan[0][1:], vec_houyan[1][1:], vec_houyan[2][1:], c = 'g', marker = 'o', markersize = 1, label = "peer pos after kalman filter")

ax2.set_xlabel("X axis")
ax2.set_ylabel("Y axis")
ax2.set_zlabel("Z axis")
ax2.legend()
plt.show()

x3 = vec_houyan[0][1:]
x4 = vec_xianyan[0][1:]
x = [i for i in range(1, len(x3)+1)]
plt.plot(x, x1[:len(x3)], label = "arkit data z")
plt.plot(x, x2[:len(x3)], label = "ni data z")
plt.plot(x, x3, label = "kalman prior")
plt.plot(x, x4, label = "kalman houyan")
plt.legend()
plt.show()

y3 = vec_houyan[1][1:]
y4 = vec_xianyan[1][1:]
y = [i for i in range(1, len(y3)+1)]
plt.plot(y, y1[:len(y3)], label = "arkit data y")
plt.plot(y, y2[:len(y3)], label = "ni data y")
plt.plot(y, y3, label = "kalman prior")
plt.plot(y, y4, label = "kalman houyan")
plt.legend()
plt.show()

z3 = vec_houyan[2][1:]
z4 = vec_xianyan[2][1:]
z = [i for i in range(1, len(z3)+1)]
plt.plot(z, z1[:len(z3)], label = "arkit data z")
plt.plot(z, z3, label = "kalman prior")
plt.plot(z, z4, label = "kalman houyan")
plt.plot(z, z2[:len(z4)], label = "ni data z")
plt.legend()
plt.show()
