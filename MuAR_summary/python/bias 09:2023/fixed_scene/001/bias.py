import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os.path

father = os.getcwd()
xlspath = os.path.abspath('../bias.xlsx')
avg_fp = [33.22, 31.53, 49.46, 56.61, 59.69, 58.145, 57.525, 49.855, 55.16, 72.17]
x = []
y = []
z = []
for i in range(1, 11):
    directory = str(i)
    data = pd.read_csv(os.path.join(os.getcwd(), str(i), 'AR_NI_DATA.csv'))

    ARx, ARy, ARz = [], [], []
    x_gt = 0.000
    y_gt = 0.600
    z_gt = 0.040
    for num in range(1500):
        ARx.append(data['ARx'][num]-x_gt)
        ARy.append(data['ARy'][num]-y_gt)
        ARz.append(data['ARz'][num]-z_gt)
    x.append(ARx)
    y.append(ARy)
    z.append(ARz)


t = [i for i in range(1500)]
color_lst = ['r', 'g', 'b', 'y', 'c']
for i in range(10):
    color = ''
    label = ''
    if avg_fp[i] < 40:
        color = color_lst[0]
        label = 'feature less than 10'
    elif avg_fp[i] >= 40 and avg_fp[i] < 50:
        color = color_lst[1]
        label = '10<feature<30'
    elif avg_fp[i] >= 50 and avg_fp[i] < 60:
        color = color_lst[2]
        label = '30<feature<50'
    else:
        color = color_lst[3]
        label = '50<feature'
        
    plt.plot(t, x[i], color = color, label = label)
plt.xlabel('time')
plt.ylabel('x/m')
plt.show()

for i in range(10):
    color = ''
    label = ''
    if avg_fp[i] < 40:
        color = color_lst[0]
        label = 'feature less than 10'
    elif avg_fp[i] >= 40 and avg_fp[i] < 50:
        color = color_lst[1]
        label = '10<feature<30'
    elif avg_fp[i] >= 50 and avg_fp[i] < 60:
        color = color_lst[2]
        label = '30<feature<50'
    else:
        color = color_lst[3]
        label = '50<feature'
        
    plt.plot(t, y[i], color = color, label = label)
plt.xlabel('time')
plt.ylabel('y/m')
plt.show()

for i in range(10):
    color = ''
    label = ''
    if avg_fp[i] < 40:
        color = color_lst[0]
        label = 'feature less than 10'
    elif avg_fp[i] >= 40 and avg_fp[i] < 50:
        color = color_lst[1]
        label = '10<feature<30'
    elif avg_fp[i] >= 50 and avg_fp[i] < 60:
        color = color_lst[2]
        label = '30<feature<50'
    else:
        color = color_lst[3]
        label = '50<feature'
        
    plt.plot(t, z[i], color = color, label = label)
plt.xlabel('time')
plt.ylabel('z/m')
plt.show()