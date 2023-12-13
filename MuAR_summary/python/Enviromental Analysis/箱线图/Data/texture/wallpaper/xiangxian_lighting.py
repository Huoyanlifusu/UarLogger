import pandas as pd
import matplotlib.pyplot as plt
import math

data = pd.read_excel('AR_NI_DATA.xlsx')
data_len = 2000
data = data[:data_len]
ARd_neu, ARy_neu, ARz_neu = [], [], []
ARd_dim, ARy_dim, ARz_dim = [], [], []

for num in range(data_len):
    if data['AmbientLightIntensity'][num] > 1050 and data['AmbientLightIntensity'][num] < 1200:
        ARd_neu.append(data['NIx'][num])
        ARy_neu.append(data['NIy'][num])
        ARz_neu.append(data['NIz'][num])
    elif data['AmbientLightIntensity'][num] < 1050 and data['AmbientLightIntensity'][num] > 800:
        ARd_dim.append(data['NIx'][num])
        ARy_dim.append(data['NIy'][num])
        ARz_dim.append(data['NIz'][num])



for i in range(len(ARd_neu)):
    ARd_neu[i] = math.sqrt(pow(ARd_neu[i], 2) + pow(ARy_neu[i], 2) + pow(ARz_neu[i], 2))

for i in range(len(ARd_dim)):
    ARd_dim[i] = math.sqrt(pow(ARd_dim[i], 2) + pow(ARy_dim[i], 2) + pow(ARz_dim[i], 2))

plt.figure()
plt.title('UWB ranging under same context(wallpaper)')
labels = 'Neutral lighitng(1050-1200 lumen)', 'Dimly Lighting(800-1050 lumen)'
plt.boxplot([ARd_neu, ARd_dim], labels = labels, showmeans = True)
plt.show()