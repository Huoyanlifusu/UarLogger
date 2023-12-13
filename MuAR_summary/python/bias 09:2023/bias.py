import pandas as pd
import matplotlib.pyplot as plt


data = pd.read_excel('bias.xlsx')

x_bias = data['x_bias']
y_bias = data['y_bias']
z_bias = data['z_bias']
feature = data['feature']
lighting = data['light']

plt.scatter(x_bias, feature)
plt.title('x_bias-feature scatter')
plt.xlabel('x/m')
plt.ylabel('feature/avg num')
plt.show()

plt.scatter(y_bias, feature)
plt.title('y_bias-feature scatter')
plt.xlabel('y/m')
plt.ylabel('feature/avg num')
plt.show()

plt.scatter(z_bias, feature)
plt.title('z_bias-feature scatter')
plt.xlabel('z/m')
plt.ylabel('feature/avg num')
plt.show()

plt.scatter(x_bias, lighting)
plt.title('x_bias-lighting scatter')
plt.xlabel('x/m')
plt.ylabel('lighting/lumens')
plt.show()

plt.scatter(y_bias, lighting)
plt.title('y_bias-lighting scatter')
plt.xlabel('y/m')
plt.ylabel('lighting/lumens')
plt.show()

plt.scatter(z_bias, lighting)
plt.title('z_bias-lighting scatter')
plt.xlabel('z/m')
plt.ylabel('lighting/lumens')
plt.show()