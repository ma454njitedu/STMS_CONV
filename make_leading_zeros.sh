#! /bin/bash

_NC='\033[0m'
yellow_on_red='\033[1;33;41m'

if [[ $# -ne 1 ]];then
   clear
   echo ""
   echo "you must include the name of the data file as an agrument"
   echo -e "usage:	$yellow_on_red $0 file_name $_NC"
   exit;
fi


DIR=`pwd`
file_name=`echo $DIR/$1 | sed 's/\..*/_mod.txt/'`




cat $1 | sed -e 's///' -e 's/ //g' > $DIR/tmp_make_leading_zeros.txt
gawk -F, '{
     
      printf("%09d\n", $1)

}' < $DIR/tmp_make_leading_zeros.txt >> $file_name



rm $DIR/tmp_make_leading_zeros.txt
