#! /bin/bash


ls -1 * | egrep 'inp$|INP$' | while read i;do

   if [[ $i =~ HEADER ]];then
      sed -i s/inp/INP/ $i
      echo "fixed HEADER file $i"
   fi
   
   
   if [[ $i =~ inp$ ]];then
      x=`echo $i |  sed 's/inp$/INP/'`
      echo "changed int to INP in	$i $x"
      mv $i $x
   fi

   cat $i | sed 's/$//' > tmp_removeM.dat
   mv tmp_removeM.dat $i
   echo clean DOS in	$i
   
done




