import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os.path

father = os.getcwd()
xlspath = os.path.abspath('../bias.xlsx')
avg_fp = [83, 107, 72, 56, 114, 115, 69, 118, 23]
file_num = 9
sampling_time = 1500
x = []
y = []
z = []
x_gt = 0.000
y_gt = 0.600
z_gt = 0.000
decrepted = []
feature_breakpoint = [70, 80, 90, 100]
for i in range(1, file_num+1):
    directory = str(i)
    data = pd.read_csv(os.path.join(os.getcwd(), str(i), 'AR_NI_DATA.csv'))

    ARx, ARy, ARz = [], [], []
    for num in range(sampling_time):
        ARx.append(data['ARx'][num]-x_gt)
        ARy.append(data['ARy'][num]-y_gt)
        ARz.append(data['ARz'][num]-z_gt)
    x.append(ARx)
    y.append(ARy)
    z.append(ARz)
    # if avg_fp[i-1] > feature_breakpoint[3] and (abs(np.mean(ARx)) > 0.05 or abs(np.mean(ARy)) > 0.05 or abs(np.mean(ARz)) > 0.05):
    #     decrepted.append(i-1)
    # if avg_fp[i-1] < feature_breakpoint[0] and (abs(np.mean(ARx)) < 0.02 or abs(np.mean(ARy)) < 0.02 or abs(np.mean(ARz)) < 0.02):
    #     decrepted.append(i-1)


t = [i for i in range(sampling_time)]
color_lst = ['r', 'g', 'b', 'y', 'c']
for i in range(file_num):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif avg_fp[i] >= feature_breakpoint[0] and avg_fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif avg_fp[i] >= feature_breakpoint[1] and avg_fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif avg_fp[i] >= feature_breakpoint[2] and avg_fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    if i == 8:
        color = 'k'
    plt.plot(t, x[i], color = color)
plt.xlabel('time')
plt.ylabel('x/m')
plt.show()

for i in range(file_num):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif avg_fp[i] >= feature_breakpoint[0] and avg_fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif avg_fp[i] >= feature_breakpoint[1] and avg_fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif avg_fp[i] >= feature_breakpoint[2] and avg_fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    if i == 8:
        color = 'k'
    plt.plot(t, y[i], color = color)
plt.xlabel('time')
plt.ylabel('y/m')
plt.show()

for i in range(file_num):
    if i in decrepted:
        continue
    color = ''
    if avg_fp[i] < feature_breakpoint[0]:
        color = color_lst[0]
    elif avg_fp[i] >= feature_breakpoint[0] and avg_fp[i] < feature_breakpoint[1]:
        color = color_lst[1]
    elif avg_fp[i] >= feature_breakpoint[1] and avg_fp[i] < feature_breakpoint[2]:
        color = color_lst[2]
    elif avg_fp[i] >= feature_breakpoint[2] and avg_fp[i] < feature_breakpoint[3]:
        color = color_lst[3]
    else:
        color = color_lst[4]
    if i == 8:
        color = 'k'
    plt.plot(t, z[i], color = color)
plt.xlabel('time')
plt.ylabel('z/m')
plt.show()