#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov 24 11:20:45 2017

@author: lisazhu
"""

#import pandas as pd
import numpy as np
import math

np.random.seed(1)

def sample(num):
    return np.random.normal(0, 1, num)

def calculateAssetPrices(sampleSet,S_t,t,T,r,sigma):
    assetPrices = []
    for epsilon in sampleSet:
       assetPrice = S_t * math.e ** ((r - (sigma**2)/2)*(T-t) + epsilon*sigma*math.sqrt(T-t))
       assetPrices.append(assetPrice)
    return assetPrices

#print(calculateAssetPrices(sampleSet,174.67,0,5,.0118,.1786))

def calculateOptionPrices(assetPrices,t,T,r,K): #K is the strike price
    optionPrices = []
    for assetPrice in assetPrices:
        optionPrice = (math.e ** (-r*(T-t))) * max(0,assetPrice - K)
        optionPrices.append(optionPrice)
    return optionPrices

def meanOptionPrice(num,S_t,t,T,r,sigma,K):
    sampleSet = sample(num)
    assetPrices = calculateAssetPrices(sampleSet,S_t,t,T,r,sigma)
    optionPrices = calculateOptionPrices(assetPrices,t,T,r,K)
    return sum(optionPrices)/len(optionPrices)

print(meanOptionPrice(100,.,0,5,.0118,.1786,170))
                        