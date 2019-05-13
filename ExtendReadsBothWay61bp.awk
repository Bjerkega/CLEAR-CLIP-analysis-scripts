#! /usr/bin/awk -f
#A program that extends reads in a bed file to 60 or 61bp by adding an even number of bp in each direction.
#I want this to work on a file with 6 columns
#Make it not print less than 0 for column 2.
{
if ($3-$2<59) {
    D = 59-($3-$2);
    if (D % 2 == 1) {
        D = D + 1;
    }
    if ($2-D/2<0) {
    print $1"\t"0"\t"$3+D/2"\t"$4"\t"$5"\t"$6;
    }
    else print $1"\t"$2-D/2"\t"$3+D/2"\t"$4"\t"$5"\t"$6;
    }
else print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6;
}
