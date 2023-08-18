import pandas as pd
import matplotlib.pyplot as plt
import pip
pip.main(["install", "openpyxl"])

# 同一背景下，比较NI和AR的测距结果

datafile = 'AR_NI_DATA.xlsx'
data = pd.read_excel(datafile)
ARx, NIx = data['ARx'], data['NIx']

plt.figure()
plt.title('NI & ARKit distance measurement under same context(white wall)')
labels = 'AR', 'NI'
plt.boxplot([ARx, NIx], labels = labels)
plt.show()
