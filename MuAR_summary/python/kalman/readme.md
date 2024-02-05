## Useful Files

### AR_NI_DATA.xlsx (hard requirement)

* Original data recorded by UarLogger

### AR_NI_DATA.csv (optional)

* A .csv file of original data, not required in kf_new.py

### kf_new.py (hard requirement)

* Key Idea: kalman filter with __uniform motion__ model
* Parameter Setting:
*  __Processing noise__ diag(0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001)
*  __Measurement noise__ diag(np.var(NIx)*150, np.var(NIy)*150, np.var(NIz)*150, np.var(vx)*3, np.var(vy)*3, np.var(vz)*3)
*  __initial value of state variable__ x0 = [0, 0, 0, 0, 0, 0]
*  __init value of state covariance__ P0 = diag(np.var(NIx), np.var(NIy), np.var(NIz), np.var(vx), np.var(vy), np.var(vz))
* References: { https://www.bzarg.com/p/how-a-kalman-filter-works-in-pictures/ }
