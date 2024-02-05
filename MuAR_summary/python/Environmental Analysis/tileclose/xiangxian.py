import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import os.path

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
data = data[:1900]
ARx, ARy, ARz, NId = [], [], [], []
ARd = []
for num in range(1900):
    if data['FeaturePointNumber'][num] > 15:
        ARx.append(data['ARx'][num])
        ARy.append(data['ARy'][num])
        ARz.append(data['ARz'][num])
        ARd.append(math.sqrt(ARx[-1]**2+ARy[-1]**2+ARz[-1]**2)-0.4)
        NId.append(data['Distance'][num]-0.4)


for i in range(len(NId)):
    ARx[i] = math.sqrt(pow(ARx[i], 2) + pow(ARy[i], 2) + pow(ARz[i], 2)) - 0.4

rmse_ar = math.sqrt(sum(x * x for x in ARd)/float(len(ARd)))
rmse_ni = math.sqrt(sum(x * x for x in NId)/float(len(NId)))
print(rmse_ar, rmse_ni)

plt.figure()
labels = 'VIO', 'UWB'
f = plt.boxplot([ARx, NId], vert=True, labels = labels, patch_artist=True)
font1 = {"family" : "Times New Roman", "weight" : "bold", "size" : 20}
c_list = ['#118AD5', '#ffd166']
for box, c in zip(f['boxes'], c_list):  # 对箱线图设置颜色
    # box.set(color=c, linewidth=2)
    box.set(facecolor=c)
plt.ylabel('Ranging Error (m)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.19, 0.41))
plt.yticks(np.arange(-0.1, 0.31, 0.1))
plt.grid(axis="y", zorder = 0)
plt.show()