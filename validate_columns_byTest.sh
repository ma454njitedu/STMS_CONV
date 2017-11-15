#! /bin/bash
#
#	./validate_columns_bySeq.sh 1
#
#	ARGUMENT $1 = start = starting sequence number and increment each instance by 1.
#	change $iterations for the number of instances you are going to run
#	in the while statement set the number to the maximum sequence number
#	modify core,noncore,source in this script
#

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`

iterations=3
strt=$1


if [[  $1 =~ [1-$iterations] ]];then
	echo "processing job sequence $1"
else
	echo "you must enter a sequence number when you run this script. And it must be run $iterations times"
fi

seq=`printf "%06d" $strt`

while [ $strt -lt 1000 ];do
  for j in core noncore;do
	exst=`ls -1 $DIR/data/$j/* | grep $seq | wc -l`
	if [[ $exst -gt 0 ]];then
           ls -1 $DIR/data/$j/*${seq}_* | egrep -v 'ETRACS|HEADER|CIE|GPG|PGP|gpg|pgp' | while read i;do
              x=`echo $i | sed 's/^.*\///'`
              echo "$x in $j"
              ./validate_columns.pl $x 
           done
	fi
   done
   strt=$(( $strt + $iterations ))
   seq=`printf "%06d" $strt`
done

echo "start $DAT"
echo "end   `date '+%Y%m%d-%H%M%S'`"
