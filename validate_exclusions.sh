#! /bin/bash
#
#	combine EXCL and Fallout accounts (remove trailer records)
#
#  exclustion.sh
#	1. check for blank acct numbers in excl file
#	2. check for blank acct numbers in data file
#	3. check for accounts in data file that should be excluded
#
DIR=`pwd`
OUT="$DIR/data/output"
LOG="$DIR/data/logs"
#FILE="CIE_EXCL_and_Fallout_Account_list_P1M6.dat"

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -m
FILE="CIE_EXCL_and_Fallout_Account_list_${MOCK}.dat"


blank_excl_rows=`cat $DIR/data/accounts/$FILE | egrep '^$|^  .*$|^		*$' | wc -l`
sort $DIR/data/accounts/$FILE    > $DIR/data/dup_chk.dat
sort -u $DIR/data/accounts/$FILE > $DIR/data/dup_chk_uniq.dat
./diff.pl $DIR/data/dup_chk.dat $DIR/data/dup_chk_uniq.dat    >> $LOG/validate_exclusions.log
excl_dup_cnt=`wc -l $DIR/in1not2.csv | sed 's/ .*//'`

echo "Check for accounts that should be excluded, $blank_excl_rows blank rows in Exclusion file, $excl_dup_cnt dups in Exclusion file" | tee $LOG/validate_exclusions.log > $OUT/validate_exclusions.csv
echo "" | tee $LOG/validate_exclusions.log > $OUT/validate_exclusions.csv

echo "exclusion file is $FILE" 										>> $LOG/validate_exclusions.log

#for j in core;do
for j in "${FILETYPE[@]}";do
   ls -1 $DIR/data/${j}/*.INP | sed 's/^.*\///' | egrep -v '^CIE|GPG|gpg|PGP|pgp' | while read i;do
      echo $i
      if [[ $i =~ $MOCK ]];then
         key=`echo $i | cut -d _ -f 1,2`
         acct_col=`grep $key $DIR/data/common/list_${j}_filenames.txt | cut -d, -f 2`
         if [[ $acct_col -gt 0 ]];then
            cat $DIR/data/${j}/${i} | sed 's/||//g' | cut -d  -f $acct_col 				> $DIR/data/tmp.dat
            blank_data_rows=`cat $DIR/data/${j}/${i} | egrep '^$|^  .*$|^		*$' | wc -l`
            echo "blank lines in $i = $blank_data_rows"	 						>> $LOG/validate_exclusions.log


            echo "$i"	 										>> $LOG/validate_exclusions.log

            ./diff.pl $DIR/data/accounts/$FILE $DIR/data/tmp.dat 						>> $LOG/validate_exclusions.log
            cnt=`wc -l $DIR/inboth.csv | sed 's/ .*//'`

            echo "File Name,Acct numbers not excluded,number of blanks"					>> $OUT/validate_exclusions.csv
            echo "File Name		Account Numbers not excluded		blank accounts"		>> $LOG/validate_exclusions.log
            echo "$i	$cnt total 	$blank_data_rows "						>> $LOG/validate_exclusions.log
            echo "$i,$cnt Total,$blank_data_rows"								>> $OUT/validate_exclusions.csv

            cat $DIR/inboth.csv | sed 's/^/,/' 		>> $OUT/validate_exclusions.csv
            cat $DIR/inboth.csv | sed 's/^/	/'	>> $LOG/validate_exclusions.log
            echo "" 					>> $LOG/validate_exclusions.log
            echo "" 					>> $OUT/validate_exclusions.csv
         fi
      else
	     echo "	Invalid mock	$MOCK $i" 
      fi
   done

done
rm $DIR/data/tmp.dat
rm $DIR/inboth.csv
rm $DIR/in1not2.csv
rm $DIR/in2not1.csv
rm $DIR/data/dup_chk.dat
rm $DIR/data/dup_chk_uniq.dat
