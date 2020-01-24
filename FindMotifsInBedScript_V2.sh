#!/bin/bash
#Script that replaces Kent's motif caller, which gets confused if the same bed area appears more than once.
#This version accepts command line arguments.

#Track errors
mkdir -p log
exec 2> log/$(date +"%H:%M:%S_%m_%d_%Y")motifcalling_terminal_commands.txt 2>&1
set -e
set -u
set -o pipefail

while getopts ":hb:m:f:" opt; do
    case $opt in
    h)
        echo 'This script is designed to motifs in a 6 column bed file, all options required:'
        echo '-b    BedFile to find motifs on'
        echo '-m    File containing list of motifs to find. Use Awk style regex ([^A] to not match A)  MUST BE UPPER CASE!!!!'
        echo '-f    Whole genome fasta input file'
        exit 0
        ;;
    b)  BedFile=$OPTARG
        ;;
    m)  MotifsFile=$OPTARG
        ;;
    f)  FastaFile=$OPTARG
        ;;
    esac
done

#Make temporary tab file
bedtools getfasta -s -tab -name -fi $FastaFile -bed $BedFile -fo $BedFile.28407275.tab

awk '{ print toupper($0) }' $BedFile.28407275.tab > $BedFile.28407275.upper.tab

rm $BedFile.28407275.tab

i=$((1))

while read p; do #Iterates line by line from file at the end
   awk -v pattern="$p" 'BEGIN{print pattern}{print gsub(pattern,"",$2)}' $BedFile.28407275.upper.tab > $BedFile.TempMotif$i.57484temp.Col
   j=$((i-1))
   if (( $i == 1 ))
    then
        cp $BedFile.TempMotif$i.57484temp.Col $BedFile.TempMotif$i.4739249.Col
    fi
   if (( $i > 1 ))
    then
      paste  $BedFile.TempMotif$j.4739249.Col $BedFile.TempMotif$i.57484temp.Col > $BedFile.TempMotif$i.4739249.Col
    fi
   i=$((i+1))
done < $MotifsFile

i=$((i-1))

paste <(echo -e '#Chr\tStart\tEnd\tName\tScore\tStrand'; cat $BedFile) $BedFile.TempMotif$i.4739249.Col

rm $BedFile.28407275.upper.tab
rm $BedFile.TempMotif*.4739249.Col
rm $BedFile.TempMotif*.57484temp.Col