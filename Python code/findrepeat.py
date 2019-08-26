# -*- coding: utf-8 -*-
"""
Created on Sun Dec  2 18:32:22 2018

@author: DC
"""
from tqdm import tqdm
import pandas as pd
import os

os.chdir("F:\\758Bdata")

sample = pd.DataFrame()
data = pd.read_csv('dentist new.csv')
text = data['text'].tolist()
text.remove(text[0])
repeat = []

for i in tqdm(range(len(text))):
    temp = text[0]
    text.remove(text[0])
    if temp in text:
        repeat.append(temp)

repeat_pd = pd.DataFrame(repeat, columns=['text'])
repeat_data = pd.merge(repeat_pd, data, how='inner', on='text')
repeat_data.drop(repeat_data.columns[1],axis=1,inplace=True)
