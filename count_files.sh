#! /bin/bash

DIR=`pwd`

ls -1 $DIR/data/${1}/*.INP | sed 's/_20.*//' | sort -u | while read i;do

cnt=`ls -1 ${i}* | wc -l`
tot_cnt=$(( $tot_cnt + $cnt ))

key=`echo $i | sed 's/.*\///'`
echo "$key	$cnt	($tot_cnt)"


done


