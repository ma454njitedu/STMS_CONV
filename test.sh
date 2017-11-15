#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d'`

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s -m

echo `date` > $DIR/data/validate_filenames.log
echo ""    >> $DIR/data/validate_filenames.log

cat $DIR/data/common/header* | sed "s/mock/$MOCK/" > $DIR/data/tmp_full_header_list.dat

for j in "${FILETYPE[@]}";do

    ls -1 $DIR/data/$j/*HEADER* > $DIR/data/tmp_file_names.dat

    while read i;do
       match=`grep $i $DIR/data/tmp_file_names.dat | wc -l`
       [[ $match -eq 0 ]]  &&  echo "Common HEADER FILE $i MISSSING" >> $DIR/data/validate_filenames.log
    done < $DIR/data/tmp_full_header_list.dat

        
    while read i;do
       match=`grep $i $DIR/data/tmp_full_header.dat | wc -l`
       [[ $match -eq 0 ]]  &&  echo "data HEADER FILE $i INVALID" >> $DIR/data/validate_filenames.log
    done < $DIR/data/tmp_file_names.dat



done 
