# sorts blast output and extracts one mapping per read that has more than 17 nucleotides matching
# written by zhaojie zhang and edited by Kent Riemondy to make user friendly, further edited by Glen Bjerke
#to make more stringent.  Allow 2 mismatches or 1 mismatch and up to 1 gap.  Minimum 19bp and require E < .05.
import sys
def blast_process(filename,output_filename):
    lines=open(filename,'r')
    file=open(output_filename,'w')
    s=set('')
    for line in lines:
        if line.split()[0] in s:
            pass
        else:
            s.add(line.split()[0])
            if int(line.split()[3])<19:
                pass
            elif int(line.split()[4])>2:
                pass
            elif int(line.split()[5])>1:
                pass
            elif int(line.split()[4])>1 and int(line.split()[5])>0:
                pass
            elif float(line.split()[10])>.05:
                 pass
            else:
                file.write(line)


if __name__=="__main__":
    blast_process(sys.argv[1],sys.argv[2])
                
    



