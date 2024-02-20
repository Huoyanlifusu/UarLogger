import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel('AR_NI_DATA.xlsx')
data_len = 2000
data = data[:data_len]
ARd_neu, ARy_neu, ARz_neu = [], [], []
ARd_dim, ARy_dim, ARz_dim = [], [], []

for num in range(data_len):
    if data['AmbientLightIntensity'][num] > 1050 and data['AmbientLightIntensity'][num] < 1200:
        ARd_neu.append(data['ARx'][num])
        ARy_neu.append(data['ARy'][num])
        ARz_neu.append(data['ARz'][num])
    elif data['AmbientLightIntensity'][num] < 1050 and data['AmbientLightIntensity'][num] > 800:
        ARd_dim.append(data['ARx'][num])
        ARy_dim.append(data['ARy'][num])
        ARz_dim.append(data['ARz'][num])


for i in range(len(ARd_neu)):
    ARd_neu[i] = math.sqrt(pow(ARd_neu[i], 2) + pow(ARy_neu[i], 2) + pow(ARz_neu[i], 2)) - 1.542

for i in range(len(ARd_dim)):
    ARd_dim[i] = math.sqrt(pow(ARd_dim[i], 2) + pow(ARy_dim[i], 2) + pow(ARz_dim[i], 2)) - 1.542

rmse_neu = math.sqrt(sum(x * x for x in ARd_neu)/float(len(ARd_neu)))
rmse_dim = math.sqrt(sum(x * x for x in ARd_dim)/float(len(ARd_dim)))
print(rmse_neu, rmse_dim)

plt.figure()
labels = 'Neutral lighitng', 'Dimly Lighting'
f = plt.boxplot([ARd_neu, ARd_dim], vert=True, labels = labels, patch_artist=True)

font1 = {"family" : "Times New Roman", "weight" : "bold", "size" : 20}
c_list = ['#118AD5', '#ffd166']
for box, c in zip(f['boxes'], c_list):  # 对箱线图设置颜色
    # box.set(color=c, linewidth=2)
    box.set(facecolor=c)
plt.ylabel('Ranging Error (m)', font1)
plt.xticks(family = "Times New Roman", size = 20, weight = "bold")
plt.yticks(family = "Times New Roman", size = 20, weight = "bold")
plt.ylim((-0.006, 0.003))
plt.yticks(np.arange(-0.005, 0.003, 0.005))
plt.grid(axis="y", zorder = 0)
plt.show()