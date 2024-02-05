import pandas as pd
import matplotlib.pyplot as plt
import math

# 同一背景下，比较NI和AR的测距结果

data = pd.read_excel('AR_NI_DATA.xlsx')
data = data[:2000]
ARx, ARy, ARz, NId = data['ARx'], data['ARy'], data['ARz'], data['Distance']

for num in range(2000):
    ARx[num] = math.sqrt(pow(ARx[num], 2) + pow(ARy[num], 2) + pow(ARz[num], 2))

plt.figure()
plt.title('NI & ARKit distance measurement difference with ground truth (meter) in white wall context')
labels = 'AR-Distance', 'NI-Distance'
plt.ylabel("distance difference with ground truth (meter)")
plt.boxplot([ARx, NId], labels = labels, showmeans = True)
plt.grid(b=True, axis="y")
plt.show()