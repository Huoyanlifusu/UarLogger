import numpy as np
def dlt(p1, p2):
    A = []
    for pair in zip(p1, p2):
        M = pair[0]
        M_p = pair[1]
        # x, y, z是特征点的三维坐标
        x = M[0]
        y = M[1]
        z = M[2]
        # u, v是像素点的二维坐标
        u = M_p[0]
        v = M_p[1]
        # A矩阵的构建，用于SVD分解
        row1 = [x, y, z, 1, 0, 0, 0, 0, -u*x, -u*y, -u*z, -u]
        row2 = [0, 0, 0, 0, x, y, z, 1, -v*x, -v*y, -v*z, -v]
        A.append(row1)
        A.append(row2)

    # 分解转置后得到V矩阵
    U, S, VT = np.linalg.svd(A)
    V = np.transpose(VT)
    # V的最后一列是m, 也就是投影矩阵M的向量表示
    V = V[:,-1]
    # M is projection matrix
    M = np.array(V).reshape(3,4)
    # M前三列为内参乘仿射矩阵的旋转分量, K*R 第四列为K*t
    KR = M[:,:3]
    Kt = M[:,3]
    # QR分解 R^-1 * K^-1 = (KR)^-1, R是正交矩阵, K是内参上三角矩阵
    Rinv, Kinv = np.linalg.qr(np.linalg.inv(KR))
    KDLT = np.linalg.inv(Kinv)
    t = np.matmul(Kinv, Kt)
    # ARKit提取的内参
    KARKit = np.array([[1533.3826, 0.0, 968.0966], [0.0, 1533.3826, 726.8793], [0, 0, 1.0]])
    print("intrinsic mat from DLT".center(40,"*"))
    print(KDLT/KDLT[-1,-1])
    print("intrinsic matrix from ARKit".center(40,"*"))
    print(KARKit)
    print("\n")
    # 用标定得到的内参和投影矩阵计算
    R = np.matmul(Kinv, KR)
    t = np.matmul(Kinv, Kt)
    return R, t

def DLT():
    # Point file
    pF = open("PointCloud.txt")
    lines = pF.readlines()
    isPixel = False
    # Feature Points
    fP = []
    # Pixel Points
    pP = []
    for line in lines:
        if isPixel:
            pP.append([float(x) for x in line.split(",")])
            isPixel = False
        else:
            fP.append([float(x) for x in line.split(",")])
            isPixel = True
    
    tF = open("camTrans.txt")
    lines2 = tF.readlines()
    # transformList
    tL = []
    for line in lines2:
        tL.append([float(t) for t in line.split(",")])
    # Known 3D coordinates
    while fP and pP:
        xyz = []
        uv = []
        for _ in range(6):
            xyz.append(fP.pop())
            uv.append(pP.pop())
        # transform from DLT
        R, t = dlt(xyz, uv)
        T = Tform(R, t)
        # transform from arkit
        tARKit = np.asarray(tL.pop()).reshape(4,4)
        print("dlt result".center(30, "="))
        print(T)
        print("ground truth".center(30,"="))
        print(tARKit)
        print("\n")
def Tform(R, t):
    return np.array([[R[0,0],R[0,1],R[0,2],t[0]],[R[1,0],R[1,1],R[1,2],t[1]],[R[2,0],R[2,1],R[2,2],t[2]]])

if __name__ == "__main__":
    DLT()