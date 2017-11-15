#! /bin/bash
#
#	./validate_columns_bySeq.sh 1
#
#	VALUE = starting sequence number and increment each instance by 1.
#	ITERATIONS = the number of instances you are going to run
#	max_seq = the number to the maximum sequence number
#	${FILETYPE[@]} =  core,noncore, or source
#

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s -i -v -E


[[ $ITERATIONS ]] || ITERATIONS=1
[[ $VALUE ]] || VALUE=1
seq_value=$VALUE
seq=`printf "%06d" $seq_value`

max_seq=0
for x in "${FILETYPE[@]}";do
  last_seq=`ls -1 $DIR/data/$x/*.INP | egrep -v 'HEADER' | sed 's/_.....INP$//' | sed 's/^.*_//' | sort | tail -1 | sed 's/^0*//'`
  [[ $last_seq -gt $max_seq ]] && max_seq=$last_seq 
done



while [ $seq_value -le $max_seq ];do
  for j in "${FILETYPE[@]}";do
	if [[ ! $ETRACS ]];then
           exst=`ls -1 $DIR/data/$j/*.INP | egrep -v 'ETRACS|ORACLE' | egrep $seq | wc -l`
           if [[ $exst -gt 0 ]];then
              ls -1 $DIR/data/$j/*${seq}_* | egrep -v 'ETRACS|ORACLE|HEADER|CIE|GPG|PGP|gpg|pgp' | while read i;do
                 x=`echo $i | sed 's/^.*\///'`
                 echo "$x in $j"
                 ./validate_columns.pl $x 
              done
  	   fi
	else
           exst=`ls -1 $DIR/data/$j/*ETRACS*.INP | grep $seq | wc -l`
           if [[ $exst -gt 0 ]];then
              ls -1 $DIR/data/$j/*ETRACS*${seq}_* | egrep -v 'HEADER|CIE|PGP|pgp|GPG|gpg' | while read i;do
                 x=`echo $i | sed 's/^.*\///'`
                 echo "$x in $j"
                 ./validate_etracs.pl $x
              done
           fi
        fi
   done
   seq_value=$(( $seq_value + $ITERATIONS ))
   seq=`printf "%06d" $seq_value`
done

echo "start $DAT"
echo "end   `date '+%Y%m%d-%H%M%S'`"
