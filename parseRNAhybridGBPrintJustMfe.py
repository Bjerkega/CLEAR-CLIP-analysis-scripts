#Originally by Kent Riemondy (Kriemo) and then I edited it to print out the binding energy (MFE) from RNAhybrid.

#!/usr/bin/env python
from __future__ import print_function
import re
import argparse
import os, shutil, sys
import numpy as np

#This script parses the output from RNAhybrid and gives output of binding as 1 (paired) or 0 (not paired), also reverses the output so that it is shown as 5' -> 3'
#GB note - I modified this script to give a tab delimited list of all the values using Kent's -a ALL option, but I think I broke
# the averaging part of it.
#Change it from printing miRNA name to printing location (First line character8+.  But make it print only that, not a number.

def parse_input(input_file):
  
  line_count = 0 

  tidy_data = []
  
  for line in input_file:
    

    line_count += 1 
    
    #if line_count == 1:
      #Extract out whatever Fasta was named
    #  tidy_data.append(line.strip("\n")[8:])
      
    if line_count == 6:
      #Extract out the Mfe
      tidy_data.append(line.strip("\n")[5:])

    elif line_count == 12:
      #extract out basepaired region, only keeping important part
      tidy_data.append(line.strip("\n")[10:-3])
    
    elif line_count == 13:
      # same as above
      tidy_data.append(line.strip("\n")[10:-3])

    elif line_count == 15:
      line_count = 0
    else:
      continue
  
  tidy_data = [tidy_data[i:i+3] for i in xrange(0, len(tidy_data), 3)]
  
  return tidy_data

def extract_basepairs(input_list):
  # input must be a list of a list like this  [target, basepair line, unbasepair line]
  bases = ["A", "C", "G", "U"]
  output_list = []
  count = 0
  for target in input_list:
    region = target[0]
    # change to list to allow interating over each character of string
    basepairs = list(target[1])
    not_paired = list(target[2])
    
    for index, nucleotide in enumerate(basepairs):
      # if miRNA is not a gap and is paired then assign 1 
      if nucleotide in bases and not_paired[index] == " ":
        not_paired[index] = "1"
     # if miRNA is a gap then do not assign a score
      elif nucleotide == " " and not_paired[index] == " ":
        not_paired[index] = " "
      # if mRNA is not paired, and miRNA is a nucleotide assign a score of 0 
      elif nucleotide == " " and not_paired[index] != " ":
        not_paired[index] = "0" 

    # change list back to string
    not_paired = ''.join(not_paired)
    
    # remove all gaps in miRNA aligment (assigned no score)
    not_paired = not_paired.replace(" ", "")
    # delimate between each value with a comma
    not_paired = '\t'.join(list(not_paired))
    
    #Reverse the string by GB to make it 5' to 3' for list of each mRNA
    not_paired = not_paired[::-1]
    
    output_list.append([count, region, not_paired])
    count = count + 1
  return output_list
    
def average_profiles(binary_binding):
  # input is a list of lists with each list being ["miRNA name, "010101010101"]

  binary_values = [np.fromstring(i[1], dtype = int, sep =",") for i in binary_binding]
  binary_values = np.mean(binary_values, axis = 0)
  binary_values = binary_values.tolist()
  #reverse the list to make 5' to 3'
  binary_values.reverse()
  binary_values = [binary_binding[0][0], binary_values]
  return(binary_values) 
  
if __name__ == '__main__':
  parser=argparse.ArgumentParser(description = """Parse RNAhybrid output to 
    return basepairing probabilities of miRNA basepairing to target mRNAs """)
  parser.add_argument('-i', '--input_file', help = 'input RNAhybrid output', required=True)
  parser.add_argument('-a', '--all', help = 'input "yes" to report all basepairing values, default is to report average', required=False)
  args=parser.parse_args()
  
  input_file = open(args.input_file, ('r'))

  parsed = parse_input(input_file)
    
  binary_binding = extract_basepairs(parsed)
  if args.all:
    for i in binary_binding:
      print(i[1], i[2], sep = '\t')
  else:
    average_binding = average_profiles(binary_binding)
    print('%s\t%s' % (average_binding[0],', '.join(map(str, average_binding[1]))))
      

