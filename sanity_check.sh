#! /bin/bash

#------------------------------------------------------------------------------------------------------------#
#
# INSTRUCTIONS:
#
# there are no arguments for this script but modify source/core/noncore in 2 places
#
# csv and log files will be in .../data/ 
# 
# 1. get counts of all files matching key and counts of files in header matching key                 
# 2. compare all rows by sequence and compare with all rows in header
# 3. get row counts of each file and compare with row count shown in header file.
# 4. check for dups
# 5. check each row for valid
# 6. check for PGP file since counts can't be done on it
#
#------------------------------------------------------------------------------------------------------------#

source getopts.incl
getopts_valid_values `basename $0` -c -n -s -t
 

DIR=`pwd`
DAT=`date +%Y%m%d_%H%M%S`

rm $DIR/data/tmp_file_data.csv 2>/dev/null 
rm $DIR/data/tmp_rec_data.csv 2>/dev/null 


#---------------------- File Checks Start---------------------------------------------------------------------------#

#for j in core noncore source;do
for j in "${FILETYPE[@]}";do
   echo "#-------------------------------------------------------- $j File check ---------------------------------------------------------#"
   echo "#-------------------------------------------------------- $j File check ---------------------------------------------------------#"		>> $DIR/data/logs/sanity_check_$DAT.log
   file_type=`echo $j | tr "[a-z]" "[A-Z]"`
   echo "File name,Header_File Count,Actual Count REceived,Difference" 		>> $DIR/data/tmp_file_data.csv

   if [[ $j == 'source' ]];then
	   header_id='HEADER'
   else
	   header_id='CIE'
   fi
   echo "header_id = $header_id"               			                >> $DIR/data/logs/sanity_check_$DAT.log

   while read i;do
	file_name_key=`echo $i | cut -d, -f1`
        header_cnt=`grep "$file_name_key" $DIR/data/${j}/*${header_id}* | wc -l`
        data_cnt=`ls -1 $DIR/data/${j}/* | grep "$file_name_key" | wc -l`
	diff_cnt=$(( $header_cnt - $data_cnt ))
	echo "$file_name_key,$header_cnt,$data_cnt,$diff_cnt" 			>> $DIR/data/tmp_file_data.csv

   done < $DIR/data/common/list_${j}_filenames.txt
   echo ",,,,,,"								>> $DIR/data/tmp_file_data.csv
   echo ",,,,,,"								>> $DIR/data/tmp_file_data.csv
done
	


#for j in core noncore source;do
for j in "${FILETYPE[@]}";do

   if [[ $j == 'source' ]];then
	   header_id='HEADER'
   else
	   header_id='CIE'
   fi
   echo "header_id = $header_id"               			                >> $DIR/data/logs/sanity_check_$DAT.log

   ls -1 $DIR/data/$j/* | egrep -v $header_id | while read i;do
       data_file=`echo $i | sed 's/^.*\///'`
       echo "$data_file"
   done | sort  								> $DIR/data/data_${j}.out

   cat $DIR/data/$j/*${header_id}* | egrep 'INP|PGP|inp|pgp|txt|GPG|gpg' | while read i;do
        header_file=`echo $i | sed 's/,.*//'`
        echo $header_file
   done | sort 									> $DIR/data/header_${j}.out


   $DIR/diff.pl $DIR/data/header_${j}.out $DIR/data/data_${j}.out  		>> $DIR/data/logs/sanity_check_$DAT.log
  
   mv $DIR/inboth.csv $DIR/data/inboth_${j}.csv 
   mv $DIR/in1not2.csv $DIR/data/inHnotD_${j}.csv 
   mv $DIR/in2not1.csv $DIR/data/inDnotH_${j}.csv 

   rm $DIR/data/data_${j}.out
   rm $DIR/data/header_${j}.out


   file_type=`echo $j | tr "[a-z]" "[A-Z]"`
   if [[ $j == 'noncore' ]];then
      echo "" 											>> $DIR/data/tmp_rec_data.csv
      echo "" 											>> $DIR/data/tmp_rec_data.csv
   fi

   echo "$file_type File RECORD Counts" 							>> $DIR/data/tmp_rec_data.csv
   echo "File Name,Header File Row Count,Actual Row Count,Difference,Duplicate Rows,Notes" 	>> $DIR/data/tmp_rec_data.csv




#---------------------- Record Checks Start ---------------------------------------------------------------------------#
   echo "#-------------------------------------------------------- $j Record check ---------------------------------------------------------#"
   echo "#-------------------------------------------------------- $j Record check ---------------------------------------------------------#"		>> $DIR/data/logs/sanity_check_$DAT.log

   while read i;do

   if [[ $j == 'source' ]];then
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$3"_"$5}'` 
   else
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$4}'` 
   fi
      echo " "										>> $DIR/data/logs/sanity_check_$DAT.log
      echo "$short_file_name"								>> $DIR/data/logs/sanity_check_$DAT.log
      header_cnt=`grep $i $DIR/data/${j}/*$header_id* | cut -d, -f2 | sed 's/\s//g'`
#      echo "inHnotD $i header_cnt $header_cnt"
      data_cnt='MISSING'
      diff_cnt=$header_cnt
      dup_cnt="N/A"
      echo $short_file_name","$header_cnt ","$data_cnt","$diff_cnt","$dup_cnt		>> $DIR/data/tmp_rec_data.csv
   done < $DIR/data/inHnotD_${j}.csv


   while read i;do

   if [[ $j == 'source' ]];then
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$3"_"$5}'` 
   else
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$4}'` 
   fi
      echo " "											>> $DIR/data/logs/sanity_check_$DAT.log
      echo "$short_file_name"									>> $DIR/data/logs/sanity_check_$DAT.log
      header_cnt='MISSING'

#dup check begins
#      data_cnt=`wc -l $DIR/data/${j}/${i} | sed 's/ .*//' | sed 's/\s//g'`
#      cat $DIR/data/${j}/${i} | sed 's///' > $DIR/data/input_data.dat
#      uniq_cnt=`cat $DIR/data/${j}/${i} | tr '\xD1\xD4\xC1\xC9\xCD\xC3\xD3\xC1\xDA\xF1\226\240\222' 'X' | sort -u 2>$DIR/data/err.log | wc -l | sed 's/ .*//'`
#      data_cnt=`cat $DIR/data/${j}/${i} | tr '\xD1\xD4\xC1\xC9\xCD\xC3\xD3\xC1\xDA\xF1\226\240\222' 'X' | tee $DIR/data/input_data.dat | wc -l | sed 's/ .*//'`
#      uniq_cnt=`cat $DIR/data/${j}/${i} | tr '\xD1\xD4\xC1\xC9\xCD\xC3\xD3\xC1\xDA\xF1\226\240\222' 'X' | sort -u 2>$DIR/data/err.log | tee $DIR/data/input_data_uniq.dat | wc -l | sed 's/ .*//'`
      data_cnt=`cat $DIR/data/${j}/${i} | tee $DIR/data/input_data.dat | wc -l | sed 's/ .*//'`
      uniq_cnt=`cat $DIR/data/${j}/${i} | LC_ALL=C sort -u 2>$DIR/data/err.log | tee $DIR/data/input_data_uniq.dat | wc -l | sed 's/ .*//'`
      dup_cnt=$(( $data_cnt - $uniq_cnt ))
      diff_cnt=$data_cnt
      sort_err_chk=`wc -l $DIR/data/err.log | sed 's/ .*//'`

      if [[ $sort_err_chk -gt 0 ]];then
	 err_msg="INVALID DATA see log"
	 cat $DIR/data/err.log 									>> $DIR/data/logs/sanity_check_$DAT.log 
         rm $DIR/data/err.log
      fi
      if [[ "$i" =~ ^.*GPG$ ]];then 
         err_msg="GPG File"
      fi
      if [[ $dup_cnt -ne 0  &&  $sort_err_chk -eq 0 ]];then
	 echo "     Duplicates -------------------------------------------" 			>> $DIR/data/logs/sanity_check_$DAT.log 
	 $DIR/diff.pl $DIR/data/input_data.dat $DIR/data/input_data_uniq.dat			>> $DIR/data/logs/sanity_check_$DAT.log 
  	 cat $DIR/in1not2.csv | sed 's/^/	/'		 				>> $DIR/data/logs/sanity_check_$DAT.log 
	 echo ""										>> $DIR/data/logs/sanity_check_$DAT.log 
	 echo ""										>> $DIR/data/logs/sanity_check_$DAT.log 
	 err_msg="DUPLICATES see log"
      fi
      echo $short_file_name","$header_cnt ","$data_cnt","$diff_cnt","$dup_cnt","$err_msg	>> $DIR/data/tmp_rec_data.csv
      sort_err_chk=0
      err_msg=""
# dup check ends
 
   done < $DIR/data/inDnotH_${j}.csv


   while read i;do
#adh 5 lines
#      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$4}'` 
   if [[ $j == 'source' ]];then
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$3"_"$5}'` 
   else
      short_file_name=`echo $i | awk -F_ '{print $1"_"$2"_"$4}'` 
   fi
      echo " "											>> $DIR/data/logs/sanity_check_$DAT.log
      echo "$short_file_name"									>> $DIR/data/logs/sanity_check_$DAT.log
#      echo "$short_file_name"
#      echo "$i"
#      echo ""
#adh 1 line
#      header_cnt=`grep $i $DIR/data/${j}/CIE* | cut -d, -f2 | sed 's/\s//g'`
      header_cnt=`grep $i $DIR/data/${j}/*${header_id}* | cut -d, -f2 | sed 's/\s//g'`

#dup check begins
#      data_cnt=`wc -l $DIR/data/${j}/${i} | sed 's/ .*//' | sed 's/\s//g'`
#      cat $DIR/data/${j}/${i} | sed 's///' > $DIR/data/input_data.dat
#      data_cnt=`cat $DIR/data/${j}/${i} | tr '\xD1\xD4\xC1\xC9\xCD\xC3\xD3\xC1\xDA\xF1\226\240\222' 'X' | tee $DIR/data/input_data.dat | wc -l | sed 's/ .*//'`
#      uniq_cnt=`cat $DIR/data/${j}/${i} | tr '\xD1\xD4\xC1\xC9\xCD\xC3\xD3\xC1\xDA\xF1\226\240\222' 'X' | sort -u 2>$DIR/data/err.log | tee $DIR/data/input_data_uniq.dat | wc -l | sed 's/ .*//'`
      data_cnt=`cat $DIR/data/${j}/${i} | tee $DIR/data/input_data.dat | wc -l | sed 's/ .*//'`
      uniq_cnt=`cat $DIR/data/${j}/${i} | LC_ALL=C sort -u 2>$DIR/data/err.log | tee $DIR/data/input_data_uniq.dat | wc -l | sed 's/ .*//'`
      dup_cnt=$(( $data_cnt - $uniq_cnt ))
      diff_cnt=$(( $header_cnt - $data_cnt ))
      sort_err_chk=`wc -l $DIR/data/err.log | sed 's/ .*//'`
      if [[ $sort_err_chk -gt 0 ]];then
	 err_msg="INVALID DATA see log"
	 cat $DIR/data/err.log 									>> $DIR/data/logs/sanity_check_$DAT.log 
         rm $DIR/data/err.log
      fi
      if [[ "$i" =~ ^.*GPG$ ]];then 
         err_msg="GPG File"
      fi

      if [[ $dup_cnt -ne 0  &&  $sort_err_chk -eq 0 ]];then
	 echo "     Duplicates -------------------------------------------" 			>> $DIR/data/logs/sanity_check_$DAT.log 
	 $DIR/diff.pl $DIR/data/input_data.dat $DIR/data/input_data_uniq.dat 			>> $DIR/data/logs/sanity_check_$DAT.log 
  	 cat $DIR/in1not2.csv | sed 's/^/	/'		 				>> $DIR/data/logs/sanity_check_$DAT.log 
	 echo ""										>> $DIR/data/logs/sanity_check_$DAT.log 
	 echo ""										>> $DIR/data/logs/sanity_check_$DAT.log 
	 err_msg="DUPLICATES see log"
      fi
      echo $short_file_name","$header_cnt ","$data_cnt","$diff_cnt","$dup_cnt","$err_msg	>> $DIR/data/tmp_rec_data.csv
      sort_err_chk=0
      err_msg=""
#dup check ends
   done < $DIR/data/inboth_${j}.csv

#adh
   rm $DIR/data/inboth_${j}.csv 
   rm $DIR/data/inHnotD_${j}.csv 
   rm $DIR/data/inDnotH_${j}.csv 

done

echo "tmp_file_data"
wc -l $DIR/data/tmp_file_data.csv
echo "tmp_rec_data.csv"
wc -l $DIR/data/tmp_rec_data.csv

paste -d, $DIR/data/tmp_file_data.csv /dev/null /dev/null $DIR/data/tmp_rec_data.csv > $DIR/data/output/sanity_check_$DAT.csv

#perl -e '
#use strict;
#
#open (FILE1, "</home/ah694w/automation/data/tmp_file_data.csv") || die "cant find file $ARGV[0] $!\n";
#open (FILE2, "</home/ah694w/automation/data/tmp_rec_data.csv") || die "cant find file $ARGV[0] $!\n";
#
#my @file_data = (<FILE1>);
#my @rec_data = (<FILE2>);
#close FILE1;
#close FILE2;
#
#my $number_of_file_rows = @file_data;
#my $number_of_rec_rows = @rec_data;
#my $rows=0;
#my $x=0;
#my $stop="";
#my $max_row=0;
#
#
#if ($number_of_rec_rows > $number_of_file_rows) {
#   $rows = $number_of_file_rows;
#   $max_row = $number_of_rec_rows;
#}else{
#   $rows = $number_of_rec_rows;
#   $max_row = $number_of_file_rows;
#}
#
#until ($stop eq "Y") {
# 
#  if ( $x <= $number_of_file_rows && $x <= $number_of_rec_rows) {
#     chomp $file_data[$x];
#     chomp $rec_data[$x];
#     print "$file_data[$x],,,$rec_data[$x]\n";
#  }elsif ($x <= $number_of_rec_rows) {
#     chomp $rec_data[$x];
#     print ",,,,,,$rec_data[$x]\n";
#  }else{
#     chomp $file_data[$x];
#     print "$file_data[$x]\n";
#  }
#
#   $x++;
#
#   if ($x > $max_row) {
#      $stop = "Y";
#   }
#}
#
#
#' > $DIR/data/output/sanity_check_$DAT.csv

rm $DIR/data/tmp_file_data.csv
rm $DIR//data/tmp_rec_data.csv
rm $DIR/in*.csv
#rm $DIR/data/uniq*
rm $DIR/data/err.log
rm $DIR/data/input_data.dat
rm $DIR/data/input_data_uniq.dat

echo "start $DAT"
echo "end   `date +%Y%m%d_%H%M%S`"
