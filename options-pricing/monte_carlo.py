#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Nov 24 11:20:45 2017

@author: lisaeverest
"""

#import pandas as pd
import numpy as np
import math

np.random.seed(1)

def sample(num):
    return np.random.normal(0, 1, num)

def calculate_asset_prices(sample_set,S_t,t,T,r,sigma):
    asset_prices = []
    for epsilon in sample_set:
       asset_price = S_t * math.e ** ((r - (sigma**2)/2)*(T-t) + epsilon*sigma*math.sqrt(T-t))
       asset_prices.append(asset_price)
    return asset_prices

#print(calculate_asset_prices(sample_set,174.67,0,5,.0118,.1786))

def calculate_option_prices(asset_prices,t,T,r,K): #K is the strike price
    option_prices = []
    for asset_price in asset_prices:
        option_price = (math.e ** (-r*(T-t))) * max(0,assetPrice - K)
        option_prices.append(option_price)
    return option_prices

def mean_option_price(num,S_t,t,T,r,sigma,K):
    sample_set = sample(num)
    asset_prices = calculate_asset_prices(sampleSet,S_t,t,T,r,sigma)
    option_prices = calculate_option_prices(assetPrices,t,T,r,K)
    return sum(option_prices)/len(option_prices)

print(mean_option_price(100,.,0,5,.0118,.1786,170))
                        
