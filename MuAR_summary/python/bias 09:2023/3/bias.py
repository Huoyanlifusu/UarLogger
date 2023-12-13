import numpy as np
import pandas as pd
import os.path
from openpyxl import load_workbook


father = os.getcwd()
data = pd.read_excel(io=os.path.join(os.getcwd(), 'AR_NI_DATA.xlsx'))
xlspath = os.path.abspath('../bias.xlsx')

ori_data = pd.read_excel(io=xlspath)

ARx, ARy, ARz = [], [], []
light = []
for num in range(1500):
    ARx.append(data['ARx'][num])
    ARy.append(data['ARy'][num])
    ARz.append(data['ARz'][num])
    light.append(data['AmbientLightIntensity'][num])

avg_light = np.mean(light)
print(light)
avg_fp = 2.81 #手动修改
x_gt = -0.441
y_gt = 0.121
z_gt = -1.392

x_bias = np.mean(ARx) - x_gt
y_bias = np.mean(ARy) - y_gt
z_bias = np.mean(ARz) - z_gt

ori_data.loc[len(ori_data)] = [x_bias, y_bias, z_bias, avg_light, avg_fp]

print(ori_data)

# data = {"x_bias":[x_bias], "y_bias":[y_bias], "z_bias":[z_bias], "light":[avg_light], "feature":[avg_fp]}
# data = pd.DataFrame(data)
for sheetName in ori_data.keys():
    ori_data.to_excel(xlspath, sheet_name=sheetName, index=False)