#! /bin/bash

DIR=`pwd`

#for i in a b c d;do
for i in a;do

   ls -1 $DIR/$i/*.inp | while read j;do

     x=`echo $j |  sed 's/inp$/INP/'`
     echo $j $x
     mv $j $x


   ls -1 $DIR/$I/*.INP | while read j;do
   cat $j | sed 's/$//' > tmp_removeM.dat

   mv $DIR/$i/tmp_removeM.dat $DIR/$i/$j
   echo $DIR/$i/$j


   done
done
  exit 
   
   #! /bin/bash

if [[ $# -ne 1 ]];then
	echo "you must enter one of the following: source noncore  core"
	exit 1
fi

./c/rename.sh

./c/removeM.sh



mv *.INP /home/conversion/data/$1

















done
