import os.path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def jiayi(s):
    return str(int(s)+1)

folder_path = os.path.abspath('../bias')

sub_folder_path = '1'
file_path = 'AR_NI_DATA.xlsx'
ori_x_data = np.zeros((50,1000))
ori_y_data = np.zeros((50,1000))
ori_z_data = np.zeros((50,1000))


ground_truth_x = [-0.148, -0.321, -0.441, 0.366, 0.363, 0.000, 0.294, 0.294, -0.168, 3.14, 0.900]
ground_truth_x += [0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000]
ground_truth_x += [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.362]
ground_truth_x += [-0.362, -0.362, -0.362, -0.362, -0.362, -0.362, -0.362, -0.362, 0.0, 0.0]
ground_truth_x += [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.362, 0.0, 0.0, 0.0]

ground_truth_y = [-0.195, 0.305, 0.121, -0.600, 0.0, 0.3, -0.6, -0.6, -0.3, 0.0]
ground_truth_y += [-0.6, 0.0, -0.3, 0.6, -1.2, -0.6, 1.2, 0.6, 0.0, 0.6]
ground_truth_y += [0.0, 0.6, 0.6, 0.0, 0.3, -0.9, 0.0, -0.6, -0.9, -0.3]
ground_truth_y += [0.0, -0.6, -0.3, -0.9, -0.9, 0.0 ,0.6, 0.6, 0.0, -0.6]
ground_truth_y += [-0.6, 0.0, 0.0, 0.3, 1.5, -0.3, 0.6, 0.6, -0.6, -0.6]

fp = [9.54, 6.215, 2.81, 51.235, 47.725, 14.94, 17.02, 66.25, 32.71, 3.14]
fp += [3.505, 40.345, 24.34, 1.195, 33.835, 37.88, 90.63, 5.38, 12.54, 8.775]
fp += [14.27, 5.015, 10.445, 16.77, 97.115, 55.12, 5.545, 43.04, 33.695, 121.05]
fp += [22.885, 1.82, 58.55, 16.025, 32.665, 25.8, 110.555, 51.71, 16.76, 4.355]
fp += [39.69, 2.895, 8.81, 18.595, 5.35, 11.97, 5.9, 102.78, 4.015, 1.985]

ground_truth_z = [-1.601, -1.135, -1.392, -1.618, -0.641, -1.800, -1.500, -1.500, -1.200, -3.000]
ground_truth_z += [1.500, -0.600, -0.600, -1.500, -0.600, 1.200, 0.600, -0.900, -0.600, 0.000]
ground_truth_z += [-0.600, 0.000, 0.000, -0.600, -0.900, 0.000, -1.500, 0.000, -0.900, 0.300]
ground_truth_z += [-0.600, 0.300, -0.300, 0.000, 0.000, -0.900, 0.000, 0.000, -0.600, 0.000]
ground_truth_z += [0.000, -1.800, -0.600, -0.600, 0.000, -1.500, -0.300, -0.600, -0.600, 0.600]

for i in range(50):
    xls_path = os.path.join(folder_path, sub_folder_path, file_path)
    sub_folder_path = jiayi(sub_folder_path)
    data = pd.read_excel(io=xls_path)

    for j in range(1000):
        ori_x_data[i][j] = data['ARx'][j] - ground_truth_x[i]
        ori_y_data[i][j] = data['ARy'][j] - ground_truth_y[i]
        ori_z_data[i][j] = data['ARz'][j] - ground_truth_z[i]

t = [i for i in range(1000)]
color_lst = ['r', 'g', 'b', 'y', 'c', 'm', 'k', 'xkcd:orange', 'xkcd:violet', 'xkcd:pink']
# x原始数据
# for j in range(50):
#     color = ''
#     label = ''
#     if fp[j] < 10:
#         color = color_lst[0]
#         label = 'feature less than 10'
#     elif fp[j] >= 10 and fp[j] < 30:
#         color = color_lst[1]
#         label = '10<feature<30'
#     elif fp[j] >= 30 and fp[j] < 50:
#         color = color_lst[2]
#         label = '30<feature<50'
#     else:
#         color = color_lst[3]
#         label = '50<feature'
#     if abs(np.mean(ori_x_data[j])) > 0.3:
#         continue
        
#     plt.plot(t, ori_x_data[j], color = color, label = label)
# plt.xlabel('time interval')
# plt.ylabel('x axis err')
# plt.show()
# for i in range(5):
#     for j in range(10):
#         color = ''
#         label = ''
#         if fp[i*10+j] < 10:
#             color = color_lst[0]
#             label = 'feature less than 10'
#         elif fp[i*10+j] >= 10 and fp[i*10+j] < 30:
#             color = color_lst[1]
#             label = '10<feature<30'
#         elif fp[i*10+j] >= 30 and fp[i*10+j] < 50:
#             color = color_lst[2]
#             label = '30<feature<50'
#         else:
#             color = color_lst[3]
#             label = '50<feature'
#         if abs(np.mean(ori_y_data[i*10+j])) > 0.3:
#             continue
            
#         plt.plot(t, ori_y_data[i*10+j], color = color, label = label)
#     plt.xlabel('time interval')
#     plt.ylabel('y axis err')
#     plt.show()

for j in range(50):
    color = ''
    label = ''
    if fp[j] < 10:
        color = color_lst[0]
        label = 'feature less than 10'
    elif fp[j] >= 10 and fp[j] < 30:
        color = color_lst[1]
        label = '10<feature<30'
    elif fp[j] >= 30 and fp[j] < 50:
        color = color_lst[2]
        label = '30<feature<50'
    else:
        color = color_lst[3]
        label = '50<feature'
    if abs(np.mean(ori_z_data[j])) > 0.3:
        continue
        
    plt.plot(t, ori_z_data[j], color = color, label = label)
plt.xlabel('time interval')
plt.ylabel('z axis err')
plt.show()

