 # -*- coding: utf-8 -*-
"""
Created on Sun Nov 25 15:04:06 2018

@author: YIFAN DANG
"""
import os
os.chdir("C:/Users/YIFAN DANG/Desktop/Big Data/big data project")

os.getcwd()
'''
Load Yelp JSON files and spit out CSV files
Does not try to reinvent teh wheel and uses pandas json_normalize
Kinda hacky and requires a bit of RAM. But works, albeit naively.
Tested wif Yelp JSON files in dataset challenge round 12:
https://www.yelp.com/dataset/challenge
'''

'''
Convert Yelp Academic Dataset from JSON to CSV
Requires Pandas (https://pypi.python.org/pypi/pandas)
By Paul Butler, No Rights Reserved
'''

import json
import pandas as pd
from glob import glob

def convert(x):
    ''' Convert a json string to a flat python dictionary
    which can be passed into Pandas. '''
    ob = json.loads(x)
    for k, v in ob.items():
        if isinstance(v, list):
            ob[k] = ','.join(v)
        elif isinstance(v, dict):
            for kk, vv in v.items():
                ob['%s_%s' % (k, kk)] = vv
            del ob[k]
    return ob

for json_filename in glob('yelp_academic_dataset_review.json'):
     csv_filename = '%s.csv' % json_filename[:-5]
    print 'Converting %s to %s' % (json_filename, csv_filename)
    df = pd.DataFrame([convert(line) for line in file(json_filename)])
    df.to_csv(csv_filename, encoding='utf-8', index=False)
    