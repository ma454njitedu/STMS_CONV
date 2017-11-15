#! /bin/bash/

 while read i; do

line=`echo $i | sed 's/0*//'`
x=`printf "%09d" $line` 
echo $x

done < $1 > ${1}.out
