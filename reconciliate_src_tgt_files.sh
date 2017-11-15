#! /bin/bash
# 
#  
#	1. verify the total of source file counts(ex. xxx_cust_0000_xxxxx) - exclusion - fallout = target file counts (cust_0000_xxx)
#

DIR=`pwd`
OUT="$DIR/data/output"
LOG="$DIR/data/logs"
COM="$DIR/data/common"
SRC="$DIR/data/source"


cat $DIR/data/accounts/CIE_EXCL_Account_List_0001_P1M7.dat | sort -u > $DIR/data/tmp_excl_accts


cat $COM/list_core_filenames.txt $COM/list_noncore_filenames.txt | while read i;do

   echo "======================================================="
   tgt_file_key=`echo $i | sed 's/,.*//'`
   src_acct_col=`echo $SRC/$i | cut -d, -f2`
   echo "===>	src_acct_col = $src_acct_col"
   echo $SRC/$i
   noncore_cnt=`ls -1 $DIR/data/noncore/* | grep "$tgt_file_key" | wc -l`
   core_cnt=`ls -1 $DIR/data/core/* | grep "$tgt_file_key" | wc -l` 
   if [[ $noncore_cnt -gt 0 ]];then tgt_dir='noncore'; else tgt_dir='core'; fi


#target files
   tgt_cnt=`cat $DIR/data/$tgt_dir/${tgt_file_key}* | sed 's/\xD1/N/' | sed 's/\xD4/O/' | sort -u | wc -l`
#   echo "TARGET	$tgt_cnt"
   echo "$tgt_file_key" > $DIR/data/tmp_tgt_keys

#source file
   cat $SRC/*_$tgt_file_key* | sed 's/\xD1/N/g' | sed 's/\xD4/O/g' | sed 's/||//g' | cut -d -f${src_acct_col} | sort -u > $DIR/data/tmp_src_accts
   src_cnt=`cat $DIR/data/tmp_src_accts | wc -l | sed 's/ .*//'`
#   echo ",SOURCE	$src_cnt"
   ls -1 $DIR/data/source/*_${tgt_file_key}* | sed 's/^.*\///' > $DIR/data/tmp_src_keys

#excl file 
   ./diff.pl $DIR/data/tmp_excl_accts $DIR/data/tmp_src_accts 
   excl_cnt=`wc -l $DIR/inboth.csv | sed 's/ .*//'`
   mv $DIR/inboth.csv $DIR/data/tmp_accts_to_excl
#   echo "Exclude $excl_cnt"
#   cat $DIR/inboth.csv 


   net_src_cnt=$(( $src_cnt - $excl_cnt ))
   diff_cnt=$(( $net_src_cnt - $tgt_cnt ))

   echo "$src_cnt Source Rows,$excl_cnt Rows to exclude,$net_src_cnt Net Source Rows,$tgt_cnt Target Rows,$diff_cnt differences"
   paste -d, $DIR/data/tmp_src_keys $DIR/data/tmp_accts_to_excl /dev/null $DIR/data/tmp_tgt_keys
   echo ""

done


#rm $DIR/in*.csv
#rm $DIR/data/tmp_src_accts
#rm $DIR/data/tmp_src_keys
#rm $DIR/data/tmp_tgt_keys
#rm $DIR/data/tmp_excl_accts
#rm $DIR/data/tmp_accts_to_excl
