#! /bin/bash

DIR=`pwd`
echo $DIR


ls -1 $DIR/data/source/* | grep HEADER | while read i;do


    echo $i

ex $i <<Eof
:1,$ s/inp/INP/
:wq
Eof



done











exit

ex yousef.dat <<Eof
:1,$ s/VI|..../VI|1111/
:wq
Eof

