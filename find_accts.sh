#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s 

for x in "${FILETYPE[@]}";do



done







exit

sort -u -t"_" -k4
cat ./data/source/STMS_CUST_0010_20170517_000001_R1M3.INP | sed 's/||/^A/g' | sort -t"^A" -k4 | sed 's/^A/||/g'

awk `NR==FNR{keys[$1] {for (key in keys) if ($0 ~ key) {print $0; next} }` accts.dat input.txt > output.txt
