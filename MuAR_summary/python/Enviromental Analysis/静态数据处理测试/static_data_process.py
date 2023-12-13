import csv
import matplotlib.pyplot as plt

ar_points = []
ni_points = []
count = 0
with open('ar_data2.csv', newline = '') as csvfile:
    reader = csv.reader(csvfile, delimiter = ',', quotechar = '"')
    for row in reader:
        count += 1
        ar_points.append(row[0].split('+'))
        ni_points.append(row[1].split('+'))

points1 = []
points2 = []
for point in ar_points[1:]:
    x, y, z = float(point[0]), float(point[1]), float(point[2])
    points1.append((x, y, z))
for point in ni_points[1:]:
    x, y, z = float(point[0]), float(point[1]), float(point[2])
    points2.append((x, y, z))
x_ar, y_ar, z_ar = zip(*points1)
x_ni, y_ni, z_ni = zip(*points2)


#x denotes down, y denotes left, z denotes front of the phone
#conforms arkit camera coordinate in portrait mode
#phoneA is iPhone 13
#phoneB is iPhone 12mini
phoneA_ground_x = 1.081
phoneA_height = 0.148
phoneB_ground_x = 0.795
phoneB_height = 0.133
x_groundTruth = (phoneA_ground_x - phoneA_height/2.0) - (phoneB_ground_x - phoneB_height/2.0)

phoneA_wall_y = 0.221
phoneA_width = 0.074
phoneB_wall_y = 0.342
phoneB_width = 0.068
y_groundTruth = (phoneB_wall_y - phoneB_width/2.0) - (phoneA_wall_y - phoneA_width/2.0)

#suppose the thickness of the mobile phone is the same
phoneA_wall_z = -0.967
phoneB_wall_z = -0.335
z_groundTruth = phoneA_wall_z - phoneB_wall_z

x_ar_diff = []
for num in x_ar:
    x_ar_diff.append(num-x_groundTruth)

x_ni_diff = []
for num in x_ni:
    x_ni_diff.append(num-x_groundTruth)

fig = plt.figure()
if len(x_ar) == len(x_ni):
    x = range(len(x_ar))
    plt.plot(x, x_ar_diff, color = 'r', label = 'arkit err with ground truth')
    plt.plot(x, x_ni_diff, color = 'b', label = 'ni err with ground truth')
plt.xlabel("frame")
plt.ylabel("x")
plt.legend()
plt.show()

y_ar_diff = []
for num in y_ar:
    y_ar_diff.append(num-y_groundTruth)

y_ni_diff = []
for num in y_ni:
    y_ni_diff.append(num-y_groundTruth)

if len(y_ar) == len(y_ni):
    y = range(len(y_ar))
    plt.plot(y, y_ar_diff, color = 'r', label = 'arkit err with ground truth')
    plt.plot(y, y_ni_diff, color = 'b', label = 'ni err with ground truth')
plt.xlabel("frame")
plt.ylabel("y")
plt.legend()
plt.show()

z_ar_diff = []
for num in z_ar:
    z_ar_diff.append(num-z_groundTruth)

z_ni_diff = []
for num in z_ni:
    z_ni_diff.append(num-z_groundTruth)

if len(z_ar) == len(z_ni):
    z = range(len(z_ar))
    plt.plot(z, z_ar_diff, color = 'r', label = 'arkit err with ground truth')
    plt.plot(z, z_ni_diff, color = 'b', label = 'ni err with ground truth')
plt.xlabel("frame")
plt.ylabel("z")
plt.legend()
plt.show()