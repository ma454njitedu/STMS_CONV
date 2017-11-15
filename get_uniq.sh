#! /bin/bash

ls -1 P1M7src_* | while read i;do

cat $i | sed 's/^.*Column //' | sed 's/ error coun.*//' | egrep -v 'Invalid|duplicate' | sort -u

done
