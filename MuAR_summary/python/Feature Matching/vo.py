import cv2 as cv
import numpy as np
import matplotlib.pyplot as plt
from skimage.measure import ransac
from skimage.transform import EssentialMatrixTransform


#some functions
K = np.array([1540.0, 0.0, 0.0, 0.0, 1540.0, 0.0, 971.0, 725.0, 1.0]).reshape((3, 3)).T

def normalize(pts):
    Kinv = np.linalg.inv(K)

    add_ones = lambda x: np.concatenate([x, np.ones((x.shape[0], 1))], axis=1)

    norm_pts = np.dot(Kinv, add_ones(pts).T).T[:, 0:2]

    return norm_pts

img1 = cv.imread("img1.jpg", cv.IMREAD_GRAYSCALE)
img2 = cv.imread("img2.jpg", cv.IMREAD_GRAYSCALE)

orb = cv.ORB_create()

kp1, des1 = orb.detectAndCompute(img1, None)
kp2, des2 = orb.detectAndCompute(img2, None)

# print(len(des1))
# print(len(des1[0]))


bf = cv.BFMatcher(cv.NORM_HAMMING)

matches = bf.knnMatch(des1, des2, k=2)

match = bf.match(des1, des2)

goodmatches = []
pts = []

for i, (m, n) in enumerate(matches):
    if m.distance < 0.8 * n.distance:
        goodmatches.append(m)

        p1 = kp1[m.queryIdx].pt
        p2 = kp2[m.trainIdx].pt

        pts.append((p1, p2))

# img = cv.drawKeypoints(img1, kp1, None, color=(255,0,0))
# plt.imshow(img)
# plt.show()

# img3 = cv.drawMatches(img1,kp1,img2,kp2,goodmatches,outImg=None,flags=cv.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)
# plt.imshow(img3)
# plt.show()

def findEssentialMat(match_pts):
    match_pts = np.array(match_pts)

    norm_curr_kps = normalize(match_pts[:, 0])
    norm_last_kps = normalize(match_pts[:, 1])

    model, inliers = ransac((norm_curr_kps, norm_last_kps),
                            EssentialMatrixTransform,
                            min_samples=8,              # at least 8 points
                            residual_threshold=0.005,
                            max_trials=200)
    
    return model.params



# OpenCV ransac
pts = np.array(pts)

pts1 = pts[:, 0]
pts2 = pts[:, 1]

em, mask = cv.findEssentialMat(pts1, pts2, K)
num, R, t, mask = cv.recoverPose(em, pts1, pts2, K)

print(em)

# scikit-image ransac
# em = findEssentialMat(pts)
print(R, t)
