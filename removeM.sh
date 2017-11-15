#! /bin/bash


ls -1 *.INP | while read i;do
cat $i | sed 's/$//' > tmp_removeM.dat

mv tmp_removeM.dat $i
echo $i


done
