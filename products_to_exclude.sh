#! /bin/bash

_NC='\033[0m'
yellow_on_red='\033[1;33;41m'

if [[ $# -ne 1 ]];then
   clear
   echo ""
   echo "you must include the name of the data file as an agrument"
   echo -e "usage:      $yellow_on_red $0 file_name $_NC"
   exit;
fi


DIR=`pwd`

file_name=`echo $DIR/$1 | sed 's/\.csv/_mod.csv/'`


echo 'Concat,Prefix,Code,Offer,Offer Reformat,Service Reformat,Product Code' > $file_name


cat $1 | sed -e 's///' -e 's/ //g' -e '/Concat/d'  > $DIR/tmp_products_to_exclude.csv
gawk -F, '{
     
      printf("%s,%s,%d,%d,%s%09d,%09d,%s%09d-%09d\n", $1, $2, $3, $4, $2, $3, $4, $2, $3, $4)

}' < $DIR/tmp_products_to_exclude.csv >> $file_name



rm $DIR/tmp_products_to_exclude.csv

