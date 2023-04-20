import csv
import numpy as np
import matplotlib.pyplot as plt

def setupDeltaTime(k):
    return timestamps[k] - timestamps[k-1]

def setupF(k):
    delta_time = setupDeltaTime(k)
    mat = [[1, delta_time, 0, 0, 0, 0],
           [0, 1, 0, 0, 0, 0],
           [0, 0, 1, delta_time, 0, 0],
           [0, 0, 0, 1, 0, 0],
           [0, 0, 0, 0, 1, delta_time],
           [0, 0, 0, 0, 0, 1]]
    return np.array(mat)

def setupB(k):
    delta_time = setupDeltaTime(k)
    mat = [[0.5 * delta_time * delta_time, 0, 0],
           [delta_time, 0, 0],
           [0, 0.5 * delta_time * delta_time, 0],
           [0, delta_time, 0],
           [0, 0, 0.5 * delta_time * delta_time],
           [0, 0, delta_time]]
    return np.array(mat)

def IMUpreintegration(k):
    global cur
    origin = timestamps[k-1]
    timestamp = timestamps[k]
    accx, accy, accz = 0, 0, 0
    while cur < len(acc) and acc[cur][0] < timestamp:
        accx += acc[cur][1] * (acc[cur][0]-acc[cur-1][0])
        accy += acc[cur][2] * (acc[cur][0]-acc[cur-1][0])
        accz += acc[cur][3] * (acc[cur][0]-acc[cur-1][0])
        cur += 1
    accx/=(acc[cur-1][0]-origin)
    accy/=(acc[cur-1][0]-origin)
    accz/=(acc[cur-1][0]-origin)
    return np.array([accx, accy, accz]).reshape(3,1)

def setupC(k):
    delta_time = setupDeltaTime(k)
    mat = [[0, delta_time, 0, 0, 0, 0],
           [0, 0, 0, delta_time, 0, 0],
           [0, 0, 0, 0, 0, delta_time],
           [1, 0, 0, 0, 0, 0],
           [0, 0, 1, 0, 0, 0],
           [0, 0, 0, 0, 1, 0]]
    return np.array(mat)

def setupy(k):
    ox = vio_points[k][0]
    oy = vio_points[k][1]
    oz = vio_points[k][2]
    # if k >= 20 and k < len(ni_points)-20:
    #     for i in range(k-20, k+20):
    #         ox += ni_points[i][0]
    #         oy += ni_points[i][1]
    #         oz += ni_points[i][2]
    #     ox /= 41
    #     oy /= 41
    #     oz /= 41
    y = [cam_move[k][0]-cam_move[k-1][0], cam_move[k][1]-cam_move[k-1][1], cam_move[k][2]-cam_move[k-1][2], ox, oy, oz]
    return np.array(y).reshape(6, 1)

vio_points = []
ni_points = []
cam_move = []
timestamps = []
with open('ar_data2.csv', newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    next(reader)
    for row in reader:
        vio_points.append(list(map(float, row[0].split('+'))))
        ni_points.append(list(map(float, row[1].split('+'))))
        cam_move.append(list(map(float, row[2].split('+'))))
        timestamps.append(float(row[5]))

acc = []
with open("Accel.txt") as txtfile:
    for line in txtfile:
        acc.append(list(map(float, line.split(","))))

# delta_px, v_x, delta_py, v_y, delta_pz, v_z
xk = np.array([ni_points[0][0],0,ni_points[0][1],0,ni_points[0][2],0]).reshape(6,1)
Pk = np.array([[10,0,0,0,0,0],
               [0,100,0,0,0,0],
               [0,0,10,0,0,0],
               [0,0,0,100,0,0],
               [0,0,0,0,10,0],
               [0,0,0,0,0,100]])
# noise
noise_w = np.random.normal(loc=0, scale=5, size=(6, 6))
Q = np.identity(6)
noise_v = np.random.normal(loc=0, scale=0.5, size=(6, 6))
R = np.cov(noise_v)
# iteration counts
frames = len(ni_points)
cur = 1
# constant
I = np.identity(6)
# lst
betas = [xk]
for k in range(1, frames):
    Fk = setupF(k)
    Bk = setupB(k)
    u = IMUpreintegration(k)
    xk_prior = np.dot(Fk, xk) + np.dot(Bk, u)
    Pk_prior = np.dot(np.dot(Fk, Pk), np.transpose(Fk)) + Q
    Ck = setupC(k)
    Kk = np.dot(np.dot(Pk_prior, np.transpose(Ck)), np.linalg.inv(np.dot(np.dot(Ck, Pk_prior), np.transpose(Ck)) + R))
    Pk = np.dot(I - np.dot(Kk, Ck), Pk_prior)
    y = setupy(k)
    xk = xk_prior + np.dot(Kk, y - np.dot(Ck, xk_prior))
    betas.append(xk)

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

vx = []
vy = []
vz = []

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
for xk in betas:
    kalman_diff_x.append(xk[0] - x_groundTruth)
    kalman_diff_y.append(xk[2] - y_groundTruth)
    kalman_diff_z.append(xk[4] - z_groundTruth)
    vx.append(xk[1])
    vy.append(xk[3])
    vz.append(xk[5])

t1 = [timestamps[i] for i in range(frames)]
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
# plt.plot(t1, vy, color = 'g', label = 'y velocity prediction')
plt.xlabel('time interval')
plt.ylabel('y axis')
plt.legend()
plt.show()

plt.plot(t1, ni_diff_z, color = 'r', label = 'ni err with gt')
plt.plot(t1, kalman_diff_z, color = 'b', label = 'kalman err with gt')
plt.plot(t1, vio_diff_z, color = 'g', label = 'vio err with gt')
# plt.plot(t1, vz, color = 'g', label = 'z velocity prediction')
plt.xlabel('time interval')
plt.ylabel('z axis')
plt.legend()
plt.show()