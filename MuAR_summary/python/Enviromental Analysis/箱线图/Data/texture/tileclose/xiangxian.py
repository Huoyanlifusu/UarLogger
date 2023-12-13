import pandas as pd
import matplotlib.pyplot as plt
import math
import os.path

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel(io=os.path.abspath('AR_NI_DATA.xlsx'))
data = data[:1900]
ARx, ARy, ARz, NId = [], [], [], []

for num in range(1900):
    if data['FeaturePointNumber'][num] > 15:
        ARx.append(data['ARx'][num])
        ARy.append(data['ARy'][num])
        ARz.append(data['ARz'][num])
        NId.append(data['Distance'][num])


for i in range(len(NId)):
    ARx[i] = math.sqrt(pow(ARx[i], 2) + pow(ARy[i], 2) + pow(ARz[i], 2))

plt.figure()
plt.title('NI & ARKit distance measurement under same context(white wall)')
labels = 'AR-Distance', 'NI-Distance'
plt.boxplot([ARx, NId], labels = labels, showmeans = True)
plt.show()