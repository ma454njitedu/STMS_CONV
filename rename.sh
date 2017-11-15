#! /bin/bash


ls -1 *.inp | while read i;do

     x=`echo $i |  sed 's/inp$/INP/'`
     echo $i $x
     mv $i $x
done
