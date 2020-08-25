#This is based on a script by Ryu Izawa
#It takes two arguments, first is the file to operate on and the second is the output file. So run as PythonMotifCollapser.py in.bed out.collapsed
#Assumes input has a header and is a tab separated bed file for columns 1-6, column seven is labeled  Gene and motifs are column 8 to however many.

import pandas as pd  
import sys

df = pd.read_csv(sys.argv[1], sep='\t')
LC = df.shape[1]
by_gene = df.iloc[:, 6:LC+1] 
sum_by_gene = by_gene.groupby('Gene').sum() 
sum_by_gene.to_csv(sys.argv[2], sep='\t')