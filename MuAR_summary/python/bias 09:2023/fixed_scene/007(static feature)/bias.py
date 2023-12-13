import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os.path
import cv2 as cv

father = os.getcwd()
fp = []
file_num = 5
sampling_time = 1500
x = []
y = []
z = []
x_gt = 0.000
y_gt = 1.800
z_gt = 0.000
decrepted = 0
orb = cv.ORB_create(nfeatures = 4000)
feature_breakpoint = [500, 1000, 1500, 2000]
for i in range(1, file_num+1):
    directory = str(i)
    if os.path.exists(directory+'/AR_NI_DATA.csv') and os.path.exists(directory+'/background.png'):
        data = pd.read_csv(os.path.join(os.getcwd(), directory, 'AR_NI_DATA.csv'))
        img = cv.imread(directory+'/background.png', cv.IMREAD_GRAYSCALE)
        ARx, ARy, ARz = [], [], []
        for num in range(sampling_time):
            ARx.append(data['ARx'][num]-x_gt)
            ARy.append(data['ARy'][num]-y_gt)
            ARz.append(data['ARz'][num]-z_gt)
        x.append(ARx)
        y.append(ARy)
        z.append(ARz)
        kp = orb.detect(img)
        fp.append(len(kp))
    else:
        decrepted += 1
        continue
    # if avg_fp[i-1] > feature_breakpoint[3] and (abs(np.mean(ARx)) > 0.05 or abs(np.mean(ARy)) > 0.05 or abs(np.mean(ARz)) > 0.05):
    #     decrepted.append(i-1)
    # if avg_fp[i-1] < feature_breakpoint[0] and (abs(np.mean(ARx)) < 0.02 or abs(np.mean(ARy)) < 0.02 or abs(np.mean(ARz)) < 0.02):
    #     decrepted.append(i-1)
print(fp)

t = [i for i in range(sampling_time)]
color_lst = ['r', 'g', 'b', 'y', 'c']
for i in range(file_num-decrepted):
    color = ''
    if fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif fp[i] >= feature_breakpoint[0] and fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif fp[i] >= feature_breakpoint[1] and fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif fp[i] >= feature_breakpoint[2] and fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    plt.plot(t, x[i], color = color)
plt.xlabel('time')
plt.ylabel('x/m')
plt.show()

for i in range(file_num-decrepted):
    color = ''
    if fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif fp[i] >= feature_breakpoint[0] and fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif fp[i] >= feature_breakpoint[1] and fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif fp[i] >= feature_breakpoint[2] and fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    plt.plot(t, y[i], color = color)
plt.xlabel('time')
plt.ylabel('y/m')
plt.show()

for i in range(file_num-decrepted):
    color = ''
    if fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif fp[i] >= feature_breakpoint[0] and fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif fp[i] >= feature_breakpoint[1] and fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif fp[i] >= feature_breakpoint[2] and fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    plt.plot(t, z[i], color = color)
plt.xlabel('time')
plt.ylabel('z/m')
plt.show()