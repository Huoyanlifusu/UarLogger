import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os.path

father = os.getcwd()
xlspath = os.path.abspath('../bias.xlsx')
avg_fp = [164, 76, 160, 109, 155, 137, 167, 105, 163, 93]
x = []
y = []
z = []
decrepted = []
for i in range(1, 11):
    directory = str(i)
    data = pd.read_csv(os.path.join(os.getcwd(), str(i), 'AR_NI_DATA.csv'))

    ARx, ARy, ARz = [], [], []
    x_gt = 0.000
    y_gt = 0.900
    z_gt = 0.000
    for num in range(1000):
        ARx.append(data['ARx'][num]-x_gt)
        ARy.append(data['ARy'][num]-y_gt)
        ARz.append(data['ARz'][num]-z_gt)
    x.append(ARx)
    y.append(ARy)
    z.append(ARz)
    if avg_fp[i-1] > 160 and (abs(np.mean(ARx)) > 0.1 or abs(np.mean(ARy)) > 0.1 or abs(np.mean(ARz)) > 0.1):
        decrepted.append(i-1)
    if avg_fp[i-1] < 100 and (abs(np.mean(ARx)) < 0.01 or abs(np.mean(ARy)) < 0.01 or abs(np.mean(ARz)) < 0.01):
        decrepted.append(i-1)


t = [i for i in range(1000)]
color_lst = ['r', 'g', 'b', 'y', 'c']
for i in range(10):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < 100:
        color = color_lst[0]
    elif avg_fp[i] >= 100 and avg_fp[i] < 120:
        color = color_lst[1]
    elif avg_fp[i] >= 120 and avg_fp[i] < 140:
        color = color_lst[2]
    elif avg_fp[i] >= 140 and avg_fp[i] < 160:
        color = color_lst[3]
    else:
        color = color_lst[4]
    plt.plot(t, x[i], color = color)
plt.xlabel('time')
plt.ylabel('x/m')
plt.show()

for i in range(10):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < 100:
        color = color_lst[0]
    elif avg_fp[i] >= 100 and avg_fp[i] < 120:
        color = color_lst[1]
    elif avg_fp[i] >= 120 and avg_fp[i] < 140:
        color = color_lst[2]
    elif avg_fp[i] >= 140 and avg_fp[i] < 160:
        color = color_lst[3]
    else:
        color = color_lst[4]
        
    plt.plot(t, y[i], color = color)
plt.xlabel('time')
plt.ylabel('y/m')
plt.show()

for i in range(10):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < 100:
        color = color_lst[0]
    elif avg_fp[i] >= 100 and avg_fp[i] < 120:
        color = color_lst[1]
    elif avg_fp[i] >= 120 and avg_fp[i] < 140:
        color = color_lst[2]
    elif avg_fp[i] >= 140 and avg_fp[i] < 160:
        color = color_lst[3]
    else:
        color = color_lst[4]
        
    plt.plot(t, z[i], color = color)
plt.xlabel('time')
plt.ylabel('z/m')
plt.show()