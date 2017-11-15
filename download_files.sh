#! /bin/bash

DIR=`pwd`
MOCK='R1M3'
HOLD_DIR="/cygdrive/c/Users/REMOTE"
OUT_DIR="/home/conversion/data/storage/TEST"

if [[ $TARGET ]];then
   DIR_TYPE='/cygdrive/t'
   FILE='Data/${MOCK}'
   head_tot=2
else
   DIR_TYPE='/cygdrive/s'
   FILE='ProcessedFiles/HS14'
   head_tot=10
   OUT_DIR="/home/conversion/data/storage/TEST/source"
fi

#################################### Testing ##############################################



   DIR_TYPE='/cygdrive/c/Users/ah694w'
   FILE='HOLD/TMP'





###############################################################################################

loop_cnt=0
prev_cnt=0

if [[ $(find $DIR_TYPE/${FILE}/*${MOCK}* -mindepth 1 -print -quit | grep -q .) ]];then
   ls -1rt $DIR_TYPE/${FILE}/*${MOCK}* | tail -${diff_cnt} | xargs cp -t  $HOLD_DIR/ &

until [[ $head_cnt -eq $head_tot ]];do
   curr_cnt="$(ls -1rt $DIR_TYPE/$FILE/*R1M3* | wc -l)"
   diff_cnt=$(( $curr_cnt - $prev_cnt ))
   prev_cnt=$(( $curr_cnt ))


#   if [[ $(find $DIR_TYPE/${FILE}/*${MOCK}* -mindepth 1 -print -quit | grep -q .) ]];then
      ls -1rt $DIR_TYPE/${FILE}/*${MOCK}* | tail -${diff_cnt} | xargs cp -t  $HOLD_DIR/ &
      copy_pid=$!

      echo "copy_pid $copy_pid" 

      cnt_of_files_copied=0
      until [[ $cnt_of_files_copied -gt 2 ]];do
         if [ "$(ls -U /cygdrive/c/Users/REMOTE/*${MOCK}* 2> /dev/null | wc -l)" -gt 0 ];then 
            cnt_of_files_copied=`ls -lU $HOLD_DIR/*$MOCK* | wc -l`
            echo "cnt_of_Files_copied $cnt_of_files_copied"
         fi
      done


      cnt=0
      until [[ $cnt -eq $diff_cnt ]];do
          if [ "$(ls -U /cygdrive/c/Users/REMOTE/*${MOCK}* 2> /dev/null | wc -l)" -gt 0 ];then 
             file_name_in=`ls -1rt $HOLD_DIR/*${MOCK}* | sed 's/^.*\///' | tail -2 | head -1` 
             file_name_out=`echo $file_name_in | sed 's/inp/INP/'`
             echo "file_name is $file_name_in	$file_name_out	cnt is $cnt" 
             cat $HOLD_DIR/$file_name_out | sed 's/$//' > $OUT_DIR/$file_name_out          
             rm $HOLD_DIR/$file_name_in                                                     
             cnt=`ls -1U $OUT_DIR/*${MOCK}* | wc -l`                                            
          fi
      done
      head_cnt=`ls -U $OUT_DIR/*HEADER*${MOCK}* 2> /dev/null | wc -l`
      loop_cnt=$(( $loop_cnt+1 ))
      echo "end iteration $loop_cnt"
#   fi
done
