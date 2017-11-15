#! /bin/bash
#
# 	./validate_columns_bySource.sh
#
#	you can modify the -p param to (CUST*.INP for all CUST) (*.INP for all files) (INVC_0120*.INP for all INVC_0120 files)
#
#

DIR=`pwd`
DAT=`date '+%Y%m%d-%H%M%S'`
ID=""

source getopts.incl
getopts_valid_values `basename $0` -c -n -t -s -p -E

[[ ! $PARAM ]] && PARAM="*.INP"
etracs_grep='^.*$'
[[ ETRACS ]] && etracs='ETRACTS'


for j in "${FILETYPE[@]}";do
   if [[ ! $ETRACS ]];then
      ls -1 $DIR/data/$j/${PARAM} | egrep -v 'ETRACS|ORACLE|HEADER|CIE|GPG|gpg|PGP|pgp' | while read i;do
         x=`echo $i | sed 's/^.*\///'`
         echo $j $x
         ./validate_columns.pl $x 
      done
   else
      ls -1 $DIR/data/$j/${PARAM} | grep ETRACS | egrep -v 'HEADER|CIE|GPG|gpg|PGP|pgp' | while read i;do
         x=`echo $i | sed 's/^.*\///'`
         echo $j $x
         ./validate_etracs.pl $x
      done
   fi
done

