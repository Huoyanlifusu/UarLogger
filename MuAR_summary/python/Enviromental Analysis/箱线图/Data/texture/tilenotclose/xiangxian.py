import pandas as pd
import matplotlib.pyplot as plt
import math

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel('AR_NI_DATA_far.xlsx')
data = data[:1300]
ARx, ARy, ARz, NId = [], [], [], []

for num in range(1300):
    if data['FeaturePointNumber'][num] > 10:
        ARx.append(data['ARx'][num])
        ARy.append(data['ARy'][num])
        ARz.append(data['ARz'][num])
        NId.append(data['Distance'][num])


for i in range(len(NId)):
    ARx[i] = math.sqrt(pow(ARx[i], 2) + pow(ARy[i], 2) + pow(ARz[i], 2))

plt.figure()
plt.title('NI & ARKit distance measurement under same context(tile far away)')
labels = 'AR-Distance', 'NI-Distance'
plt.boxplot([ARx, NId], labels = labels, showmeans = True)
plt.show()