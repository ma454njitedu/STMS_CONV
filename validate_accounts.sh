#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d %H%M%S'`

for j in noncore;do

   echo "$j files `date`" > $DIR/data/output/validate_accounts.dat
   echo ""               >> $DIR/data/output/validate_accounts.dat
   cat $DIR/data/common/list_${j}_filenames.txt | while read i;do
      file_name_key=`echo $i | cut -d, -f1`
      acct_col=`echo $i | cut -d, -f2`



      file_exists=`wc -l $DIR/data/${j}/${file_name_key}*  2> /dev/null`

      if [[ $file_exists ]];then
	 echo "$file_name_key"
         cat $DIR/data/${j}/${file_name_key}* | sed 's/||//g' | cut -d -f${acct_col} | sed 's/ //g' | sort -u > $DIR/data/data_accounts.txt
	 echo "$file_name_key"                                                                          >> $DIR/data/output/validate_accounts.dat
         ./diff.pl $DIR/data/accounts/CIE_Final_Account_List_0001_R2M1.dat $DIR/data/data_accounts.txt  >> $DIR/data/output/validate_accounts.dat
         echo ""                                                                                        >> $DIR/data/output/validate_accounts.dat
      fi

   done

done

rm $DIR/data/data_accounts.txt
rm $DIR/inboth.csv
rm $DIR/in1not2.csv
rm $DIR/in2not1.csv

echo "start $DAT"
echo "end   "`date '+%Y%m%d %H%M%S'
