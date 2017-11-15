#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d_%H%M%d'`

# use MSTR_ACCT for source files
# use CIE_Final for target files

source getopts.incl
getopts_valid_values `basename $0` -c -n -s -t -m

err='N'

for j in  "${FILETYPE[@]}";do
    echo $j
    if [[ $j == 'core' || $j == 'noncore' ]];then
       file_type='target'
       FILENAME="CIE_Final_Account_List_0001_${MOCK}.dat"
    else
       file_type='source'
       FILENAME="MSTR_Account_List_0001_${MOCK}.dat"
    fi


    cat $DIR/data/common/list_${j}_filenames.txt | egrep -v 'CUST_0500|ETRACS_0040|HEADER' | while read i;do

        common_key=`echo $i | cut -d, -f1`
        acct_col=`echo $i | cut -d, -f2`
        incl_file=`echo $i | cut -d, -f4`


 	if [[ $incl_file -eq 0 ]];then
           echo "$common_key	EXCLUDED" 
 	   continue
 	fi

        echo "$common_key" | tee -a $DIR/data/tmp_mstr_output.dat
    
        cat $DIR/data/${j}/*${common_key}* | sed -e 's/||//g' | cut -d -f${acct_col} | sed 's/ //g' | sort -n --parallel=8 -S 75% -u > $DIR/data/tmp_data_accts.dat
#        cat $DIR/data/${j}/*${common_key}* | grep $MOCK | sed 's/||//g' | cut -d -f${acct_col} | sort -n --parallel=8 -S 75% -u > $DIR/data/tmp_data_accts.dat
#        cat $DIR/data/${j}/*${common_key}* | sed 's/||//g' | cut -d -f${acct_col} | sort -n --parallel="$(nproc --all)" -S 75% -u > $DIR/data/tmp_data_accts.dat


        $DIR/spcl_diff.pl $DIR/data/accounts/$FILENAME $DIR/data/tmp_data_accts.dat > $DIR/data/tmp_${common_key}_diff.dat
if [[ $common_key == 'CACS_ETRACS_0010' ]];then
	cp $DIR/data/tmp_data_accts.dat $DIR/data/adh_data_accts.dat
fi

        while read k;do
            msg_row_cnt=`echo $k | sed 's/.*:\s\s*//'`
	    if [[ $k =~ 'matched:'  &&  $msg_row_cnt -eq 0 ]];then
	       echo "	no accounts matched in data, see  validate_mstr_${common_key}_${file_type}_accts_missing in logs dir" | tee  -a $DIR/data/tmp_mstr_output.dat
	       echo "	file 1 is the mstr account file"
	       err="Y"
	    elif [[ $k =~ 'from file 1'  &&  $msg_row_cnt -gt 0 ]];then
	       echo "	accounts missing in data are in validate_mstr_${common_key}_${file_type}_accts_missing in logs dir" | tee  -a $DIR/data/tmp_mstr_output.dat
	       echo "	file 1 is the mstr account file"
	       err="Y"
	    elif [[ $k =~ 'from file 2'  &&  $msg_row_cnt -gt 0 ]];then
	       echo "	accounts in data are not in mstr, see validate_mstr_${common_key}_${file_type}_accts_missing in logs dir" | tee  -a $DIR/data/tmp_mstr_output.dat
	       echo "	file 1 is the mstr account file"
	       err="Y"
	    fi
        done < $DIR/data/tmp_${common_key}_diff.dat 


	if [[ $err = "Y" ]];then
           cat $DIR/data/tmp_${common_key}_diff.dat | sed 's/^/	/' | tee  -a $DIR/data/tmp_mstr_output.dat
	   echo ""                                                 | tee  -a $DIR/data/tmp_mstr_output.dat
        fi
        err="N"

	mv $DIR/inboth.csv  $DIR/data/logs/validate_mstr_${common_key}_${file_type}_accts_in_both.log
        mv $DIR/in1not2.csv $DIR/data/logs/validate_mstr_${common_key}_${file_type}_accts_missing_in_data.log
        mv $DIR/in2not1.csv $DIR/data/logs/validate_mstr_${common_key}_${file_type}_accts_missing_in_mstr.log

	rm $DIR/data/tmp_${common_key}_diff.dat

    done
done

mv $DIR/data/tmp_mstr_output.dat  $DIR/data/output/validate_mstr_${file_type}_$DAT.dat

   
rm $DIR/data/tmp_data_accts.dat
if [[ -s $DIR/inboth.csv ]];then
   rm $DIR/inboth.csv
   rm $DIR/in1not2.csv
   rm $DIR/in2not1.csv
fi

echo "begin date $DAT"
echo "end   date" `date '+%Y%m%d_%H%M%d'`






exit

if [ $(ls -1 data/core/CUST_0070* 2>/dev/null | wc -l) == 0 ];then 
   echo "no files";
else



fi

