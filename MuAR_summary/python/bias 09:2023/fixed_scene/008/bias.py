import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os.path
import cv2 as cv

i = '1'
orb = cv.ORB_create()
bf = cv.BFMatcher(cv.NORM_HAMMING)
for i in range(100):
    j = i + 1
    if os.path.exists('background_' + str(i) + '.png'):
        if os.path.exists('background_' + str(j) + '.png'):
            if j - i >= 10:
                break
            file1 = 'background_' + str(i) + '.png'
            file2 = 'background_' + str(j) + '.png'
            img1 = cv.imread(file1)
            img2 = cv.imread(file2)

            kp1 = orb.detect(img1)
            kp2 = orb.detect(img2)

            kp1, des1 = orb.compute(img1, kp1)
            kp2, des2 = orb.compute(img2, kp2)

            matches = bf.match(des1, des2)

            min_distance = matches[0].distance
            max_distance = matches[0].distance

            for x in matches:
                if x.distance < min_distance:
                    min_distance = x.distance
                if x.distance > max_distance:
                    max_distance = x.distance
            
            good_match = []

            for x in matches:
                if x.distance <= max(2 * min_distance, 30):
                    good_match.append(x)
            
            outimg = cv.drawMatches(img1, kp1, img2, kp2, good_match, outImg = None)
            cv.imshow("Matcj result", outimg)
            cv.waitKey(0)
        
        else:
            j += 1
