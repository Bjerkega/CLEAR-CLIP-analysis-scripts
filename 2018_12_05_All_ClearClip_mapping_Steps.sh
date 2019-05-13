# Try and write a big script to do all the CLEAR-CLIP steps.

#This is going to require a file with the list of the base file names.  (No extension).  Called: FilesToBeClearClipped.txt

#Also modify here the number of processors to use, i.e. the number of files you're working on:
Cores=3

# initialize log directory and track terminal output and commands
mkdir -p log
exec 1> log/$(date +"%m_%d_%Y")miRNA_mapping_terminal_commands.txt 2>&1
set -x
set -u
set -e
set -o pipefail

echo Working with $Cores processors

#Fastq filter as part of the CIMS package doesn't work any more, so use the Fastx toolkit one.
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'fastq_quality_filter -Q33 -q 30 -i {}.fastq -o {.}.qualfiltered.fastq'

#Have to add a separate step to convert to Fasta.
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'fastq_to_fasta -Q33 -i {}.qualfiltered.fastq -o {.}.qualfiltered.fasta'

#Remove the quality filtered files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm {}.qualfiltered.fastq'

cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'cutadapt -a 3pAdapter=TGGAATTCTCGGGTGCCAAGG \
-b 5pAdapter=CTACAGTCCGACGATC {}.qualfiltered.fasta > {.}.qualfiltered.cutadapt.fasta'

ls *.fasta | parallel -v -j $Cores \
'grep -c -e ">" {}'

#Remove the quality filtered fasta files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm {}.qualfiltered.fasta'

#Make this step 19bp, because using my blast processor now
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'fastx_trimmer -f 3 -i {}.qualfiltered.cutadapt.fasta -Q33 | \
fastx_trimmer -t 2 -m 19 -i - -Q33 > {.}.qualfiltered.cutadapt.trimmed.fasta'

#Don't remove the cutadapt files, need those for Clash mapping

# run blast in parallel 
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'/Users/labadmin/Desktop/Software/ncbi-blast-2.7.1+/bin/blastn \
-db /Users/labadmin/Desktop/Software/ncbi-blast-2.7.1+/mmu-mature.simple.fasta  \
-query {}.qualfiltered.cutadapt.trimmed.fasta -out {.}.qualfiltered.cutadapt.trimmed.blast -word_size 11 -outfmt 6 -strand plus'

#Just use my more stringent blast filterer
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'python /Volumes/Data3/Glen/GBScripts/blast_process_GBstringent.py {}.qualfiltered.cutadapt.trimmed.blast {.}.qualfiltered.cutadapt.trimmed.filtered'

#We lost the previous miRNA counter, but that should be easy to replace.
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'cut -f 2 {}.qualfiltered.cutadapt.trimmed.filtered | sort | uniq -c > {.}.qualfiltered.cutadapt.trimmed.filtered.miRNAcount'

echo "Done with Blast mapping of miRNAs" | mail -s "miRNAs_Have_Been_Blast_mapped!_Now_On_To_CLEAR-CLIP" glen.bjerke@Colorado.EDU

Mkdir -p ClashMapping

#Collapse exact duplicate sequencing reads
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'perl /Users/labadmin/Desktop/Software/ctk-1.1.2/fasta2collapse.pl -v {}.qualfiltered.cutadapt.fasta ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.fasta'

#Now trim just 3' end and keep only reads 43+ bp (Minimum 19 for miRNA and 20 for Novoalign, 4bp for barcode)
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'fastx_trimmer -t 2 -m 43 -i ./ClashMapping/{}.qualfiltered.cutadapt.nodups.fasta -Q33 > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.fasta'

#Use Darnell lab barcoder
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'perl /Users/labadmin/Desktop/Software/ctk-1.1.2/stripBarcode.pl -len 4 -format fasta ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.fasta ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.fasta'

#Remove trimmed reads
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.fasta'

# run blast in parallel
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'/Users/labadmin/Desktop/Software/ncbi-blast-2.7.1+/bin/blastn \
-db /Users/labadmin/Desktop/Software/ncbi-blast-2.7.1+/mmu-mature.simple.fasta  \
-query ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.fasta -out ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.blast -word_size 11 -outfmt 6 -strand plus'

#More stringent blast filterer on Clash reads
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'python /Volumes/Data3/Glen/GBScripts/blast_process_GBstringent.py ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.blast ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered'

#Make tabular versions of the input, barcoded files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'fasta_formatter -t -i ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.fasta -o ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.tab'

#Sort the files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'sort ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort'

cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'sort ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.tab > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.sort.tab'

#Now join the two files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'join ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.sort.tab > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge'

#Remove the tab files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.tab'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.sort.tab'

#Make a file with the sequence 3prime of the miRNA added
#Need to make a variable for the awk body, this is my ClashTrimmer code.
awkbody3prime='{start=$8; fulllength=length($13);print $0,"\t",substr($13, start+1, fulllength-(start));}'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
"awk '$awkbody3prime' ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.3prime"

#Pull out 3prime sequences of 20-24 base pairs and 25+ base pairs and make them into fastas.
awk20to24='length($14) >= 20 && length($14) <= 24 {print">"$1"."$2"\n"$14}'
awk25Plus='length($14) >=25 {print">"$1"."$2"\n"$14}'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
"awk '$awk20to24' ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.3prime > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.fa"
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
"awk '$awk25Plus' ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.3prime > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.fa"

#Remove the 3 prime file
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'rm ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.3prime'

#Novoalign both sets
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'novoalign -s 1 -t 85 -d ~/Desktop/Software/Mus_musculus/UCSC/mm10/Sequence/WholeGenomeFasta/genome.nix -f ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.fa -F FA -l 25 -r None > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.novoalign'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'novoalign -s 1 -t 1 -d ~/Desktop/Software/Mus_musculus/UCSC/mm10/Sequence/WholeGenomeFasta/genome.nix -f ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.fa -F FA -l 20 -r None > ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.novoalign'

#Step 95, make mutation file and convert to bed.
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'perl /Users/labadmin/Desktop/Software/ctk-1.1.2/novoalign2bed.pl -v --mismatch-file ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.novoalign.mutation.txt ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.novoalign ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.novoalign.tag.bed'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'perl /Users/labadmin/Desktop/Software/ctk-1.1.2/novoalign2bed.pl -v --mismatch-file ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.novoalign.mutation.txt ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.novoalign ./ClashMapping/{.}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.novoalign.tag.bed'

#Combine bed files
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
'cat ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.20to24.novoalign.tag.bed ./ClashMapping/{}.qualfiltered.cutadapt.nodups.trimmed.barcoded.filtered.sort.merge.25Plus.novoalign.tag.bed > ./ClashMapping/{.}.ClearClipReads.All.tag.bed'

#Collapse the reads based on location and barcode.
#Need the awk bodies as variables
Gsub1='gsub(/\./, "\t")'
Gsub2='gsub(/\#/, "\t")'
AwkPrint='{print$1"\t"$2"\t"$3"\t"$4"#"$5"#"$6"\t"$7"\t"$9}'
cat FilesToBeClearClipped.txt | parallel -v -j $Cores \
"awk '$Gsub1' ./ClashMapping/{}.ClearClipReads.All.tag.bed | awk '$Gsub2' | sort -k1,1 -k2,2n -k3,3n -k6,6 -k7,7 -k9,9 -u | awk '$AwkPrint' > ./ClashMapping/{.}.ClearClipReads.All.tag.collapsed.bed"

echo "Done with CLEAR-CLIP mapping!" | mail -s "CLEAR-CLIP_Mapped!!!" glen.bjerke@Colorado.EDU
