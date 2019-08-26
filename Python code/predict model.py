# -*- coding: utf-8 -*-
"""
Created on Mon Dec 10 11:43:25 2018

@author: YIFAN DANG
"""

import os
import csv
import pandas as pd
from  tqdm import tqdm
import numpy as np
import gc
gc.collect()
from sklearn import preprocessing
#import matplotlib.pyplot as plt 
#plt.rc("font", size=14)
from sklearn.linear_model import LogisticRegression
from sklearn.cross_validation import train_test_split
#import seaborn as sns
#sns.set(style="white")
#sns.set(style="whitegrid", color_codes=True)



os.chdir("C:/Users/YIFAN DANG/Desktop/Big Data/big data project/big data Yelp/yelp big data set")

TDM=pd.read_csv('mat_new.csv')
#TDM=TDM.dropna()
#print(TDM.shape)
#print(list(TDM.columns))
#TDM.head()

#count how many positive and negative
#TDM['positive'].value_counts()
#sns.countplot(x='positive', data=TDM, palette='hls')
#plt.show()

#spliting data
from sklearn.linear_model import LogisticRegressionCV
from sklearn.model_selection import train_test_split
from matplotlib import pyplot as plt
from sklearn.metrics import confusion_matrix
from sklearn.metrics import accuracy_score
import random
import numpy



#create training and testing vars

y = TDM.positive # define teh target variable (dependent variable) as y
tdm = numpy.array(tdm)
x_train, x_test, y_train, y_test=train_test_split(TDM, y, test_size=0.3, random_state=0)

del x_train(64)

#fit model
clf = LogisticRegressionCV(cv=5).fit(x_train, y_train)
y_pred=clf.predict(x_test)
confusion_matrix(y_test, y_pred)
accuracy_score(y_test, y_pred)


import statsmodels.api as sm
from sklearn import metrics
logit_model=sm.Logit(y_train, x_train)
y_pred=predict(logit_model, x_test)
result=logit_model.fit()
print(result.summary2())

#baseline
sum(y_test)/len(y_test)








