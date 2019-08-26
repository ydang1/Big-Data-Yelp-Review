import os
import csv
import pandas as pd
from  tqdm import tqdm

os.chdir("C:/Users/YIFAN DANG/Desktop/Big Data/big data project/big data Yelp/yelp big data set")

#os.getcwd()
csv_data=pd.read_csv('yelp_academic_dataset_review.csv')
#dentist=pd.read_csv('business_id_2.csv')
#sample=pd.DataFrame()
#sample=sample.append(pd.merge(dentist, csv_data, how='inner', on='business_id'))
#sample.to_csv('dentist.csv')

sample = pd.DataFrame()
data = pd.read_csv('dentist.csv')
data=data.drop(columns=['Unnamed: 0'])
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

csv_data=csv_data.replace('\r\n','')
sample_data=csv_data.head(100000)
sample_data.to_csv('sample_data.txt', sep='\t')
