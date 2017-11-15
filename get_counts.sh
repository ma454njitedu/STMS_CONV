#! /bin/bash

DIR=`pwd`
source use_color.incl
source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s

function build_unionAll () {

   seqQ=1

   for x in `seq 1 $1`;do
      seqT=`printf "%06d" $x`
      key=`echo $2 | sed 's/^.*\///'` 
      
      if [[ $x -eq 1 ]];then
         echo "SELECT * FROM ${key}_$seqT" > $DIR/data/tmp_tab.txt
         echo "SELECT * FROM qry_${key}_01" > $DIR/data/tmp_qry.txt
      else
         echo "UNION ALL SELECT * FROM ${key}_$seqT" >> $DIR/data/tmp_tab.txt
         (( _99cnt++ ))
         if [[ $_99cnt -eq 99 ]];then
            _99cnt=0
            (( seqQ++ ))
            seqQ=`printf "%02d" $seqQ`
	    echo "UNION ALL SELECT * FROM qry_${key}_$seqQ" >> $DIR/data/tmp_qry.txt
         fi
      fi

   done
   
   cat $DIR/data/tmp_tab.txt $DIR/data/tmp_qry.txt > $DIR/data/output/Union_all_${key}${3}.txt
   rm $DIR/data/tmp_tab.txt
   rm $DIR/data/tmp_qry.txt
}



for x in "${FILETYPE[@]}";do
echo "		$x"
echo "		======="
ls -1 $DIR/data/$x/*.INP | egrep -v 'HEADER|GPG|gpg|PGP|pgp' | sed 's/_20.*//' | sort -u | while read i;do

   x=`ls -1 $i* | wc -l`
   y=`ls -1 $i* | tail -1`

   seq=`echo $y | sed 's/.*_20......_//' | sed 's/_.*//' | sed 's/^0*//'`

   if [[ $x -eq $seq ]];then 
      echo $x	$seq	$y
      build_unionAll $seq $i
   else
      echo -e "$black_on_yellow $x $seq $yellow_on_red $y $_NC"
      build_unionAll $seq $i _ERR
   fi

done
done
