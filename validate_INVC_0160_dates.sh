#! /bin/bash
#
#  verify INVC_0160 files have every date between START_DATE and 124 days previous
#

DIR=`pwd`

source getopts.incl
getopts_valid_values `basename $0` -c -s -d

START_DATE=$YYYYMMDD

END_DATE=$(date '+%Y%m%d' -d "$START_DATE-123 days")

echo "Validating TRX_DATE is within the range of $START_DATE and $END_DATE"

######################################################################################################

for i in {0..123};do
  echo $(date '+%Y%m%d' -d "$START_DATE-${i} days")
done > $DIR/data/tmp_DATE_file.dat

#

for i in "${FILETYPE[@]}";do

   if [[ $i == 'core' ]];then
      file_names="INVC_0160"
      dir_name="core"
   else 
      file_names="TRS_INVC_0160 STMS_INVC_0160"
      dir_name="source"
   fi

   for j in ${file_names};do
      echo ""
      echo "	$j"
      cat $DIR/data/${dir_name}/${j}* | sed 's/||//g' | cut -d -f18 | sort -u > $DIR/data/tmp_data_file.dat
   
      ./diff.pl $DIR/data/tmp_data_file.dat $DIR/data/tmp_DATE_file.dat
      echo ""
      echo "in2not1  	in1not2"
      echo "(DATE file)	(data file)"
      echo ""
      echo "file date	file date is"
      echo "is Missing 	Out of Range"
      echo "----------	------------"
      paste $DIR/in2not1.csv $DIR/in1not2.csv | sed 's/^	/		/'
   done
done > $DIR/data/tmp_INVC_0160_dates.txt

echo " "                                                                    | tee  $DIR/data/output/validate_INVC_0160_dates.txt
echo "Validating TRX_DATE is within the range of $START_DATE and $END_DATE" | tee -a  $DIR/data/output/validate_INVC_0160_dates.txt
echo " "                                                                    | tee -a  $DIR/data/output/validate_INVC_0160_dates.txt
cat  $DIR/data/tmp_INVC_0160_dates.txt                                      | tee -a  $DIR/data/output/validate_INVC_0160_dates.txt

rm $DIR/inboth.csv 
rm $DIR/in1not2.csv
rm $DIR/in2not1.csv
rm $DIR/data/tmp_INVC_0160_dates.txt
rm $DIR/data/tmp_data_file.dat
rm $DIR/data/tmp_DATE_file.dat 
