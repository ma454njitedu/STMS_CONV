#! /bin/bash
# 
#  No modifcaiton or arguments needed. 
# 
#  account number check
#	1. check data is numeric
#	2. check data is 9 digits
#	3. check data rows match with Trailer count
#	4. check for blank acct numbers in data file
#	5. check for accounts in data file that should be excluded
#	6. check for Dups in all Account files
#

DIR=`pwd`
OUT="$DIR/data/output"
LOG="$DIR/data/logs"

source getopts.incl
getopts_valid_values `basename $0` -m

echo "Data Row Level Check"						    |    tee $LOG/validate_acct_files.csv > $OUT/validate_acct_files.csv
echo "Acount File Name,Account Number,Row Number,Error Message,Notes"       |    tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
for j in CIE_EXCL_Account_List_0001_${MOCK}.dat CIE_Fallout_Account_List_${MOCK}.dat MSTR_Account_List_0001_${MOCK}.dat CIE_Final_Account_List_0001_${MOCK}.dat;do
#ls -1 $DIR/data/accounts/*${MOCK}* | sed 's/^.*\///' | while read j;do
    echo $j                                                                 |    tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
   cat $DIR/data/accounts/$j | while read i;do
       length=`expr "${i}" : '.*'`
       if [[ "$i" =~ ^TRAIL.* ]];then
          trailer_acct=`echo $i | sed 's/|.*//'`

	  trailer_cnt=`echo $i | sed 's/||//g' | cut -d -f2`
          if [[ $trailer_cnt -ne $row_cnt ]];then
       	     echo ",$trailer_acct,row $row_cnt,Counts don't match,Trailer count $trailer_cnt,Row count $row_cnt"		>> $OUT/validate_acct_files.csv
          else
	     echo ",$trailer_acct,row $row_cnt,Counts match,Trailer count $trailer_cnt,Row count $row_cnt"			>> $OUT/validate_acct_files.csv
	  fi
	  echo " "
       else
          row_cnt=$(( $row_cnt + 1 ))
          if [[ "$i" != +([0-9]) ]];then
	     echo ",$i,row $row_cnt,Data is not numeric,\"$i\""			>> $OUT/validate_acct_files.csv
	  fi


          if	[[ $length -ne 9 ]];then
	     echo ",$i,row $row_cnt,Data is not 9 digits,\"$i\""		>> $OUT/validate_acct_files.csv
          fi

      fi
   done
   echo " "                                                                |    tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
   row_cnt=0
done


echo "done with section 1"
echo " " 		| 	    		tee -a $LOG/validate_acct_files.log >> $OUT/validate_acct_files.csv
echo " " 		| 			tee -a $LOG/validate_acct_files.log >> $OUT/validate_acct_files.csv


echo "Data File Level Check"					    |    tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
ls -1 $DIR/data/accounts/* | sed 's/^.*\///' | while read j;do
   sort $DIR/data/accounts/${j}                                          > $DIR/data/tmp1.dat
   sort -u $DIR/data/accounts/${j}                                       > $DIR/data/tmp2.dat
   $DIR/diff.pl $DIR/data/tmp1.dat $DIR/data/tmp2.dat		 	>> $LOG/validate_acct_files.log

   num_dups=`wc -l $DIR/in1not2.csv | sed 's/ .*//'`

   echo "Duplicate Account File Check, Account File Name,Number of Dups" | tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
   echo ",$j,$num_dups Dups were found" 				>> $OUT/validate_acct_files.csv

   if [[ -s $DIR/in1not2.csv ]];then
      cat  $DIR/in1not2.csv | sed 's/^/	/'				>> $LOG/validate_acct_files.log
      cat  $DIR/in1not2.csv | sed 's/^/,/'				>> $OUT/validate_acct_files.csv
      echo " "              | 	       tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv
   fi
done
echo " "               	    |          tee -a $LOG/validate_acct_files.csv >> $OUT/validate_acct_files.csv

   rm $DIR/inboth.csv
   rm $DIR/in1not2.csv
   rm $DIR/in2not1.csv


rm $DIR/data/tmp1.dat
rm $DIR/data/tmp2.dat
