#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`


if [[ $1 ]];then
    if [[ $1 == `basename $1` ]];then
       IN_FILE=$DIR/data/output/$1
       echo "1"
     else
       IN_FILE=$1
       echo "2"
     fi
else
   IN_FILE=`ls -1rt $DIR/data/output/find_accts_by_key_* | tail -1` 
   echo "3"
fi

while read i;do

   acct=`echo $i|cut -d, -f1`
   file=`echo $i|cut -d, -f2`
   type=`echo $i|cut -d, -f3`

   echo $acct	$file
   egrep "\|\|$acct\|\||^${acct}\|\|" $DIR/data/$type/$file

   echo "--------------------------------------------------------------------------------------------"

done < $IN_FILE > $DIR/data/output/find_accts_data_$DAT.dat
