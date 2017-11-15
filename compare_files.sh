#! /bin/bash

NTWK_LOC_1='/cygdrive/t/DATA/R1M3'
NTWK_LOC_2='/cygdrive/t/DATA/R1M3/BK'
DIR=`pwd`

echo "start `date`"

if [[ -e $DIR/data/tmp_data_files.dat ]];then
   rm $DIR/data/tmp_data_files.dat
fi

if [[ -e $DIR/data/tmp_network_files.dat ]];then
   rm $DIR/data/tmp_network_files.dat
fi



#for i in $NTWK_LOC_1 $NTWK_LOC_2;do
for i in $NTWK_LOC_1;do

    ls -1 $i/* | egrep 'INP$|inp$' | sed 's/^.*\///' >> $DIR/data/tmp_network_files.dat

done



#for i in source;do
for i in core noncore;do
   
   ls -1 $DIR/data/$i/* | egrep 'INP$|inp$' | sed 's/^.*\///' >> $DIR/data/tmp_data_files.dat

done


./diff.pl $DIR/data/tmp_network_files.dat $DIR/data/tmp_data_files.dat


echo "end `date`"

rm $DIR/data/tmp_network_files.dat
rm $DIR/data/tmp_data_files.dat
