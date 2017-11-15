#! /bin/bash

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`
source getopts.incl
getopts_valid_values `basename $0` -t -s -f -m


if [[ $TARGET  &&  $SOURCE ]];then
   echo "choose only -t or -s, not both"
   exit
fi


echo ""
echo $0
echo "started $DAT"



if [[ $TARGET ]];then
   NTWK_LOC_1="/cygdrive/t/${FILE}"
else
   NTWK_LOC_1="/cygdrive/s/${FILE}"
fi

echo "NETWK_LOC $NTWK_LOC_1"

echo "   processing $file_type common file..."
for i in ${FILETYPE[@]};do
   cat $DIR/data/common/list_${i}_filenames.txt 
done | sort > $DIR/data/tmp_common_file.dat

echo "   getting network data..."
ls -1 -f $NTWK_LOC_1/*${MOCK}* | sed -e 's/^.*\///' -e 's/inp/INP/' | egrep -v '^-|no good' > $DIR/data/tmp_network_files.dat

echo "   validating network data against common data"
while read i;do
   key=`echo $i | sed 's/,.*//'` 

#   echo "seq col $seq_col $i"
   if [[ $TARGET ]];then
      seq_col=4
      grep $key $DIR/data/tmp_network_files.dat | sort -u -t"_" -k1,2 -k4,4 -k3,3r > $DIR/data/tmp_network_files.srt
   elif [[ $SOURCE ]];then
      seq_col=5
      grep $key $DIR/data/tmp_network_files.dat | sort -u -t"_" -k1,3 -k5,5 -k4,4r > $DIR/data/tmp_network_files.srt
   else
      echo "not source or target"
   fi

   echo ",,,"
   echo $key
   echo "===================================================================================="
   if [[ ! -s $DIR/data/tmp_network_files.srt ]];then
	   echo ",,$key files are MISSING"
   fi
   cnt=0
   while read j;do
      seq=`echo $j | cut -d_ -f${seq_col}`
#      seq=`echo $j | cut -d_ -f4`
      cnt=$(( $cnt + 1 ))
      cntr=`printf "%06d" $cnt`
      if [[ $cntr == $seq ]];then
         echo "cnt $cntr,seq $seq,$j,"
      elif [[ $cntr < $seq ]];then
         newline=`echo $j | sed "s/$seq/$cntr/"`
         echo "cnt $cntr,seq $seq,$newline,MISSING sequence $cntr"
	 until [ $cntr == $seq ];do
            cnt=$(( $cnt + 1 ))
            cntr=`printf "%06d" $cnt`
	    if [[ $cntr == $seq ]];then
               echo "cnt $cntr,seq $seq,$j,"
            else
               newline=`echo $j | sed "s/$seq/$cntr/"`
               echo "cnt $cntr,seq $seq,$newline,MISSING sequence $cntr"
            fi
	 done
      else
         echo "cnt $cntr,seq $seq,$j,INVALID" 
         cnt=$(( $cnt - 1 ))
      fi

   done < $DIR/data/tmp_network_files.srt 

done < $DIR/data/tmp_common_file.dat > $DIR/data/output/validate_network_files_${DAT}.csv

rm $DIR/data/tmp_common_file.dat
rm $DIR/data/tmp_network_files.dat
rm $DIR/data/tmp_network_files.srt

echo "ended `date '+%Y%m%d-%H%M%S'`"
