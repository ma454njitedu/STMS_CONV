#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d'`

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s -m

echo `date` > $DIR/data/tmp_validate_filenames.log
echo ""    >> $DIR/data/tmp_validate_filenames.log

cat $DIR/data/common/list* | sed 's/,.*//' > $DIR/data/tmp_full_key_list.dat


for j in "${FILETYPE[@]}";do

    ls -1 $DIR/data/$j/*HEADER* | sed 's/^.*\///' > $DIR/data/tmp_file_names.dat
#    ls -1 $DIR/data/$j/*HEADER*${MOCK}* | sed 's/^.*\///' > $DIR/data/tmp_file_names.dat
    cat $DIR/data/common/header_${j}_filenames.txt | sed "s/mock/$MOCK/" > $DIR/data/tmp_header_filenames.dat
    while read i;do
       match=`grep $i $DIR/data/tmp_file_names.dat | wc -l`
       [[ $match -eq 0 ]]  &&  echo "$i	HEADER FILE MISSSING" | tee -a $DIR/data/tmp_validate_filenames.log
    done  < $DIR/data/tmp_header_filenames.dat


    while read i;do
       match=`grep $i $DIR/data/tmp_header_filenames.dat | wc -l`
       [[ $match -eq 0 ]]  &&  echo "$i	data HEADER FILE INVALID" | tee -a $DIR/data/tmp_validate_filenames.log
    done < $DIR/data/tmp_file_names.dat

    echo "" >> $DIR/data/tmp_validate_filenames.log


done



for k in data header;do
   for j in "${FILETYPE[@]}";do
       if [[ $k == "data" ]];then
          echo "DATA file"    >> $DIR/data/tmp_validate_filenames.log
          ls -1 $DIR/data/$j/*${MOCK}* | egrep 'INP$|inp$' | egrep -v 'HEADER|CIE' > $DIR/data/tmp_file_names.dat
       else
          echo "HEADER file"    >> $DIR/data/tmp_validate_filenames.log
          cat $DIR/data/$j/*HEADER*${MOCK}* | egrep -v '^Total|^Time|^Instan|^List'| sed 's/,.*//' > $DIR/data/tmp_file_names.dat
       fi
#       cat $DIR/data/tmp_file_names.dat | while read i;do
       while read i;do
          file_name=`echo $i | sed 's/.*\///'`
	  echo $file_name
	  echo $file_name >> $DIR/data/tmp_validate_filenames.log
          if [[ $j == 'source' ]];then
             type_key=`echo $file_name     | cut -d_ -f1-3` 
             date_section=`echo $file_name | cut -d_ -f4`
             seq_section=`echo $file_name  | cut -d_ -f5`
             mock_section=`echo $file_name | cut -d_ -f6 | sed 's/\..*//'`
             inp_section=`echo $file_name  | cut -d_ -f6 | sed 's/.*\.//'`
          else
             type_key=`echo $file_name     | cut -d_ -f1-2`
             date_section=`echo $file_name | cut -d_ -f3`
             seq_section=`echo $file_name  | cut -d_ -f4`
             mock_section=`echo $file_name | cut -d_ -f5 | sed 's/\..*//'`
             inp_section=`echo $file_name  | cut -d_ -f5 | sed 's/.*\.//'`
          fi
#
   	  echo "     Key check for $type_key" >> $DIR/data/tmp_validate_filenames.log
          key_found=`grep ^$type_key $DIR/data/tmp_full_key_list.dat | wc -l`
          if [[ $key_found -ne 1 ]];then
	     echo "	INVALID key $key_found	$type_key" >> $DIR/data/tmp_validate_filenames.log
          fi
#
          echo "     date check $date_section" >> $DIR/data/tmp_validate_filenames.log
          date -d $date_section "+%Y%m%d" > /dev/null 2>&1 
          if  [[ $? -gt 0 ]];then
             echo "	INVALID date, $date_section" >> $DIR/data/tmp_validate_filenames.log
          fi
#
          echo "     seq check $seq_section" >> $DIR/data/tmp_validate_filenames.log
          len_of_seq=`expr length "$seq_section"`
          if [[ ! $seq_section =~ [[:digit:]]{6} ]];then
	     echo "	INVALID sequence number $seq_section : not numeric or not 6 digits" >> $DIR/data/tmp_validate_filenames.log
          fi
#
          echo "     Mock check $mock_section should match $MOCK" >> $DIR/data/tmp_validate_filenames.log
          if [ $mock_section != $MOCK ];then
             echo "	INVALID Mock number, file $mock_section does not match expected $MOCK" >> $DIR/data/tmp_validate_filenames.log
          fi
#
          echo "     Prefix check $inp_section should match INP" >> $DIR/data/tmp_validate_filenames.log
          if [ $inp_section != "INP" ];then
   	     echo "	INVALID file suffix. $inp_section should be INP" >> $DIR/data/tmp_validate_filenames.log
          fi

          echo "" >> $DIR/data/tmp_validate_filenames.log

       done < $DIR/data/tmp_file_names.dat

   done

done

echo ""     >> $DIR/data/tmp_validate_filenames.log
echo `date` >> $DIR/data/tmp_validate_filenames.log

cat $DIR/data/tmp_validate_filenames.log | egrep '^[A-Z]|INVALID' > $DIR/data/output/validate_filenames_$DAT.csv
mv $DIR/data/tmp_validate_filenames.log $DIR/data/logs/validate_filenames_$DAT.log

rm $DIR/data/tmp_header_filenames.dat
rm $DIR/data/tmp_file_names.dat
rm $DIR/data/tmp_full_key_list.dat
